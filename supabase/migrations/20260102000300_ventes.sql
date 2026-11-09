-- =============================================================================
-- Ventes : documents (ticket, facture, devis, BL, avoir), lignes, paiements,
-- sessions de caisse, dépenses, plages de numéros par appareil.
-- Aucun PDF n'est stocké : l'en-tête est figé en jsonb à l'émission, le PDF est généré à la demande.
-- Aucune taxe : les totaux sont sous_total − remise = total.
-- Écritures uniquement par fonctions SECURITY DEFINER (immuabilité d'une facture émise).
-- =============================================================================

create type public.type_document_vente as enum ('devis', 'bon_livraison', 'facture', 'avoir', 'ticket');
create type public.statut_document_vente as enum (
  'brouillon', 'envoye', 'accepte', 'refuse', 'expire',
  'valide', 'livre', 'facture',
  'emise', 'partiellement_payee', 'payee', 'annulee'
);
create type public.canal_vente as enum ('caisse', 'site_web', 'whatsapp', 'instagram', 'facebook', 'telephone', 'autre');

create table public.sessions_caisse (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  utilisateur_id uuid not null references public.profils (id),
  appareil_id uuid references public.appareils (id) on delete set null,
  ouverte_le timestamptz not null default now(),
  fermee_le timestamptz,
  fond_initial numeric(14, 2) not null default 0 check (fond_initial >= 0),
  attendu numeric(14, 2),
  compte numeric(14, 2),
  ecart numeric(14, 2),
  notes text,
  unique (boutique_id, id)
);
create unique index sessions_caisse_une_ouverte_idx on public.sessions_caisse (boutique_id, utilisateur_id) where fermee_le is null;

create table public.documents_vente (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  type public.type_document_vente not null,
  numero text not null,
  statut public.statut_document_vente not null,
  client_id uuid,
  document_source_id uuid,
  session_caisse_id uuid,
  canal public.canal_vente not null default 'caisse',
  date_emission timestamptz not null default now(),
  date_echeance date,
  sous_total numeric(14, 2) not null check (sous_total >= 0),
  remise numeric(14, 2) not null default 0 check (remise >= 0),
  total numeric(14, 2) not null check (total >= 0),
  paye numeric(14, 2) not null default 0 check (paye >= 0),
  reste numeric(14, 2) generated always as (total - paye) stored,
  notes text,
  entete jsonb not null,
  utilisateur_id uuid references public.profils (id),
  annule_le timestamptz,
  motif_annulation text,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, id),
  unique (boutique_id, type, numero),
  foreign key (boutique_id, client_id) references public.clients (boutique_id, id),
  foreign key (boutique_id, document_source_id) references public.documents_vente (boutique_id, id),
  foreign key (boutique_id, session_caisse_id) references public.sessions_caisse (boutique_id, id),
  constraint documents_total_coherent check (total = sous_total - remise)
);
create index documents_vente_date_idx on public.documents_vente (boutique_id, date_emission desc);
create index documents_vente_client_idx on public.documents_vente (boutique_id, client_id) where client_id is not null;
create index documents_vente_impayes_idx on public.documents_vente (boutique_id, client_id) where reste > 0 and statut <> 'annulee';
select prive.attacher_modifie_le('public.documents_vente');

create table public.lignes_document_vente (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  document_id uuid not null,
  variante_id uuid,
  libelle_ar text,
  libelle_fr text,
  quantite numeric(14, 3) not null check (quantite > 0),
  prix_unitaire numeric(14, 2) not null check (prix_unitaire >= 0),
  remise numeric(14, 2) not null default 0 check (remise >= 0),
  cout_unitaire numeric(14, 4) not null default 0 check (cout_unitaire >= 0),
  total numeric(14, 2) not null check (total >= 0),
  ordre integer not null default 0,
  unique (boutique_id, id),
  foreign key (boutique_id, document_id) references public.documents_vente (boutique_id, id) on delete cascade,
  foreign key (boutique_id, variante_id) references public.variantes_produit (boutique_id, id),
  constraint lignes_total_coherent check (total = round(quantite * prix_unitaire - remise, 2)),
  constraint lignes_libelle_requis check (coalesce(libelle_ar, libelle_fr) is not null)
);
create index lignes_document_vente_idx on public.lignes_document_vente (boutique_id, document_id);
create index lignes_document_vente_variante_idx on public.lignes_document_vente (boutique_id, variante_id);

