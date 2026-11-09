-- =============================================================================
-- Référentiels de la boutique : catégories, modèles, couleurs, tailles, marques, unités,
-- modes de paiement, clientes, fournisseurs, zones de livraison, motifs de mouvement,
-- catégories de dépenses. Isolation par boutique_id + clés composites (boutique_id, id).
-- =============================================================================

create type public.type_mode_paiement as enum ('especes', 'mobile_money', 'banque', 'carte', 'credit');

-- Vrai quand la requête vient directement d'un client API (et non d'une fonction SECURITY DEFINER).
create or replace function prive.appel_direct_client()
returns boolean
language sql
stable
as $$
  select current_user in ('anon', 'authenticated');
$$;

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  parent_id uuid,
  nom_ar text,
  nom_fr text,
  image_url text,
  ordre integer not null default 0,
  visible_en_ligne boolean not null default true,
  actif boolean not null default true,
  cree_par uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, id),
  foreign key (boutique_id, parent_id) references public.categories (boutique_id, id),
  constraint categories_nom_requis check (coalesce(nom_ar, nom_fr) is not null),
  constraint categories_pas_son_parent check (parent_id is distinct from id)
);
create index categories_boutique_ordre_idx on public.categories (boutique_id, ordre);

create table public.modeles (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  categorie_id uuid,
  nom_ar text,
  nom_fr text,
  actif boolean not null default true,
  cree_par uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, id),
  foreign key (boutique_id, categorie_id) references public.categories (boutique_id, id),
  constraint modeles_nom_requis check (coalesce(nom_ar, nom_fr) is not null)
);

create table public.couleurs (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  nom_ar text,
  nom_fr text,
  code_hex text not null check (code_hex ~ '^#[0-9A-Fa-f]{6}$'),
  ordre integer not null default 0,
  actif boolean not null default true,
  cree_par uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, id),
  constraint couleurs_nom_requis check (coalesce(nom_ar, nom_fr) is not null)
);

create table public.tailles (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  nom_ar text,
  nom_fr text,
  type text not null default 'taille' check (type in ('taille', 'pointure', 'longueur')),
  ordre integer not null default 0,
  actif boolean not null default true,
  cree_par uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, id),
  constraint tailles_nom_requis check (coalesce(nom_ar, nom_fr) is not null)
);

create table public.marques (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  nom_ar text,
  nom_fr text,
  logo_url text,
  actif boolean not null default true,
  cree_par uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, id),
  constraint marques_nom_requis check (coalesce(nom_ar, nom_fr) is not null)
);

create table public.unites (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  nom_ar text,
  nom_fr text,
  abreviation text,
  actif boolean not null default true,
  cree_par uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, id),
  constraint unites_nom_requis check (coalesce(nom_ar, nom_fr) is not null)
);

create table public.modes_paiement (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  nom_ar text,
  nom_fr text,
  type public.type_mode_paiement not null,
  icone text,
  par_defaut boolean not null default false,
  actif boolean not null default true,
  ordre integer not null default 0,
  cree_par uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, id),
  constraint modes_paiement_nom_requis check (coalesce(nom_ar, nom_fr) is not null)
);
create unique index modes_paiement_un_defaut_idx on public.modes_paiement (boutique_id) where par_defaut;

create table public.clients (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  nom_ar text,
  nom_fr text,
  telephone text,
  whatsapp text,
  adresse text,
  ville text,
  plafond_credit numeric(14, 2) check (plafond_credit >= 0),
  solde numeric(14, 2) not null default 0,
  notes text,
  cree_par uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  supprime_le timestamptz,
  unique (boutique_id, id),
  constraint clients_nom_requis check (coalesce(nom_ar, nom_fr) is not null)
);
create index clients_telephone_idx on public.clients (boutique_id, telephone);

create table public.fournisseurs (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  nom_ar text,
  nom_fr text,
  telephone text,
  adresse text,
  solde numeric(14, 2) not null default 0,
  notes text,
  cree_par uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  supprime_le timestamptz,
  unique (boutique_id, id),
  constraint fournisseurs_nom_requis check (coalesce(nom_ar, nom_fr) is not null)
);

create table public.zones_livraison (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  nom_ar text,
  nom_fr text,
  frais numeric(14, 2) not null default 0 check (frais >= 0),
  delai_jours integer check (delai_jours >= 0),
  ordre integer not null default 0,
  actif boolean not null default true,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, id),
  constraint zones_livraison_nom_requis check (coalesce(nom_ar, nom_fr) is not null)
);

-- `code` identifie les motifs système utilisés par les fonctions (ex. 'inventaire').
create table public.motifs_mouvement (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  code text,
  nom_ar text,
  nom_fr text,
  actif boolean not null default true,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, id),
  constraint motifs_mouvement_nom_requis check (coalesce(nom_ar, nom_fr) is not null)
);
create unique index motifs_mouvement_code_idx on public.motifs_mouvement (boutique_id, code) where code is not null;

create table public.categories_depenses (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  nom_ar text,
  nom_fr text,
  actif boolean not null default true,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, id),
  constraint categories_depenses_nom_requis check (coalesce(nom_ar, nom_fr) is not null)
);

-- Soldes : modifiés uniquement par les fonctions métier (vente, règlement, réception).
create or replace function prive.trg_proteger_solde()
returns trigger
language plpgsql
as $$
begin
  if prive.appel_direct_client() and (
    (tg_op = 'INSERT' and new.solde <> 0) or (tg_op = 'UPDATE' and new.solde is distinct from old.solde)
  ) then
    raise exception 'colonne_protegee: le solde est calculé par le système' using errcode = '42501';
  end if;
  return new;
end;
$$;
create trigger proteger_solde before insert or update on public.clients
  for each row execute function prive.trg_proteger_solde();
create trigger proteger_solde before insert or update on public.fournisseurs
  for each row execute function prive.trg_proteger_solde();

-- Triggers modifie_le + politiques RLS.
do $$
declare
  t text;
begin
  foreach t in array array['categories', 'modeles', 'couleurs', 'tailles', 'marques', 'unites', 'modes_paiement',
                           'clients', 'fournisseurs', 'zones_livraison', 'motifs_mouvement', 'categories_depenses']
  loop
    perform prive.attacher_modifie_le(('public.' || t)::regclass);
  end loop;

  foreach t in array array['categories', 'modeles', 'couleurs', 'tailles', 'marques', 'unites', 'modes_paiement',
                           'zones_livraison', 'motifs_mouvement']
  loop
    perform prive.creer_politiques_boutique(('public.' || t)::regclass, 'referentiels.lire', 'referentiels.ecrire');
  end loop;
end;
$$;

select prive.creer_politiques_boutique('public.clients', 'clients.lire', 'clients.ecrire', array['insert', 'update']);
select prive.creer_politiques_boutique('public.fournisseurs', 'stock.lire', 'stock.ecrire', array['insert', 'update']);
select prive.creer_politiques_boutique('public.categories_depenses', 'depenses.gerer', 'depenses.gerer');

-- Audit : suppression de référentiels sensibles.
create trigger audit after delete on public.clients for each row execute function prive.trg_journaliser();
create trigger audit after delete on public.fournisseurs for each row execute function prive.trg_journaliser();
