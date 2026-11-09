-- =============================================================================
-- Stock : réceptions, lots, mouvements (ajout seul), ajustements, vues.
-- Le stock n'est jamais modifié directement : toute écriture passe par les fonctions
-- recevoir_stock / ajuster_stock / enregistrer_vente… (SECURITY DEFINER).
-- Les coûts d'achat sont masqués par des vues pour les rôles sans « couts.voir ».
-- =============================================================================

create type public.type_mouvement_stock as enum (
  'entree', 'sortie_vente', 'sortie_manuelle', 'retour_client', 'retour_fournisseur',
  'ajustement', 'reservation', 'liberation', 'transfert_sortie', 'transfert_entree'
);
create type public.type_ajustement_stock as enum ('sortie_manuelle', 'inventaire', 'retour_fournisseur');

create table public.receptions_stock (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  fournisseur_id uuid,
  transfert_id uuid,
  date_reception timestamptz not null default now(),
  reference text,
  total numeric(14, 2) not null default 0 check (total >= 0),
  montant_paye numeric(14, 2) not null default 0 check (montant_paye >= 0),
  notes text,
  utilisateur_id uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  unique (boutique_id, id),
  foreign key (boutique_id, fournisseur_id) references public.fournisseurs (boutique_id, id)
);
create index receptions_stock_date_idx on public.receptions_stock (boutique_id, date_reception desc);

create table public.lignes_reception_stock (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  reception_id uuid not null,
  variante_id uuid not null,
  quantite numeric(14, 3) not null check (quantite > 0),
  cout_unitaire numeric(14, 4) not null check (cout_unitaire >= 0),
  date_expiration date,
  prix_vente numeric(14, 2) check (prix_vente >= 0),
  unique (boutique_id, id),
  foreign key (boutique_id, reception_id) references public.receptions_stock (boutique_id, id) on delete cascade,
  foreign key (boutique_id, variante_id) references public.variantes_produit (boutique_id, id)
);
create index lignes_reception_stock_idx on public.lignes_reception_stock (boutique_id, reception_id);

-- Un lot = une entrée datée ; `decouvert` marque le lot négatif créé quand le stock négatif est autorisé.
create table public.lots_stock (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  variante_id uuid not null,
  numero_lot text not null,
  recu_le timestamptz not null default now(),
  quantite_initiale numeric(14, 3) not null,
  quantite_restante numeric(14, 3) not null,
  cout_unitaire numeric(14, 4) not null default 0 check (cout_unitaire >= 0),
  date_expiration date,
  ligne_reception_id uuid,
  fournisseur_id uuid,
  decouvert boolean not null default false,
  unique (boutique_id, id),
  unique (boutique_id, numero_lot),
  foreign key (boutique_id, variante_id) references public.variantes_produit (boutique_id, id),
  foreign key (boutique_id, ligne_reception_id) references public.lignes_reception_stock (boutique_id, id),
  foreign key (boutique_id, fournisseur_id) references public.fournisseurs (boutique_id, id),
  constraint lots_quantites_coherentes check (
    (decouvert and quantite_restante <= 0)
    or (not decouvert and quantite_initiale > 0 and quantite_restante >= 0 and quantite_restante <= quantite_initiale)
  )
);
create index lots_stock_fifo_idx on public.lots_stock (boutique_id, variante_id, recu_le) where quantite_restante > 0;

create table public.mouvements_stock (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  variante_id uuid not null,
  lot_id uuid,
  type public.type_mouvement_stock not null,
  quantite numeric(14, 3) not null check (quantite <> 0),
  cout_unitaire numeric(14, 4),
  source_type text,
  source_id uuid,
  motif_id uuid,
  note text,
  utilisateur_id uuid,
  cree_le timestamptz not null default now(),
  foreign key (boutique_id, variante_id) references public.variantes_produit (boutique_id, id),
  foreign key (boutique_id, lot_id) references public.lots_stock (boutique_id, id),
  foreign key (boutique_id, motif_id) references public.motifs_mouvement (boutique_id, id)
);
create index mouvements_stock_variante_idx on public.mouvements_stock (boutique_id, variante_id, cree_le desc);
create index mouvements_stock_source_idx on public.mouvements_stock (boutique_id, source_type, source_id);
create trigger mouvements_stock_ajout_seul before update or delete on public.mouvements_stock
  for each row execute function prive.interdire_modification();

create table public.ajustements_stock (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  type public.type_ajustement_stock not null,
  motif_id uuid,
  note text,
  utilisateur_id uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  unique (boutique_id, id),
  foreign key (boutique_id, motif_id) references public.motifs_mouvement (boutique_id, id)
);

