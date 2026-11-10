-- =============================================================================
-- Suivi des commandes par numéro de téléphone seul (sans numéro de commande).
-- Retourne les 10 dernières commandes de la boutique pour ce numéro, au même format que
-- suivre_commande (aucune adresse ni nom du client). Débit limité par numéro et par IP ;
-- un numéro sans commande renvoie une liste vide (aucune information sur son existence).
-- =============================================================================

create or replace function prive.resume_suivi(p_commande_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_commande public.commandes;
begin
  select * into v_commande from public.commandes c where c.id = p_commande_id;
  return jsonb_build_object(
    'numero', v_commande.numero, 'statut', v_commande.statut, 'statut_paiement', v_commande.statut_paiement,
    'mode_livraison', v_commande.mode_livraison, 'mode_paiement', v_commande.mode_paiement,
    'sous_total', v_commande.sous_total, 'frais_livraison', v_commande.frais_livraison, 'total', v_commande.total,
    'cree_le', v_commande.cree_le, 'justificatif_envoye', v_commande.justificatif_url is not null,
    'lignes', (select coalesce(jsonb_agg(jsonb_build_object('libelle_ar', l.libelle_ar, 'libelle_fr', l.libelle_fr,
                'quantite', l.quantite, 'prix_unitaire', l.prix_unitaire, 'total', l.total)), '[]'::jsonb)
               from public.lignes_commande l where l.commande_id = v_commande.id),
    'historique', (select coalesce(jsonb_agg(jsonb_build_object('statut', h.statut, 'date_statut', h.date_statut) order by h.date_statut), '[]'::jsonb)
                   from public.historique_statuts_commande h where h.commande_id = v_commande.id),
    'boutique', (select jsonb_build_object('nom_ar', b.nom_ar, 'nom_fr', b.nom_fr, 'telephone', b.telephone, 'whatsapp', b.whatsapp)
                 from public.boutiques b where b.id = v_commande.boutique_id)
  );
end;
$$;
revoke all on function prive.resume_suivi(uuid) from public;

create or replace function public.suivre_commandes_par_telephone(p_slug text, p_telephone text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tel text := prive.normaliser_telephone(p_telephone);
  v_ip text := prive.adresse_ip();
begin
  perform prive.limiter_debit('suivi:tel:' || v_tel, 20, interval '1 hour');
  if v_ip is not null then
    perform prive.limiter_debit('suivi:ip:' || v_ip, 60, interval '1 hour');
  end if;
  return (
    select coalesce(jsonb_agg(prive.resume_suivi(r.id) order by r.cree_le desc), '[]'::jsonb)
    from (
      select c.id, c.cree_le
      from public.commandes c join public.boutiques b on b.id = c.boutique_id
      where b.slug = p_slug and c.telephone = v_tel
      order by c.cree_le desc
      limit 10
    ) r
  );
end;
$$;
revoke all on function public.suivre_commandes_par_telephone(text, text) from public;
grant execute on function public.suivre_commandes_par_telephone(text, text) to anon, authenticated, service_role;
