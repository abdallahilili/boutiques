-- =============================================================================
-- Base : schéma privé, privilèges par défaut, utilitaires génériques.
-- Les helpers de sécurité (RLS) vivent dans le schéma `prive`, non exposé par l'API.
-- =============================================================================

create schema if not exists prive;
grant usage on schema prive to anon, authenticated, service_role;

-- Les nouvelles tables ne sont jamais lisibles par `anon` : seules les vues publiques
-- explicitement accordées (boutique en ligne) le sont.
alter default privileges for role postgres in schema public revoke all on tables from anon;
alter default privileges for role postgres in schema public revoke all on sequences from anon;

-- Horodatage automatique `modifie_le`.
create or replace function prive.maj_modifie_le()
returns trigger
language plpgsql
as $$
begin
  new.modifie_le := now();
  return new;
end;
$$;

-- Attache le trigger `modifie_le` à une table.
create or replace function prive.attacher_modifie_le(p_table regclass)
returns void
language plpgsql
as $$
begin
  execute format(
    'create trigger maj_modifie_le before update on %s for each row execute function prive.maj_modifie_le()',
    p_table
  );
end;
$$;

-- Interdit toute modification/suppression (tables en ajout seul : journal_audit, mouvements_stock…).
create or replace function prive.interdire_modification()
returns trigger
language plpgsql
as $$
begin
  raise exception 'table_en_ajout_seul: % est en ajout seul (%)', tg_table_name, tg_op
    using errcode = 'P0001';
end;
$$;

-- Normalisation d'un numéro de téléphone : chiffres uniquement, indicatif pays inclus.
create or replace function prive.normaliser_telephone(p_valeur text, p_indicatif text default '222')
returns text
language plpgsql
immutable
as $$
declare
  v text := regexp_replace(coalesce(p_valeur, ''), '[^0-9]', '', 'g');
begin
  if v like '00%' then
    v := substr(v, 3);
  end if;
  if length(v) <= 8 then
    v := p_indicatif || v;
  end if;
  return v;
end;
$$;