create table public.lignes_ajustement_stock (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  ajustement_id uuid not null,
  variante_id uuid not null,
  quantite_systeme numeric(14, 3) not null,
  quantite_comptee numeric(14, 3),
  ecart numeric(14, 3) not null,
  foreign key (boutique_id, ajustement_id) references public.ajustements_stock (boutique_id, id) on delete cascade,
  foreign key (boutique_id, variante_id) references public.variantes_produit (boutique_id, id)
);
create index lignes_ajustement_stock_idx on public.lignes_ajustement_stock (boutique_id, ajustement_id);

-- Les clients API n'écrivent jamais dans le stock.
revoke insert, update, delete on public.mouvements_stock, public.lots_stock from authenticated;

-- Tables contenant des coûts : lecture réservée à « couts.voir » (les autres rôles passent par les vues).
select prive.creer_politiques_boutique('public.receptions_stock', 'couts.voir');
select prive.creer_politiques_boutique('public.lignes_reception_stock', 'couts.voir');
select prive.creer_politiques_boutique('public.lots_stock', 'couts.voir');
select prive.creer_politiques_boutique('public.mouvements_stock', 'couts.voir');
select prive.creer_politiques_boutique('public.ajustements_stock', 'stock.lire');
select prive.creer_politiques_boutique('public.lignes_ajustement_stock', 'stock.lire');

create trigger audit after insert on public.ajustements_stock
  for each row execute function prive.trg_journaliser();

-- ---------------------------------------------------------------------------
-- Vues : accès en lecture seule, filtrées par permission, coûts masqués si non autorisé.
-- (propriétaire de la vue = postgres : le filtrage est fait ici, pas par la RLS)
-- ---------------------------------------------------------------------------

create view public.lots_stock_vue with (security_barrier = true) as
select l.id, l.boutique_id, l.variante_id, l.numero_lot, l.recu_le, l.quantite_initiale, l.quantite_restante,
       case when l.boutique_id = any (prive.boutiques_avec_permission('couts.voir')) then l.cout_unitaire end as cout_unitaire,
       l.date_expiration, l.ligne_reception_id, l.fournisseur_id, l.decouvert
from public.lots_stock l
where l.boutique_id = any (prive.boutiques_avec_permission('stock.lire'));

create view public.mouvements_stock_vue with (security_barrier = true) as
select m.id, m.boutique_id, m.variante_id, m.lot_id, m.type, m.quantite,
       case when m.boutique_id = any (prive.boutiques_avec_permission('couts.voir')) then m.cout_unitaire end as cout_unitaire,
       m.source_type, m.source_id, m.motif_id, m.note, m.utilisateur_id, m.cree_le
from public.mouvements_stock m
where m.boutique_id = any (prive.boutiques_avec_permission('stock.lire'));

create view public.receptions_stock_vue with (security_barrier = true) as
select r.id, r.boutique_id, r.fournisseur_id, r.transfert_id, r.date_reception, r.reference, r.notes, r.utilisateur_id, r.cree_le,
       case when r.boutique_id = any (prive.boutiques_avec_permission('couts.voir')) then r.total end as total,
       case when r.boutique_id = any (prive.boutiques_avec_permission('couts.voir')) then r.montant_paye end as montant_paye
from public.receptions_stock r
where r.boutique_id = any (prive.boutiques_avec_permission('stock.lire'));

create view public.lignes_reception_stock_vue with (security_barrier = true) as
select l.id, l.boutique_id, l.reception_id, l.variante_id, l.quantite, l.date_expiration, l.prix_vente,
       case when l.boutique_id = any (prive.boutiques_avec_permission('couts.voir')) then l.cout_unitaire end as cout_unitaire
from public.lignes_reception_stock l
where l.boutique_id = any (prive.boutiques_avec_permission('stock.lire'));

-- Stock par variante : en stock = somme des lots ; réservé = réservations non libérées.
create view public.stock_variante with (security_barrier = true) as
select v.id as variante_id,
       v.boutique_id,
       coalesce(l.en_stock, 0) as en_stock,
       coalesce(r.reserve, 0) as reserve,
       coalesce(l.en_stock, 0) - coalesce(r.reserve, 0) as disponible
from public.variantes_produit v
left join (
  select s.variante_id, sum(s.quantite_restante) as en_stock
  from public.lots_stock s
  where s.boutique_id = any (prive.mes_boutiques())
  group by s.variante_id
) l on l.variante_id = v.id
left join (
  select m.variante_id, sum(m.quantite) as reserve
  from public.mouvements_stock m
  where m.type in ('reservation', 'liberation') and m.boutique_id = any (prive.mes_boutiques())
  group by m.variante_id
) r on r.variante_id = v.id
where v.boutique_id = any (prive.boutiques_avec_permission('stock.lire'));

-- Aucune écriture possible à travers les vues.
revoke insert, update, delete, truncate on
  public.lots_stock_vue, public.mouvements_stock_vue, public.receptions_stock_vue,
  public.lignes_reception_stock_vue, public.stock_variante
from anon, authenticated;
