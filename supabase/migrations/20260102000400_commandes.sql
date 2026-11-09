-- =============================================================================
-- Commandes (boutique en ligne et autres canaux), lignes figées, historique des statuts.
-- Création et changements de statut uniquement par fonctions SECURITY DEFINER.
-- =============================================================================

create type public.statut_commande as enum (
  'nouvelle', 'confirmee', 'en_preparation', 'prete', 'expediee', 'livree', 'annulee', 'retournee'
);
create type public.statut_paiement_commande as enum ('non_paye', 'partiel', 'paye');
create type public.mode_livraison as enum ('livraison', 'retrait');
create type public.mode_paiement_commande as enum ('a_la_livraison', 'mobile_money', 'especes', 'autre');

-- Comptes des clientes de la boutique en ligne (identité Auth distincte par boutique).
create table public.comptes_clientes_site (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  utilisateur_id uuid not null unique,
  nom text not null,
  telephone text not null check (telephone ~ '^[0-9]{8,15}$'),
  adresses jsonb not null default '[]'::jsonb,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, id),
  unique (boutique_id, telephone)
);
select prive.attacher_modifie_le('public.comptes_clientes_site');

create table public.commandes (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  numero text not null,
  canal public.canal_vente not null default 'site_web',
  client_id uuid,
  compte_client_id uuid,
  nom_client text not null,
  telephone text not null check (telephone ~ '^[0-9]{8,15}$'),
  adresse text,
  ville text,
  zone_id uuid,
  mode_livraison public.mode_livraison not null default 'livraison',
  frais_livraison numeric(14, 2) not null default 0 check (frais_livraison >= 0),
  statut public.statut_commande not null default 'nouvelle',
  statut_paiement public.statut_paiement_commande not null default 'non_paye',
  mode_paiement public.mode_paiement_commande not null default 'a_la_livraison',
  sous_total numeric(14, 2) not null check (sous_total >= 0),
  total numeric(14, 2) not null check (total >= 0),
  montant_paye numeric(14, 2) not null default 0 check (montant_paye >= 0),
  notes text,
  justificatif_url text,
  document_id uuid,
  livreur_nom text,
  livreur_telephone text,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, id),
  unique (boutique_id, numero),
  foreign key (boutique_id, client_id) references public.clients (boutique_id, id),
  foreign key (boutique_id, compte_client_id) references public.comptes_clientes_site (boutique_id, id),
  foreign key (boutique_id, zone_id) references public.zones_livraison (boutique_id, id),
  foreign key (boutique_id, document_id) references public.documents_vente (boutique_id, id),
  constraint commandes_total_coherent check (total = sous_total + frais_livraison)
);
create index commandes_statut_idx on public.commandes (boutique_id, statut, cree_le desc);
create index commandes_telephone_idx on public.commandes (boutique_id, telephone);
create index commandes_compte_idx on public.commandes (compte_client_id) where compte_client_id is not null;
select prive.attacher_modifie_le('public.commandes');

create table public.lignes_commande (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  commande_id uuid not null,
  variante_id uuid not null,
  quantite numeric(14, 3) not null check (quantite > 0),
  prix_unitaire numeric(14, 2) not null check (prix_unitaire >= 0),
  libelle_ar text,
  libelle_fr text,
  total numeric(14, 2) not null check (total >= 0),
  unique (boutique_id, id),
  foreign key (boutique_id, commande_id) references public.commandes (boutique_id, id) on delete cascade,
  foreign key (boutique_id, variante_id) references public.variantes_produit (boutique_id, id),
  constraint lignes_commande_total check (total = round(quantite * prix_unitaire, 2)),
  constraint lignes_commande_libelle_requis check (coalesce(libelle_ar, libelle_fr) is not null)
);
create index lignes_commande_idx on public.lignes_commande (boutique_id, commande_id);

create table public.historique_statuts_commande (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  commande_id uuid not null,
  statut public.statut_commande not null,
  utilisateur_id uuid,
  date_statut timestamptz not null default now(),
  note text,
  foreign key (boutique_id, commande_id) references public.commandes (boutique_id, id) on delete cascade
);
create index historique_statuts_commande_idx on public.historique_statuts_commande (boutique_id, commande_id, date_statut);
create trigger historique_ajout_seul before update or delete on public.historique_statuts_commande
  for each row execute function prive.interdire_modification();

-- Limitation de débit des RPC publiques (commande, inscription) : table interne.
create table public.limites_debit (
  cle text primary key,
  compteur integer not null default 0,
  fenetre_debut timestamptz not null default now()
);
alter table public.limites_debit enable row level security;
create policy refus_total_limites_debit on public.limites_debit
  for all to anon, authenticated using (false) with check (false);

revoke insert, update, delete on public.commandes, public.lignes_commande, public.historique_statuts_commande,
  public.comptes_clientes_site from authenticated;

select prive.creer_politiques_boutique('public.commandes', 'commandes.lire');
select prive.creer_politiques_boutique('public.lignes_commande', 'commandes.lire');
select prive.creer_politiques_boutique('public.historique_statuts_commande', 'commandes.lire');

-- La cliente connectée lit ses propres commandes et son compte (jamais celles des autres).
create policy lecture_commandes_cliente on public.commandes for select to authenticated
  using (compte_client_id in (select c.id from public.comptes_clientes_site c where c.utilisateur_id = auth.uid()));
create policy lecture_lignes_commande_cliente on public.lignes_commande for select to authenticated
  using (commande_id in (
    select o.id from public.commandes o
    join public.comptes_clientes_site c on c.id = o.compte_client_id
    where c.utilisateur_id = auth.uid()
  ));

alter table public.comptes_clientes_site enable row level security;
create policy lecture_compte_cliente on public.comptes_clientes_site for select to authenticated
  using (utilisateur_id = auth.uid());
create policy modification_compte_cliente on public.comptes_clientes_site for update to authenticated
  using (utilisateur_id = auth.uid()) with check (utilisateur_id = auth.uid());

create or replace function prive.trg_compte_cliente_protege()
returns trigger
language plpgsql
as $$
begin
  if prive.appel_direct_client() and (
    new.utilisateur_id is distinct from old.utilisateur_id or new.boutique_id is distinct from old.boutique_id
    or new.telephone is distinct from old.telephone
  ) then
    raise exception 'colonne_protegee: identité du compte non modifiable' using errcode = '42501';
  end if;
  return new;
end;
$$;
create trigger compte_cliente_protege before update on public.comptes_clientes_site
  for each row execute function prive.trg_compte_cliente_protege();

-- Temps réel : les nouvelles commandes apparaissent dans l'app mobile (filtré par RLS).
alter publication supabase_realtime add table public.commandes;
alter publication supabase_realtime add table public.notifications;
