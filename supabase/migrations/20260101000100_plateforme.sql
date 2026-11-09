-- =============================================================================
-- Plateforme : profils, commerçantes, boutiques (tenants), rôles et permissions,
-- membres, plans, abonnements, paiements d'abonnement.
-- Les politiques RLS sont posées dans 20260101000200_securite.sql.
-- =============================================================================

create type public.role_plateforme as enum ('super_admin', 'support', 'aucun');
create type public.statut_commercante as enum ('active', 'desactivee');
create type public.statut_boutique as enum ('essai', 'actif', 'grace', 'suspendu', 'ferme');
create type public.statut_membre as enum ('invite', 'actif', 'desactive');
create type public.statut_abonnement as enum ('essai', 'actif', 'grace', 'suspendu', 'expire', 'annule');
create type public.mode_paiement_abonnement as enum ('especes', 'virement', 'mobile_money');

-- Un profil par utilisateur Auth (hors clientes de la boutique en ligne, voir comptes_clientes_site).
create table public.profils (
  id uuid primary key references auth.users (id) on delete cascade,
  nom_ar text,
  nom_fr text,
  telephone text unique check (telephone ~ '^[0-9]{8,15}$'),
  email text,
  role_plateforme public.role_plateforme not null default 'aucun',
  langue text not null default 'ar' check (langue in ('ar', 'fr')),
  actif boolean not null default true,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  constraint profils_nom_requis check (coalesce(nom_ar, nom_fr) is not null),
  constraint profils_identifiant_requis check (telephone is not null or email is not null)
);
select prive.attacher_modifie_le('public.profils');

-- La commerçante, cliente de l'éditeur. Les notes internes restent visibles de l'éditeur seul.
create table public.commercantes (
  id uuid primary key default gen_random_uuid(),
  utilisateur_id uuid not null unique references public.profils (id),
  nom_ar text,
  nom_fr text,
  telephone text not null check (telephone ~ '^[0-9]{8,15}$'),
  whatsapp text,
  email text,
  ville text,
  notes text,
  statut public.statut_commercante not null default 'active',
  cree_par uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  constraint commercantes_nom_requis check (coalesce(nom_ar, nom_fr) is not null)
);
select prive.attacher_modifie_le('public.commercantes');

-- Le tenant. `slug` est le sous-domaine attribué à la création (immuable côté commerçante).
create table public.boutiques (
  id uuid primary key default gen_random_uuid(),
  commercante_id uuid not null references public.commercantes (id),
  nom_ar text,
  nom_fr text,
  slug text not null unique check (slug ~ '^[a-z0-9]([a-z0-9-]{0,38}[a-z0-9])?$'),
  code_boutique text not null unique check (code_boutique ~ '^[A-Z0-9]{6}$'),
  type_activite text,
  logo_url text,
  telephone text,
  whatsapp text,
  adresse text,
  ville text,
  devise text not null default 'MRU' check (devise ~ '^[A-Z]{3}$'),
  langue_par_defaut text not null default 'ar' check (langue_par_defaut in ('ar', 'fr')),
  fuseau_horaire text not null default 'Africa/Nouakchott',
  statut public.statut_boutique not null default 'essai',
  parametres jsonb not null default '{}'::jsonb,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  constraint boutiques_nom_requis check (coalesce(nom_ar, nom_fr) is not null)
);
create index boutiques_commercante_idx on public.boutiques (commercante_id);
create index boutiques_statut_idx on public.boutiques (statut);
select prive.attacher_modifie_le('public.boutiques');

-- Catalogue des permissions (clé stable, libellés bilingues) : base des rôles personnalisés (V2).
create table public.permissions (
  cle text primary key,
  module text not null,
  nom_ar text not null,
  nom_fr text not null
);

-- Rôles : `boutique_id` nul = rôle système partagé par toutes les boutiques.
create table public.roles (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid references public.boutiques (id) on delete cascade,
  cle text not null check (cle ~ '^[a-z_]+$'),
  nom_ar text not null,
  nom_fr text not null,
  systeme boolean not null default false,
  cree_le timestamptz not null default now(),
  unique nulls not distinct (boutique_id, cle)
);

create table public.permissions_role (
  role_id uuid not null references public.roles (id) on delete cascade,
  cle_permission text not null references public.permissions (cle) on delete cascade,
  autorise boolean not null default true,
  primary key (role_id, cle_permission)
);

create table public.membres_boutique (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  utilisateur_id uuid not null references public.profils (id),
  role_id uuid not null references public.roles (id),
  statut public.statut_membre not null default 'actif',
  invite_le timestamptz not null default now(),
  invite_par uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, utilisateur_id)
);
create index membres_boutique_utilisateur_idx on public.membres_boutique (utilisateur_id) where statut = 'actif';
select prive.attacher_modifie_le('public.membres_boutique');

-- Catalogue des plans. `limites` : utilisateurs, produits, stockage_mo, boutique_en_ligne,
-- domaine_personnalise, themes, rapports_avances (null = illimité).
create table public.plans (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[a-z0-9_]+$'),
  nom_ar text not null,
  nom_fr text not null,
  description_ar text,
  description_fr text,
  prix_mensuel numeric(14, 2) not null default 0 check (prix_mensuel >= 0),
  prix_annuel numeric(14, 2) not null default 0 check (prix_annuel >= 0),
  devise text not null default 'MRU',
  limites jsonb not null default '{}'::jsonb,
  duree_essai_jours integer check (duree_essai_jours > 0),
  ordre integer not null default 0,
  actif boolean not null default true,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now()
);
select prive.attacher_modifie_le('public.plans');

create table public.abonnements (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  plan_id uuid not null references public.plans (id),
  statut public.statut_abonnement not null default 'essai',
  debut_le date not null default current_date,
  fin_le date,
  grace_jusqu_au date,
  renouvellement_auto boolean not null default false,
  remise numeric(14, 2) not null default 0 check (remise >= 0),
  notes text,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now()
);
-- Un seul abonnement en cours par boutique.
create unique index abonnements_un_en_cours_idx on public.abonnements (boutique_id)
  where statut in ('essai', 'actif', 'grace');
create index abonnements_fin_idx on public.abonnements (fin_le) where statut in ('essai', 'actif', 'grace');
select prive.attacher_modifie_le('public.abonnements');

create table public.paiements_abonnement (
  id uuid primary key default gen_random_uuid(),
  abonnement_id uuid not null references public.abonnements (id) on delete cascade,
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  montant numeric(14, 2) not null check (montant > 0),
  devise text not null default 'MRU',
  mode public.mode_paiement_abonnement not null,
  reference text,
  justificatif_url text,
  paye_le timestamptz not null default now(),
  periode_mois integer not null default 1 check (periode_mois between 1 and 36),
  enregistre_par uuid references public.profils (id),
  cree_le timestamptz not null default now()
);
create index paiements_abonnement_boutique_idx on public.paiements_abonnement (boutique_id, paye_le desc);
