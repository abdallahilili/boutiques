-- Sous-ensemble de pgTAP pour PGlite (tests locaux sans Docker) : plan, ok, is, isnt, cmp_ok,
-- throws_ok / throws_like / lives_ok, is_empty, finish. Les fichiers de supabase/tests utilisent
-- uniquement ces fonctions, compatibles avec le vrai pgTAP.
create or replace function _tap_enregistrer(p_ok boolean, p_desc text, p_diag text default null)
returns text language plpgsql as $$
declare
  n integer := coalesce(nullif(current_setting('pgtap.run', true), '')::integer, 0) + 1;
  v text;
begin
  perform set_config('pgtap.run', n::text, true);
  if not coalesce(p_ok, false) then
    perform set_config('pgtap.echecs', (coalesce(nullif(current_setting('pgtap.echecs', true), '')::integer, 0) + 1)::text, true);
  end if;
  v := case when coalesce(p_ok, false) then 'ok ' else 'not ok ' end || n || coalesce(' - ' || p_desc, '');
  if not coalesce(p_ok, false) and p_diag is not null then
    v := v || E'\n# ' || replace(p_diag, E'\n', E'\n# ');
  end if;
  return v;
end $$;

create or replace function plan(p_nb integer) returns text language plpgsql as $$
begin
  perform set_config('pgtap.plan', p_nb::text, true);
  perform set_config('pgtap.run', '0', true);
  perform set_config('pgtap.echecs', '0', true);
  return '1..' || p_nb;
end $$;

create or replace function ok(p_condition boolean, p_desc text default null) returns text language sql as $$
  select _tap_enregistrer(p_condition, p_desc)
$$;

create or replace function is(p_obtenu anyelement, p_attendu anyelement, p_desc text default null) returns text language sql as $$
  select _tap_enregistrer(p_obtenu is not distinct from p_attendu, p_desc,
    format('obtenu : %s' || E'\n' || 'attendu : %s', p_obtenu, p_attendu))
$$;

create or replace function isnt(p_obtenu anyelement, p_autre anyelement, p_desc text default null) returns text language sql as $$
  select _tap_enregistrer(p_obtenu is distinct from p_autre, p_desc, format('valeur inattendue : %s', p_obtenu))
$$;

create or replace function cmp_ok(p_a anyelement, p_op text, p_b anyelement, p_desc text default null) returns text language plpgsql as $$
declare v boolean;
begin
  execute format('select $1 %s $2', p_op) into v using p_a, p_b;
  return _tap_enregistrer(v, p_desc, format('%s %s %s', p_a, p_op, p_b));
end $$;

create or replace function lives_ok(p_sql text, p_desc text default null) returns text language plpgsql as $$
begin
  execute p_sql;
  return _tap_enregistrer(true, p_desc);
exception when others then
  return _tap_enregistrer(false, p_desc, format('exception inattendue : %s (%s)', sqlerrm, sqlstate));
end $$;

create or replace function throws_ok(p_sql text, p_errcode text, p_errmsg text, p_desc text default null) returns text language plpgsql as $$
begin
  execute p_sql;
  return _tap_enregistrer(false, p_desc, 'aucune exception levée');
exception when others then
  return _tap_enregistrer(
    (p_errcode is null or sqlstate = p_errcode) and (p_errmsg is null or sqlerrm = p_errmsg), p_desc,
    format('obtenu : %s (%s)' || E'\n' || 'attendu : %s (%s)', sqlerrm, sqlstate, p_errmsg, p_errcode));
end $$;

create or replace function throws_like(p_sql text, p_motif text, p_desc text default null) returns text language plpgsql as $$
begin
  execute p_sql;
  return _tap_enregistrer(false, p_desc, 'aucune exception levée');
exception when others then
  return _tap_enregistrer(sqlerrm like p_motif, p_desc, format('obtenu : %s (%s)' || E'\n' || 'motif : %s', sqlerrm, sqlstate, p_motif));
end $$;

create or replace function is_empty(p_sql text, p_desc text default null) returns text language plpgsql as $$
declare n bigint;
begin
  execute 'select count(*) from (' || p_sql || ') q' into n;
  return _tap_enregistrer(n = 0, p_desc, format('%s ligne(s) retournée(s)', n));
end $$;

create or replace function finish() returns setof text language plpgsql as $$
declare
  prevu integer := nullif(current_setting('pgtap.plan', true), '')::integer;
  fait integer := coalesce(nullif(current_setting('pgtap.run', true), '')::integer, 0);
  echecs integer := coalesce(nullif(current_setting('pgtap.echecs', true), '')::integer, 0);
begin
  if prevu is not null and prevu <> fait then
    return next format('# Looks like you planned %s tests but ran %s', prevu, fait);
  end if;
  if echecs > 0 then
    return next format('# Looks like you failed %s test(s) of %s', echecs, fait);
  end if;
end $$;
