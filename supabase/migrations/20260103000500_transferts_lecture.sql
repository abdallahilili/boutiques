-- Lecture des transferts pour l'application : liste et détail avec le nom de l'autre boutique (une boutique
-- ne peut pas lire directement les boutiques des autres) et les lignes, sans aucun coût d'achat.

create or replace function public.liste_transferts(p_boutique uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform prive.exiger_permission(p_boutique, 'stock.lire');
  return (
    select coalesce(jsonb_agg(to_jsonb(r) order by r.cree_le desc), '[]'::jsonb)
    from (
      select t.id, t.numero, t.statut, t.total, t.cree_le, t.repondu_le,
             case when t.boutique_emettrice_id = p_boutique then 'envoye' else 'recu' end as sens,
             jsonb_build_object('nom_ar', b.nom_ar, 'nom_fr', b.nom_fr, 'telephone', b.telephone) as autre_boutique
      from public.transferts t
      join public.boutiques b on b.id = case when t.boutique_emettrice_id = p_boutique then t.boutique_destinataire_id else t.boutique_emettrice_id end
      where t.boutique_emettrice_id = p_boutique or t.boutique_destinataire_id = p_boutique
      order by t.cree_le desc
      limit 200
    ) r
  );
end;
$$;

create or replace function public.detail_transfert(p_boutique uuid, p_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_transfert public.transferts;
begin
  perform prive.exiger_permission(p_boutique, 'stock.lire');
  select * into v_transfert from public.transferts t
  where t.id = p_id and (t.boutique_emettrice_id = p_boutique or t.boutique_destinataire_id = p_boutique);
  if not found then
    raise exception 'transfert_introuvable' using errcode = 'P0001';
  end if;
  return jsonb_build_object(
    'id', v_transfert.id, 'numero', v_transfert.numero, 'statut', v_transfert.statut, 'total', v_transfert.total,
    'note', v_transfert.note, 'cree_le', v_transfert.cree_le, 'repondu_le', v_transfert.repondu_le,
    'sens', case when v_transfert.boutique_emettrice_id = p_boutique then 'envoye' else 'recu' end,
    'autre_boutique', (select jsonb_build_object('nom_ar', b.nom_ar, 'nom_fr', b.nom_fr, 'telephone', b.telephone)
                       from public.boutiques b
                       where b.id = case when v_transfert.boutique_emettrice_id = p_boutique then v_transfert.boutique_destinataire_id else v_transfert.boutique_emettrice_id end),
    'lignes', (select coalesce(jsonb_agg(jsonb_build_object('id', l.id, 'libelle_ar', l.libelle_ar, 'libelle_fr', l.libelle_fr,
                'quantite', l.quantite, 'prix_unitaire', l.prix_unitaire, 'total', l.total,
                'variante_destinataire_id', case when v_transfert.boutique_destinataire_id = p_boutique then l.variante_destinataire_id end)
                order by l.ordre), '[]'::jsonb)
               from public.lignes_transfert l where l.transfert_id = v_transfert.id)
  );
end;
$$;

revoke all on function public.liste_transferts(uuid), public.detail_transfert(uuid, uuid) from public, anon;
grant execute on function public.liste_transferts(uuid), public.detail_transfert(uuid, uuid) to authenticated, service_role;
