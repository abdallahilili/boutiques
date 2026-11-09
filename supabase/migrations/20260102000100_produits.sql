-- =============================================================================
-- Produits, variantes (modèle + couleur + taille) et images.
-- Suppression logique uniquement (supprime_le). Quota « produits » du plan sur les variantes.
-- =============================================================================

create type public.statut_produit as enum ('actif', 'inactif');

create table public.produits (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  categorie_id uuid,
  marque_id uuid,
  unite_id uuid,
  nom_ar text,
  nom_fr text,
  description_ar text,
  description_fr text,
  slug text,
  statut public.statut_produit not null default 'actif',
  visible_en_ligne boolean not null default true,
  epingle boolean not null default false,
  ordre_epinglage integer,
  ordre integer not null default 0,
  etiquettes text[] not null default '{}',
  cree_par uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  supprime_le timestamptz,
  unique (boutique_id, id),
  foreign key (boutique_id, categorie_id) references public.categories (boutique_id, id),
  foreign key (boutique_id, marque_id) references public.marques (boutique_id, id),
  foreign key (boutique_id, unite_id) references public.unites (boutique_id, id),
  constraint produits_nom_requis check (coalesce(nom_ar, nom_fr) is not null),
  constraint produits_slug_format check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$')
);
create unique index produits_slug_idx on public.produits (boutique_id, slug);
create index produits_categorie_idx on public.produits (boutique_id, categorie_id) where supprime_le is null;
create index produits_epingle_idx on public.produits (boutique_id, ordre_epinglage) where epingle and supprime_le is null;

create table public.variantes_produit (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  produit_id uuid not null,
  modele_id uuid,
  couleur_id uuid,
  taille_id uuid,
  sku text,
  code_barres text,
  prix_vente numeric(14, 2) not null check (prix_vente >= 0),
  prix_gros numeric(14, 2) check (prix_gros >= 0),
  prix_promo numeric(14, 2) check (prix_promo >= 0),
  promo_debut timestamptz,
  promo_fin timestamptz,
  stock_minimum numeric(14, 3) not null default 0 check (stock_minimum >= 0),
  image_url text,
  actif boolean not null default true,
  cree_par uuid references public.profils (id),
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),
  supprime_le timestamptz,
  unique (boutique_id, id),
  foreign key (boutique_id, produit_id) references public.produits (boutique_id, id) on delete cascade,
  foreign key (boutique_id, modele_id) references public.modeles (boutique_id, id),
  foreign key (boutique_id, couleur_id) references public.couleurs (boutique_id, id),
  foreign key (boutique_id, taille_id) references public.tailles (boutique_id, id),
  constraint variantes_promo_coherente check (prix_promo is null or prix_promo <= prix_vente),
  constraint variantes_promo_dates check (promo_fin is null or promo_debut is null or promo_fin >= promo_debut)
);
create unique index variantes_sku_idx on public.variantes_produit (boutique_id, sku) where sku is not null;
create unique index variantes_code_barres_idx on public.variantes_produit (boutique_id, code_barres) where code_barres is not null;
create unique index variantes_combinaison_idx on public.variantes_produit (produit_id, modele_id, couleur_id, taille_id) nulls not distinct
  where supprime_le is null;
create index variantes_produit_idx on public.variantes_produit (boutique_id, produit_id);

create table public.images_produit (
  id uuid primary key default gen_random_uuid(),
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  produit_id uuid not null,
  variante_id uuid,
  url text not null,
  principale boolean not null default false,
  ordre integer not null default 0,
  cree_le timestamptz not null default now(),
  foreign key (boutique_id, produit_id) references public.produits (boutique_id, id) on delete cascade,
  foreign key (boutique_id, variante_id) references public.variantes_produit (boutique_id, id) on delete cascade
);
create index images_produit_idx on public.images_produit (boutique_id, produit_id, ordre);

-- ---------------------------------------------------------------------------
-- Slug lisible et unique par boutique (SEO) ; EAN-13 interne pour les codes-barres.
-- ---------------------------------------------------------------------------
create or replace function prive.trg_slug_produit()
returns trigger
language plpgsql
as $$
declare
  v_base text;
  v_candidat text;
  v_i integer := 1;
