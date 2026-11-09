-- =============================================================================
-- Fonctions de gestion des comptes, appelées par les Edge Functions (service_role)
-- et permissions de l'appelant pour les clients.
-- =============================================================================

-- Permissions de l'appelant dans une boutique (pour l'affichage conditionnel côté apps ;
-- les contrôles réels restent faits par la RLS et les RPC).
create or replace function public.mes_permissions(p_boutique uuid)
returns text[]
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(array_agg(pr.cle_permission order by pr.cle_permission), '{}'::text[])
  from public.membres_boutique m
  join public.permissions_role pr on pr.role_id = m.role_id and pr.autorise
  where m.utilisateur_id = auth.uid() and m.boutique_id = p_boutique and m.statut = 'actif';
$$;
revoke all on function public.mes_permissions(uuid) from public, anon;
grant execute on function public.mes_permissions(uuid) to authenticated, service_role;

-- Sous-domaines interdits (services techniques de la plateforme).
create or replace function prive.slugs_reserves()
returns text[]
language sql
immutable
as $$
  select array['www', 'admin', 'api', 'app', 'mail', 'support', 'static', 'cdn', 'boutique', 'boutiques', 'shop', 'staging', 'dev'];
$$;

create or replace function prive.slugifier(p_texte text)
returns text
language sql
immutable
as $$
  select trim(both '-' from left(
    regexp_replace(
      translate(lower(coalesce(p_texte, '')), 'àâäáãéèêëíîïóôöõúùûüçñ', 'aaaaaeeeeiiiooooouuuucn'),
      '[^a-z0-9]+', '-', 'g'),
    38));
$$;

-- Premier sous-domaine libre dérivé de la base : base, base-2, base-3…
create or replace function prive.slug_disponible(p_base text)
returns text
language plpgsql
stable
as $$
declare
  v_base text := prive.slugifier(p_base);
  v_candidat text;
  v_i integer := 1;
begin
  if length(v_base) < 3 or v_base = any (prive.slugs_reserves()) then
    v_base := left('boutique-' || v_base, 38);
  end if;
  v_candidat := v_base;
  while exists (select 1 from public.boutiques b where b.slug = v_candidat) loop
    v_i := v_i + 1;
    v_candidat := left(v_base, 38 - length(v_i::text) - 1) || '-' || v_i;
  end loop;
  return v_candidat;
end;
$$;

-- Crée en une seule transaction : profil, commerçante, boutique (+ défauts, membre propriétaire,
-- abonnement d'essai). L'utilisateur Auth existe déjà (créé par admin-create-merchant).
create or replace function public.creer_commercante_avec_boutique(p_donnees jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_utilisateur uuid := (p_donnees ->> 'utilisateur_id')::uuid;
  v_commercante uuid;
  v_boutique uuid;
  v_slug text;
begin
  insert into public.profils (id, nom_ar, nom_fr, telephone, email, langue)
  values (
    v_utilisateur, p_donnees ->> 'nom_ar', p_donnees ->> 'nom_fr', p_donnees ->> 'telephone',
    p_donnees ->> 'email', coalesce(p_donnees ->> 'langue', 'ar')
  );

  insert into public.commercantes (utilisateur_id, nom_ar, nom_fr, telephone, whatsapp, email, ville, notes, cree_par)
  values (
    v_utilisateur, p_donnees ->> 'nom_ar', p_donnees ->> 'nom_fr', p_donnees ->> 'telephone',
    coalesce(p_donnees ->> 'whatsapp', p_donnees ->> 'telephone'), p_donnees ->> 'email',
    p_donnees ->> 'ville', p_donnees ->> 'notes', (p_donnees ->> 'cree_par')::uuid
  )
  returning id into v_commercante;

  v_slug := prive.slug_disponible(coalesce(
    nullif(p_donnees #>> '{boutique,slug}', ''),
    p_donnees #>> '{boutique,nom_fr}',
    p_donnees #>> '{boutique,nom_ar}'
  ));

  v_boutique := public.creer_boutique_avec_defauts(
    v_commercante,
    p_donnees #>> '{boutique,nom_ar}',
    p_donnees #>> '{boutique,nom_fr}',
    v_slug,
    p_donnees #>> '{boutique,type_activite}',
    p_donnees ->> 'telephone',
    coalesce(p_donnees #>> '{boutique,devise}', 'MRU')
  );

  return jsonb_build_object('commercante_id', v_commercante, 'boutique_id', v_boutique, 'slug', v_slug);
end;
$$;
revoke all on function public.creer_commercante_avec_boutique(jsonb) from public, anon, authenticated;
grant execute on function public.creer_commercante_avec_boutique(jsonb) to service_role;

-- Ajoute une employée à une boutique (et crée son profil si le compte Auth vient d'être créé).
-- Le rôle propriétaire ne peut pas être attribué ici. Le quota du plan est vérifié par trigger.
create or replace function public.inviter_membre(p_donnees jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_utilisateur uuid := (p_donnees ->> 'utilisateur_id')::uuid;
  v_role uuid;
  v_membre uuid;
begin
  select r.id into v_role from public.roles r
  where r.boutique_id is null and r.cle = p_donnees ->> 'role_cle' and r.cle <> 'proprietaire';
  if v_role is null then
    raise exception 'role_invalide' using errcode = 'P0001';
  end if;

  if p_donnees ? 'profil' then
    insert into public.profils (id, nom_ar, nom_fr, telephone, email, langue)
    values (
      v_utilisateur, p_donnees #>> '{profil,nom_ar}', p_donnees #>> '{profil,nom_fr}',
      p_donnees #>> '{profil,telephone}', p_donnees #>> '{profil,email}', coalesce(p_donnees #>> '{profil,langue}', 'ar')
    );
  end if;

  insert into public.membres_boutique (boutique_id, utilisateur_id, role_id, statut, invite_par)
  values ((p_donnees ->> 'boutique_id')::uuid, v_utilisateur, v_role, 'actif', (p_donnees ->> 'invite_par')::uuid)
  returning id into v_membre;
  return v_membre;
end;
$$;
revoke all on function public.inviter_membre(jsonb) from public, anon, authenticated;
grant execute on function public.inviter_membre(jsonb) to service_role;
