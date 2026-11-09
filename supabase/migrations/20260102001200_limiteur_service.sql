-- Limiteur de débit exposé aux Edge Functions (service_role) : inscription des clientes,
-- créations de comptes… Réutilise prive.limiter_debit (exception `trop_de_requetes`).
create or replace function public.limiter_requete(p_cle text, p_max integer, p_fenetre_secondes integer)
returns void
language sql
security definer
set search_path = public
as $$
  select prive.limiter_debit(p_cle, p_max, make_interval(secs => p_fenetre_secondes));
$$;
revoke all on function public.limiter_requete(text, integer, integer) from public, anon, authenticated;
grant execute on function public.limiter_requete(text, integer, integer) to service_role;
