-- =============================================================================
-- Site web de la boutique : domaines, thèmes, paramètres, sections, pages, bannières.
-- Le sous-domaine est attribué à la création et modifiable uniquement par l'éditeur.
-- =============================================================================

create type public.statut_domaine as enum ('non_configure', 'en_attente', 'verifie', 'erreur');

-- Catalogue global des thèmes (gabarits React pilotés par schema_config / config_theme).
-- `plan_minimum` : rang minimal du plan (plans.ordre) donnant accès au thème.
create table public.themes_site (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[a-z0-9_]+$'),
  nom_ar text not null,
  nom_fr text not null,
  apercu_url text,
  schema_config jsonb not null default '{}'::jsonb,
  plan_minimum integer not null default 0,
  actif boolean not null default true,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now()
);
select prive.attacher_modifie_le('public.themes_site');

create table public.domaines_boutique (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  sous_domaine text not null unique check (sous_domaine ~ '^[a-z0-9]([a-z0-9-]{0,38}[a-z0-9])?$'),
  domaine_personnalise text unique check (domaine_personnalise ~ '^[a-z0-9.-]+\.[a-z]{2,}$'),
  statut_dns public.statut_domaine not null default 'non_configure',
  statut_ssl public.statut_domaine not null default 'non_configure',
  principal boolean not null default true,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, id)
);
create index domaines_boutique_boutique_idx on public.domaines_boutique (boutique_id);
select prive.attacher_modifie_le('public.domaines_boutique');

create table public.parametres_site (
  boutique_id uuid primary key references public.boutiques (id) on delete cascade,
  theme_id uuid references public.themes_site (id),
  config_theme jsonb not null default '{}'::jsonb,
  config_brouillon jsonb,
  logo_url text,
  favicon_url text,
  liens_sociaux jsonb not null default '{}'::jsonb,
  referencement jsonb not null default '{}'::jsonb,
  infos_paiement jsonb not null default '{}'::jsonb,
  horaires jsonb not null default '{}'::jsonb,
  commande_minimale numeric(14, 2) not null default 0 check (commande_minimale >= 0),
  livraison_active boolean not null default true,
  retrait_boutique_actif boolean not null default true,
  paiement_livraison_actif boolean not null default true,
  mobile_money_actif boolean not null default false,
  afficher_stock boolean not null default true,
  masquer_epuises boolean not null default false,
  message_confirmation_ar text,
  message_confirmation_fr text,
  langues_activees text[] not null default '{ar,fr}' check (langues_activees <@ array['ar', 'fr']),
  publie boolean not null default true,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now()
);
select prive.attacher_modifie_le('public.parametres_site');

create table public.sections_site (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  type text not null check (type in (
    'banniere', 'categories_vedettes', 'nouveautes', 'promotions', 'produits_populaires', 'a_propos', 'contact'
  )),
  titre_ar text,
  titre_fr text,
  contenu_ar text,
  contenu_fr text,
  config jsonb not null default '{}'::jsonb,
  ordre integer not null default 0,
  visible boolean not null default true,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now()
);
create index sections_site_idx on public.sections_site (boutique_id, ordre);
select prive.attacher_modifie_le('public.sections_site');

create table public.pages_site (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  slug text not null check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  titre_ar text,
  titre_fr text,
  contenu_ar text,
  contenu_fr text,
  ordre integer not null default 0,
  visible boolean not null default true,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  unique (boutique_id, slug)
);
select prive.attacher_modifie_le('public.pages_site');

create table public.bannieres_site (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  image_url text not null,
  titre_ar text,
  titre_fr text,
  lien text,
  ordre integer not null default 0,
  actif boolean not null default true,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now()
);
create index bannieres_site_idx on public.bannieres_site (boutique_id, ordre);
select prive.attacher_modifie_le('public.bannieres_site');

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.themes_site enable row level security;
create policy lecture_themes_site on public.themes_site for select to authenticated using (true);
create policy ecriture_themes_site on public.themes_site for all to authenticated
  using (prive.est_super_admin()) with check (prive.est_super_admin());

-- Domaines : lecture membres + éditeur ; seule la saisie du domaine personnalisé est ouverte aux membres.
alter table public.domaines_boutique enable row level security;
create policy lecture_domaines_boutique on public.domaines_boutique for select to authenticated
  using (boutique_id = any ((select prive.mes_boutiques())::uuid[]) or prive.est_admin_plateforme());
