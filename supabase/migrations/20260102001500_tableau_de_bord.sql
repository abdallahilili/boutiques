-- Tableau de bord de l'app commerçante : chiffre d'affaires, ruptures, commandes à traiter, impayés.
-- Les montants financiers ne sont retournés qu'aux rôles ayant « rapports.financiers » ;
-- les compteurs opérationnels sont visibles de tous les membres (stock / commandes).
create or replace function public.tableau_de_bord(p_boutique_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_fuseau text;
  v_jour timestamptz;
  v_financier boolean;
begin
  perform prive.exiger_permission(p_boutique_id, 'pos.vendre');
  select b.fuseau_horaire into v_fuseau from public.boutiques b where b.id = p_boutique_id;
  v_jour := date_trunc('day', now() at time zone v_fuseau) at time zone v_fuseau;
  v_financier := prive.a_permission(p_boutique_id, 'rapports.financiers');

  return jsonb_build_object(
    'ca_jour', case when v_financier then (select coalesce(sum(d.total), 0) from public.documents_vente d
                where d.boutique_id = p_boutique_id and d.type in ('facture', 'ticket') and d.statut <> 'annulee' and d.date_emission >= v_jour) end,
    'ca_semaine', case when v_financier then (select coalesce(sum(d.total), 0) from public.documents_vente d
                where d.boutique_id = p_boutique_id and d.type in ('facture', 'ticket') and d.statut <> 'annulee' and d.date_emission >= v_jour - interval '6 days') end,
    'ca_mois', case when v_financier then (select coalesce(sum(d.total), 0) from public.documents_vente d
                where d.boutique_id = p_boutique_id and d.type in ('facture', 'ticket') and d.statut <> 'annulee'
                  and d.date_emission >= date_trunc('month', now() at time zone v_fuseau) at time zone v_fuseau) end,
    'impayes', case when v_financier then (select coalesce(sum(c.solde), 0) from public.clients c where c.boutique_id = p_boutique_id and c.solde > 0) end,
    'nb_ventes_jour', (select count(*) from public.documents_vente d
                       where d.boutique_id = p_boutique_id and d.type in ('facture', 'ticket') and d.statut <> 'annulee' and d.date_emission >= v_jour),
    'ruptures', (select count(*) from public.variantes_produit v
                 where v.boutique_id = p_boutique_id and v.actif and v.supprime_le is null
                   and coalesce((select sum(l.quantite_restante) from public.lots_stock l where l.variante_id = v.id), 0) <= 0),
    'sous_seuil', (select count(*) from public.variantes_produit v
                   where v.boutique_id = p_boutique_id and v.actif and v.supprime_le is null and v.stock_minimum > 0
                     and coalesce((select sum(l.quantite_restante) from public.lots_stock l where l.variante_id = v.id), 0) between 1 and v.stock_minimum),
    'commandes_a_traiter', (select count(*) from public.commandes c
                            where c.boutique_id = p_boutique_id and c.statut in ('nouvelle', 'confirmee', 'en_preparation'))
  );
end;
$$;
revoke all on function public.tableau_de_bord(uuid) from public, anon;
grant execute on function public.tableau_de_bord(uuid) to authenticated, service_role;
