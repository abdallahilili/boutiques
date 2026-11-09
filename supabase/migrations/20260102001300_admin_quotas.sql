-- Quotas consommés par une boutique (fiche boutique de la console éditeur).
-- L'éditeur ne lit pas directement les tables métier : il passe par cette fonction agrégée.
create or replace function public.admin_quotas_boutique(p_boutique uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not prive.est_admin_plateforme() then
    raise exception 'acces_refuse: réservé à l''éditeur' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'produits', (select count(*) from public.variantes_produit v where v.boutique_id = p_boutique and v.supprime_le is null),
    'utilisateurs', (select count(*) from public.membres_boutique m where m.boutique_id = p_boutique and m.statut <> 'desactive'),
    'commandes_30j', (select count(*) from public.commandes c where c.boutique_id = p_boutique and c.cree_le >= now() - interval '30 days'),
    'limites', coalesce((select p.limites from public.abonnements a join public.plans p on p.id = a.plan_id
                         where a.boutique_id = p_boutique and a.statut in ('essai', 'actif', 'grace') limit 1), '{}'::jsonb)
  );
end;
$$;
revoke all on function public.admin_quotas_boutique(uuid) from public, anon;
grant execute on function public.admin_quotas_boutique(uuid) to authenticated, service_role;