create table public.paiements (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  document_id uuid,
  client_id uuid,
  mode_paiement_id uuid not null,
  montant numeric(14, 2) not null check (montant > 0),
  paye_le timestamptz not null default now(),
  session_caisse_id uuid,
  reference text,
  justificatif_url text,
  utilisateur_id uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  unique (boutique_id, id),
  foreign key (boutique_id, document_id) references public.documents_vente (boutique_id, id),
  foreign key (boutique_id, client_id) references public.clients (boutique_id, id),
  foreign key (boutique_id, mode_paiement_id) references public.modes_paiement (boutique_id, id),
  foreign key (boutique_id, session_caisse_id) references public.sessions_caisse (boutique_id, id),
  constraint paiements_cible check (document_id is not null or client_id is not null)
);
create index paiements_document_idx on public.paiements (boutique_id, document_id);
create index paiements_session_idx on public.paiements (boutique_id, session_caisse_id);

create table public.depenses (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  categorie_id uuid,
  montant numeric(14, 2) not null check (montant > 0),
  date_depense date not null default current_date,
  motif text,
  mode_paiement_id uuid,
  utilisateur_id uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  foreign key (boutique_id, categorie_id) references public.categories_depenses (boutique_id, id),
  foreign key (boutique_id, mode_paiement_id) references public.modes_paiement (boutique_id, id)
);
create index depenses_date_idx on public.depenses (boutique_id, date_depense desc);
select prive.attacher_modifie_le('public.depenses');

-- Plages de numéros réservées par appareil (ventes hors ligne). Les numéros réservés non utilisés
-- restent attribués à l'appareil : ils sont consommés dans l'ordre à sa prochaine vente.
create table public.plages_numeros (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  type_document text not null,
  annee integer not null,
  appareil_id uuid not null references public.appareils (id) on delete cascade,
  debut integer not null check (debut >= 1),
  fin integer not null,
  cree_le timestamptz not null default now(),
  constraint plages_numeros_ordre check (fin >= debut),
  unique (boutique_id, type_document, annee, debut)
);
create index plages_numeros_appareil_idx on public.plages_numeros (appareil_id);

-- Écritures par RPC uniquement ; lecture selon la permission.
revoke insert, update, delete on public.documents_vente, public.lignes_document_vente, public.paiements,
  public.sessions_caisse, public.plages_numeros from authenticated;

select prive.creer_politiques_boutique('public.documents_vente', 'documents.creer');
select prive.creer_politiques_boutique('public.lignes_document_vente', 'couts.voir');
select prive.creer_politiques_boutique('public.paiements', 'documents.creer');
select prive.creer_politiques_boutique('public.sessions_caisse', 'pos.vendre');
select prive.creer_politiques_boutique('public.plages_numeros', 'pos.vendre');
select prive.creer_politiques_boutique('public.depenses', 'depenses.gerer', 'depenses.gerer');

-- Audit : toute annulation et tout changement de statut d'un document.
create trigger audit_statut after update on public.documents_vente
  for each row when (old.statut is distinct from new.statut)
  execute function prive.trg_journaliser();

-- Lignes avec coût masqué pour les rôles sans « couts.voir » (vendeuse : pas de coûts d'achat).
create view public.lignes_document_vente_vue with (security_barrier = true) as
select l.id, l.boutique_id, l.document_id, l.variante_id, l.libelle_ar, l.libelle_fr, l.quantite,
       l.prix_unitaire, l.remise, l.total, l.ordre,
       case when l.boutique_id = any (prive.boutiques_avec_permission('couts.voir')) then l.cout_unitaire end as cout_unitaire
from public.lignes_document_vente l
where l.boutique_id = any (prive.boutiques_avec_permission('documents.creer'));
revoke insert, update, delete, truncate on public.lignes_document_vente_vue from anon, authenticated;
