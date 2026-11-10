-- =============================================================================
-- Phase 2 — Notifications métier : nouvelle commande (propriétaire, manager, vendeuse), changement de
-- statut de commande (propriétaire, manager), impayés échus (tâche quotidienne). Les notifications sont
-- enregistrées en base (in-app) ; la livraison push FCM est faite par les Edge Functions
-- (on-order-created, stock-alerts-cron).
-- =============================================================================

create or replace function prive.trg_notifier_commande()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ids uuid[];
begin
  if tg_op = 'INSERT' then
    v_ids := prive.notifier_boutique_ids(
      new.boutique_id, 'commandes.lire', 'commande', 'طلب جديد', 'Nouvelle commande',
      new.numero || ' — ' || new.nom_client || ' — ' || new.total::text,
      new.numero || ' — ' || new.nom_client || ' — ' || new.total::text,
      jsonb_build_object('commande_id', new.id, 'numero', new.numero, 'statut', new.statut));
  elsif new.statut is distinct from old.statut then
    v_ids := prive.notifier_boutique_ids(
      new.boutique_id, 'rapports.financiers', 'commande_statut', 'تغيّر حالة الطلب', 'Statut de commande modifié',
      new.numero || ' : ' || new.statut::text, new.numero || ' : ' || new.statut::text,
      jsonb_build_object('commande_id', new.id, 'numero', new.numero, 'statut', new.statut));
  end if;
  return null;
end;
$$;
create trigger notifier_commande_creee after insert on public.commandes
  for each row execute function prive.trg_notifier_commande();
create trigger notifier_commande_statut after update of statut on public.commandes
  for each row execute function prive.trg_notifier_commande();

-- Tâche quotidienne : une synthèse par boutique et par jour des factures échues non soldées.
create or replace function public.generer_alertes_impayes()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_boutique record;
  v_ids uuid[] := '{}';
begin
  if not prive.est_service() then
    raise exception 'acces_refuse' using errcode = '42501';
  end if;
  for v_boutique in
    select d.boutique_id, count(*) as nombre, sum(d.reste) as montant
    from public.documents_vente d join public.boutiques b on b.id = d.boutique_id
    where d.type = 'facture' and d.statut in ('emise', 'partiellement_payee') and d.reste > 0
      and d.date_echeance is not null and d.date_echeance < current_date and b.statut in ('essai', 'actif', 'grace')
    group by d.boutique_id
  loop
    if exists (select 1 from public.notifications n where n.boutique_id = v_boutique.boutique_id and n.type = 'impaye_echu'
               and n.cree_le >= date_trunc('day', now())) then
      continue;
    end if;
    v_ids := v_ids || prive.notifier_boutique_ids(
      v_boutique.boutique_id, 'rapports.financiers', 'impaye_echu', 'فواتير متأخرة السداد', 'Impayés échus',
      format('%s فاتورة متأخرة — المبلغ: %s', v_boutique.nombre, v_boutique.montant),
      format('%s facture(s) échue(s) — montant dû : %s', v_boutique.nombre, v_boutique.montant),
      jsonb_build_object('nombre', v_boutique.nombre, 'montant', v_boutique.montant));
  end loop;
  return jsonb_build_object('notification_ids', to_jsonb(v_ids), 'nombre', coalesce(array_length(v_ids, 1), 0));
end;
$$;
revoke all on function public.generer_alertes_impayes() from public, anon, authenticated;
grant execute on function public.generer_alertes_impayes() to service_role;