create policy modification_domaines_membres on public.domaines_boutique for update to authenticated
  using (public.boutique_est_active(boutique_id) and boutique_id = any ((select prive.boutiques_avec_permission('site.gerer'))::uuid[]))
  with check (boutique_id = any ((select prive.boutiques_avec_permission('site.gerer'))::uuid[]));
create policy ecriture_domaines_admin on public.domaines_boutique for all to authenticated
  using (prive.est_admin_plateforme()) with check (prive.est_admin_plateforme());

create or replace function prive.trg_proteger_domaine()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not (prive.est_service() or prive.est_admin_plateforme()) then
    if new.sous_domaine is distinct from old.sous_domaine
       or new.boutique_id is distinct from old.boutique_id
       or new.statut_dns is distinct from old.statut_dns
       or new.statut_ssl is distinct from old.statut_ssl
       or new.principal is distinct from old.principal then
      raise exception 'colonne_protegee: le sous-domaine est attribué à la création et réservé à l''éditeur'
        using errcode = '42501';
    end if;
  end if;
  -- Un changement de domaine personnalisé remet la vérification à zéro ; il exige un plan qui l'autorise.
  if new.domaine_personnalise is distinct from old.domaine_personnalise then
    new.statut_dns := case when new.domaine_personnalise is null then 'non_configure' else 'en_attente' end;
    new.statut_ssl := new.statut_dns;
    if new.domaine_personnalise is not null
       and coalesce((select p.limites ->> 'domaine_personnalise'
                     from public.abonnements a join public.plans p on p.id = a.plan_id
                     where a.boutique_id = new.boutique_id and a.statut in ('essai', 'actif', 'grace') limit 1), 'false') <> 'true' then
      raise exception 'quota_depasse: le plan actuel n''autorise pas de domaine personnalisé' using errcode = 'P0001';
    end if;
  end if;
  return new;
end;
$$;
create trigger proteger_domaine before update on public.domaines_boutique
  for each row execute function prive.trg_proteger_domaine();
create trigger audit after insert or update or delete on public.domaines_boutique
  for each row execute function prive.trg_journaliser();

-- Paramètres, sections, pages, bannières : membres (lecture) / « site.gerer » (écriture) + éditeur.
select prive.creer_politiques_boutique('public.parametres_site', 'parametres.lire', 'site.gerer', array['insert', 'update']);
select prive.creer_politiques_boutique('public.sections_site', 'parametres.lire', 'site.gerer');
select prive.creer_politiques_boutique('public.pages_site', 'parametres.lire', 'site.gerer');
select prive.creer_politiques_boutique('public.bannieres_site', 'parametres.lire', 'site.gerer');

create policy admin_parametres_site on public.parametres_site for all to authenticated
  using (prive.est_admin_plateforme()) with check (prive.est_admin_plateforme());

-- ---------------------------------------------------------------------------
-- Thèmes de départ (catalogue de la plateforme, éditable par l'éditeur)
-- ---------------------------------------------------------------------------
insert into public.themes_site (code, nom_ar, nom_fr, schema_config, plan_minimum) values
  ('classique', 'كلاسيكي', 'Classique',
   '{"entete": "centre", "grille_produits": 2, "style_carte": "bordure", "accueil": "banniere_categories"}'::jsonb, 0),
  ('moderne', 'عصري', 'Moderne',
   '{"entete": "gauche", "grille_produits": 3, "style_carte": "ombre", "accueil": "banniere_nouveautes"}'::jsonb, 1),
  ('elegant', 'أنيق', 'Élégant',
   '{"entete": "centre", "grille_produits": 2, "style_carte": "minimal", "accueil": "plein_ecran"}'::jsonb, 1);

-- Thème autorisé par le plan de la boutique (nombre de thèmes et rang minimal).
create or replace function prive.trg_theme_autorise()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rang integer;
  v_minimum integer;
begin
  if new.theme_id is not null and (tg_op = 'INSERT' or new.theme_id is distinct from old.theme_id)
     and not (prive.est_service() or prive.est_admin_plateforme()) then
    select p.ordre into v_rang
    from public.abonnements a join public.plans p on p.id = a.plan_id
    where a.boutique_id = new.boutique_id and a.statut in ('essai', 'actif', 'grace') limit 1;
    select t.plan_minimum into v_minimum from public.themes_site t where t.id = new.theme_id and t.actif;
    if v_minimum is null or coalesce(v_rang, 0) < v_minimum then
      raise exception 'quota_depasse: thème non disponible avec le plan actuel' using errcode = 'P0001';
    end if;
  end if;
  return new;
end;
$$;
create trigger theme_autorise before insert or update on public.parametres_site
  for each row execute function prive.trg_theme_autorise();