begin
  if new.slug is null or new.slug = '' then
    v_base := prive.slugifier(coalesce(new.nom_fr, new.nom_ar));
    if v_base = '' then
      v_base := 'produit-' || left(new.id::text, 8);
    end if;
    v_candidat := v_base;
    while exists (select 1 from public.produits p where p.boutique_id = new.boutique_id and p.slug = v_candidat) loop
      v_i := v_i + 1;
      v_candidat := v_base || '-' || v_i;
    end loop;
    new.slug := v_candidat;
  end if;
  return new;
end;
$$;
create trigger slug_produit before insert on public.produits
  for each row execute function prive.trg_slug_produit();

-- Chiffre de contrôle EAN-13 à partir de 12 chiffres.
create or replace function prive.ean13(p_base12 text)
returns text
language sql
immutable
as $$
  select p_base12 || ((10 - (sum(substr(p_base12, i, 1)::int * case when i % 2 = 0 then 3 else 1 end) % 10)) % 10)::text
  from generate_series(1, 12) as i;
$$;

-- Compteur annuel ou permanent (annee = 0) par boutique et par type, sans trou, verrouillé par ligne.
create table public.sequences_documents (
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  type_document text not null,
  annee integer not null default 0,
  prochain_numero integer not null default 1 check (prochain_numero >= 1),
  prefixe text,
  primary key (boutique_id, type_document, annee)
);
alter table public.sequences_documents enable row level security;
create policy lecture_sequences_documents on public.sequences_documents for select to authenticated
  using (boutique_id = any ((select prive.boutiques_avec_permission('parametres.lire'))::uuid[]));

-- Attribue le prochain numéro d'une séquence (entier). Appelée uniquement depuis des fonctions SECURITY DEFINER.
create or replace function prive.prochain_compteur(p_boutique uuid, p_type text, p_annee integer default 0)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_numero integer;
begin
  insert into public.sequences_documents (boutique_id, type_document, annee)
  values (p_boutique, p_type, p_annee)
  on conflict do nothing;

  update public.sequences_documents
  set prochain_numero = prochain_numero + 1
  where boutique_id = p_boutique and type_document = p_type and annee = p_annee
  returning prochain_numero - 1 into v_numero;
  return v_numero;
end;
$$;

create or replace function prive.trg_variante_defauts()
returns trigger
language plpgsql
as $$
declare
  v_base text;
begin
  if new.code_barres is null then
    v_base := '29' || lpad(prive.prochain_compteur(new.boutique_id, 'code_barres')::text, 10, '0');
    new.code_barres := prive.ean13(v_base);
  end if;
  return new;
end;
$$;
create trigger variante_defauts before insert on public.variantes_produit
  for each row execute function prive.trg_variante_defauts();

-- Quota de produits (variantes actives) du plan.
create or replace function prive.trg_quota_variantes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform prive.verifier_quota(
    new.boutique_id, 'produits',
    (select count(*) from public.variantes_produit v where v.boutique_id = new.boutique_id and v.supprime_le is null)
  );
  return new;
end;
$$;
create trigger quota_variantes before insert on public.variantes_produit
  for each row execute function prive.trg_quota_variantes();

-- Audit : changement de prix de vente, archivage et suppression de produits.
create trigger audit_prix after update on public.variantes_produit
  for each row when (old.prix_vente is distinct from new.prix_vente or old.prix_promo is distinct from new.prix_promo)
  execute function prive.trg_journaliser();
create trigger audit_archivage after update on public.produits
  for each row when (old.supprime_le is distinct from new.supprime_le)
  execute function prive.trg_journaliser();
create trigger audit_suppression after delete on public.produits
  for each row execute function prive.trg_journaliser();

select prive.attacher_modifie_le('public.produits');
select prive.attacher_modifie_le('public.variantes_produit');
select prive.creer_politiques_boutique('public.produits', 'produits.lire', 'produits.ecrire');
select prive.creer_politiques_boutique('public.variantes_produit', 'produits.lire', 'produits.ecrire');
select prive.creer_politiques_boutique('public.images_produit', 'produits.lire', 'produits.ecrire');
