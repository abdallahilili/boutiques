-- =============================================================================
-- Phase 2 — Rapports, alertes de stock et traitement quotidien des abonnements.
-- Rapports : permission « rapports.financiers » (propriétaire et manager) ; les marges exigent en plus
-- « couts.voir ». Montants nets des avoirs. Périodes en dates locales de la boutique (fuseau).
-- Tâches quotidiennes (service uniquement) : alertes de stock, abonnements (grâce 7 jours, suspension, rappels).
-- =============================================================================

create or replace function prive.bornes_periode(p_boutique uuid, p_debut date, p_fin date, out debut timestamptz, out fin timestamptz)
language sql
stable
security definer
set search_path = public
as $$
  select p_debut::timestamp at time zone b.fuseau_horaire, (p_fin + 1)::timestamp at time zone b.fuseau_horaire
  from public.boutiques b where b.id = p_boutique;
$$;

-- Notification à toutes les utilisatrices d'une boutique ayant une permission ; retourne les identifiants créés.
create or replace function prive.notifier_boutique_ids(
  p_boutique uuid, p_permission text, p_type text, p_titre_ar text, p_titre_fr text, p_corps_ar text, p_corps_fr text, p_donnees jsonb
)
returns uuid[]
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ids uuid[];
begin
  with ins as (
    insert into public.notifications (boutique_id, utilisateur_id, type, titre_ar, titre_fr, corps_ar, corps_fr, cible, donnees)
    select p_boutique, u, p_type, p_titre_ar, p_titre_fr, p_corps_ar, p_corps_fr, 'boutique', p_donnees
    from prive.utilisatrices_avec_permission(p_boutique, p_permission) u
    returning id
  )
  select coalesce(array_agg(id), '{}') into v_ids from ins;
  return v_ids;
end;
$$;

-- ---------------------------------------------------------------------------
-- Synthèse : chiffre d'affaires, marge, dépenses, résultat, valeur du stock, impayés, dettes.
-- ---------------------------------------------------------------------------
create or replace function public.rapport_synthese(p_boutique uuid, p_debut date, p_fin date)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_debut timestamptz;
  v_fin timestamptz;
  v_couts boolean;
  v_ca numeric;
  v_nb integer;
  v_marge numeric;
  v_depenses numeric;
  v_encaisse numeric;
begin
  perform prive.exiger_permission(p_boutique, 'rapports.financiers');
  v_couts := prive.a_permission(p_boutique, 'couts.voir');
  select b.debut, b.fin into v_debut, v_fin from prive.bornes_periode(p_boutique, p_debut, p_fin) b;

  select coalesce(sum(case when d.type = 'avoir' then -d.total else d.total end), 0),
         count(*) filter (where d.type <> 'avoir')
  into v_ca, v_nb
  from public.documents_vente d
  where d.boutique_id = p_boutique and d.statut <> 'annulee' and d.type in ('facture', 'ticket', 'avoir')
    and d.date_emission >= v_debut and d.date_emission < v_fin;

  select coalesce(sum(case when d.type = 'avoir' then -(l.total - l.quantite * l.cout_unitaire) else l.total - l.quantite * l.cout_unitaire end), 0)
  into v_marge
  from public.lignes_document_vente l join public.documents_vente d on d.id = l.document_id
  where d.boutique_id = p_boutique and d.statut <> 'annulee' and d.type in ('facture', 'ticket', 'avoir')
    and d.date_emission >= v_debut and d.date_emission < v_fin;

  select coalesce(sum(dp.montant), 0) into v_depenses from public.depenses dp
  where dp.boutique_id = p_boutique and dp.date_depense between p_debut and p_fin;

  select coalesce(sum(case when d.type = 'avoir' then -p.montant else p.montant end), 0) into v_encaisse
  from public.paiements p left join public.documents_vente d on d.id = p.document_id
  where p.boutique_id = p_boutique and p.paye_le >= v_debut and p.paye_le < v_fin;

  return jsonb_build_object(
    'debut', p_debut, 'fin', p_fin,
    'chiffre_affaires', v_ca, 'nb_ventes', v_nb, 'encaisse', v_encaisse,
    'marge_brute', case when v_couts then v_marge end,
    'depenses', v_depenses,
    'resultat', case when v_couts then v_marge - v_depenses end,
    'valeur_stock', case when v_couts then (select coalesce(sum(s.quantite_restante * s.cout_unitaire), 0)
                                            from public.lots_stock s where s.boutique_id = p_boutique and s.quantite_restante > 0) end,
    'impayes_clients', (select coalesce(sum(c.solde), 0) from public.clients c where c.boutique_id = p_boutique and c.supprime_le is null and c.solde > 0),
    'dettes_fournisseurs', (select coalesce(sum(f.solde), 0) from public.fournisseurs f where f.boutique_id = p_boutique and f.supprime_le is null and f.solde > 0)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Ventes par axe : jour, produit, categorie, vendeuse, mode_paiement, canal.
-- Lignes : { cle, libelle_ar, libelle_fr, nb, quantite, ca, marge }
-- ---------------------------------------------------------------------------
create or replace function public.rapport_ventes(p_boutique uuid, p_debut date, p_fin date, p_axe text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_debut timestamptz;
  v_fin timestamptz;
  v_couts boolean;
  v_fuseau text;
  v_resultat jsonb;
begin
  perform prive.exiger_permission(p_boutique, 'rapports.financiers');
  if p_axe not in ('jour', 'produit', 'categorie', 'vendeuse', 'mode_paiement', 'canal') then
    raise exception 'parametres_invalides: axe' using errcode = 'P0001';
  end if;
  v_couts := prive.a_permission(p_boutique, 'couts.voir');
  select b.debut, b.fin into v_debut, v_fin from prive.bornes_periode(p_boutique, p_debut, p_fin) b;
  select b.fuseau_horaire into v_fuseau from public.boutiques b where b.id = p_boutique;

  if p_axe in ('produit', 'categorie') then
    select coalesce(jsonb_agg(to_jsonb(t) order by t.ca desc), '[]'::jsonb) into v_resultat
    from (
      select case p_axe when 'produit' then pr.id::text else coalesce(ca.id::text, '-') end as cle,
             case p_axe when 'produit' then pr.nom_ar else coalesce(ca.nom_ar, 'بدون فئة') end as libelle_ar,
             case p_axe when 'produit' then pr.nom_fr else coalesce(ca.nom_fr, 'Sans catégorie') end as libelle_fr,
             count(distinct d.id) as nb,
             sum(case when d.type = 'avoir' then -l.quantite else l.quantite end) as quantite,
             sum(case when d.type = 'avoir' then -l.total else l.total end) as ca,
             case when v_couts then sum(case when d.type = 'avoir' then -(l.total - l.quantite * l.cout_unitaire) else l.total - l.quantite * l.cout_unitaire end) end as marge
      from public.lignes_document_vente l
      join public.documents_vente d on d.id = l.document_id
      left join public.variantes_produit v on v.id = l.variante_id
      left join public.produits pr on pr.id = v.produit_id
      left join public.categories ca on ca.id = pr.categorie_id
      where d.boutique_id = p_boutique and d.statut <> 'annulee' and d.type in ('facture', 'ticket', 'avoir')
        and d.date_emission >= v_debut and d.date_emission < v_fin
        and (p_axe = 'categorie' or pr.id is not null)
      group by 1, 2, 3
    ) t;
  elsif p_axe = 'mode_paiement' then
    select coalesce(jsonb_agg(to_jsonb(t) order by t.ca desc), '[]'::jsonb) into v_resultat
    from (
      select m.id::text as cle, m.nom_ar as libelle_ar, m.nom_fr as libelle_fr, count(*) as nb, null::numeric as quantite,
             sum(case when d.type = 'avoir' then -p.montant else p.montant end) as ca, null::numeric as marge
      from public.paiements p
      join public.modes_paiement m on m.id = p.mode_paiement_id
      left join public.documents_vente d on d.id = p.document_id
      where p.boutique_id = p_boutique and p.paye_le >= v_debut and p.paye_le < v_fin
      group by m.id, m.nom_ar, m.nom_fr
    ) t;
  else
    select coalesce(jsonb_agg(to_jsonb(t) order by case when p_axe = 'jour' then null else t.ca end desc nulls last, t.cle), '[]'::jsonb) into v_resultat
    from (
      select case p_axe when 'jour' then (d.date_emission at time zone v_fuseau)::date::text
                        when 'vendeuse' then coalesce(d.utilisateur_id::text, '-')
                        else d.canal::text end as cle,
             max(case p_axe when 'jour' then (d.date_emission at time zone v_fuseau)::date::text
                        when 'vendeuse' then coalesce(pf.nom_ar, pf.nom_fr, '—')
                        else d.canal::text end) as libelle_ar,
             max(case p_axe when 'jour' then (d.date_emission at time zone v_fuseau)::date::text
                        when 'vendeuse' then coalesce(pf.nom_fr, pf.nom_ar, '—')
                        else d.canal::text end) as libelle_fr,
             count(*) filter (where d.type <> 'avoir') as nb, null::numeric as quantite,
             sum(case when d.type = 'avoir' then -d.total else d.total end) as ca,
             case when v_couts then sum(case when d.type = 'avoir' then -d.marge_doc else d.marge_doc end) end as marge
      from (select d0.*, (select sum(l.total - l.quantite * l.cout_unitaire) from public.lignes_document_vente l where l.document_id = d0.id) as marge_doc
            from public.documents_vente d0) d
      left join public.profils pf on pf.id = d.utilisateur_id
      where d.boutique_id = p_boutique and d.statut <> 'annulee' and d.type in ('facture', 'ticket', 'avoir')
        and d.date_emission >= v_debut and d.date_emission < v_fin
      group by 1
    ) t;
  end if;
  return v_resultat;
end;
$$;

-- ---------------------------------------------------------------------------
-- Produits : meilleurs (par quantité vendue) ou dormants (en stock, sans vente sur la période).
-- ---------------------------------------------------------------------------
create or replace function public.rapport_produits(p_boutique uuid, p_debut date, p_fin date, p_type text, p_limite integer default 20)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_debut timestamptz;
  v_fin timestamptz;
  v_couts boolean;
  v_resultat jsonb;
begin
  perform prive.exiger_permission(p_boutique, 'rapports.financiers');
  if p_type not in ('meilleurs', 'dormants') then
    raise exception 'parametres_invalides: type' using errcode = 'P0001';
  end if;
  v_couts := prive.a_permission(p_boutique, 'couts.voir');
  select b.debut, b.fin into v_debut, v_fin from prive.bornes_periode(p_boutique, p_debut, p_fin) b;
  p_limite := least(greatest(coalesce(p_limite, 20), 1), 200);

  if p_type = 'meilleurs' then
    select coalesce(jsonb_agg(to_jsonb(t) order by t.quantite desc), '[]'::jsonb) into v_resultat
    from (
      select l.variante_id, prive.libelle_variante(l.variante_id, 'ar') as libelle_ar, prive.libelle_variante(l.variante_id, 'fr') as libelle_fr,
             sum(case when d.type = 'avoir' then -l.quantite else l.quantite end) as quantite,
             sum(case when d.type = 'avoir' then -l.total else l.total end) as ca,
             case when v_couts then sum(case when d.type = 'avoir' then -(l.total - l.quantite * l.cout_unitaire) else l.total - l.quantite * l.cout_unitaire end) end as marge
      from public.lignes_document_vente l join public.documents_vente d on d.id = l.document_id
      where d.boutique_id = p_boutique and d.statut <> 'annulee' and d.type in ('facture', 'ticket', 'avoir')
        and d.date_emission >= v_debut and d.date_emission < v_fin and l.variante_id is not null
      group by l.variante_id
      order by 4 desc
      limit p_limite
    ) t;
  else
    select coalesce(jsonb_agg(to_jsonb(t) order by t.valeur desc nulls last), '[]'::jsonb) into v_resultat
    from (
      select v.id as variante_id, prive.libelle_variante(v.id, 'ar') as libelle_ar, prive.libelle_variante(v.id, 'fr') as libelle_fr,
             s.en_stock,
             case when v_couts then s.valeur end as valeur,
             (select max(d.date_emission) from public.lignes_document_vente l join public.documents_vente d on d.id = l.document_id
              where l.variante_id = v.id and d.type in ('facture', 'ticket') and d.statut <> 'annulee') as derniere_vente
      from public.variantes_produit v
      join (select l.variante_id, sum(l.quantite_restante) as en_stock, sum(l.quantite_restante * l.cout_unitaire) as valeur
            from public.lots_stock l where l.boutique_id = p_boutique and l.quantite_restante > 0 group by l.variante_id) s on s.variante_id = v.id
      where v.boutique_id = p_boutique and v.supprime_le is null and v.actif
        and not exists (
          select 1 from public.lignes_document_vente l join public.documents_vente d on d.id = l.document_id
          where l.variante_id = v.id and d.type in ('facture', 'ticket') and d.statut <> 'annulee'
            and d.date_emission >= v_debut and d.date_emission < v_fin)
      order by s.valeur desc nulls last
      limit p_limite
    ) t;
  end if;
  return v_resultat;
end;
$$;

-- ---------------------------------------------------------------------------
-- Valeur du stock par variante (coût moyen pondéré des lots restants)
-- ---------------------------------------------------------------------------
create or replace function public.rapport_stock(p_boutique uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_couts boolean;
  v_lignes jsonb;
begin
  perform prive.exiger_permission(p_boutique, 'rapports.financiers');
  v_couts := prive.a_permission(p_boutique, 'couts.voir');
  select coalesce(jsonb_agg(to_jsonb(t) order by t.valeur desc nulls last), '[]'::jsonb) into v_lignes
  from (
    select v.id as variante_id, prive.libelle_variante(v.id, 'ar') as libelle_ar, prive.libelle_variante(v.id, 'fr') as libelle_fr,
           coalesce(s.en_stock, 0) as en_stock, v.stock_minimum,
           case when v_couts and coalesce(s.en_stock, 0) > 0 then round(s.valeur / s.en_stock, 4) end as cout_moyen,
           case when v_couts then coalesce(s.valeur, 0) end as valeur
    from public.variantes_produit v
    left join (select l.variante_id, sum(l.quantite_restante) as en_stock, sum(l.quantite_restante * l.cout_unitaire) as valeur
               from public.lots_stock l where l.boutique_id = p_boutique group by l.variante_id) s on s.variante_id = v.id
    where v.boutique_id = p_boutique and v.supprime_le is null and v.actif
    limit 5000
  ) t;
  return jsonb_build_object(
    'valeur_totale', case when v_couts then (select coalesce(sum(l.quantite_restante * l.cout_unitaire), 0) from public.lots_stock l
                                              where l.boutique_id = p_boutique and l.quantite_restante > 0) end,
    'lignes', v_lignes);
end;
$$;

-- ---------------------------------------------------------------------------
-- Impayés clientes et dettes fournisseurs
-- ---------------------------------------------------------------------------
create or replace function public.rapport_impayes(p_boutique uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform prive.exiger_permission(p_boutique, 'rapports.financiers');
  return jsonb_build_object(
    'clients', (select coalesce(jsonb_agg(to_jsonb(t) order by t.solde desc), '[]'::jsonb) from (
        select c.id, c.nom_ar, c.nom_fr, c.telephone, c.solde,
               (select min(coalesce(d.date_echeance, d.date_emission::date)) from public.documents_vente d
                where d.client_id = c.id and d.type = 'facture' and d.statut in ('emise', 'partiellement_payee')) as plus_ancienne
        from public.clients c where c.boutique_id = p_boutique and c.supprime_le is null and c.solde > 0) t),
    'fournisseurs', (select coalesce(jsonb_agg(to_jsonb(t) order by t.solde desc), '[]'::jsonb) from (
        select f.id, f.nom_ar, f.nom_fr, f.telephone, f.solde
        from public.fournisseurs f where f.boutique_id = p_boutique and f.supprime_le is null and f.solde > 0) t));
end;
$$;

-- ---------------------------------------------------------------------------
-- Alertes de stock : ruptures, seuils bas, lots périmés ou proches de l'expiration
-- ---------------------------------------------------------------------------
create or replace function prive.alertes_stock(p_boutique uuid, p_jours integer default 30)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_seuil_defaut numeric := coalesce((select (b.parametres ->> 'seuil_stock_defaut')::numeric from public.boutiques b where b.id = p_boutique), 0);
  v_ruptures jsonb;
  v_bas jsonb;
  v_expirations jsonb;
begin
  with a as (
    select v.id as variante_id, s.en_stock, case when v.stock_minimum > 0 then v.stock_minimum else v_seuil_defaut end as seuil
    from public.variantes_produit v
    join (select l.variante_id, sum(l.quantite_restante) as en_stock from public.lots_stock l
          where l.boutique_id = p_boutique group by l.variante_id) s on s.variante_id = v.id
    where v.boutique_id = p_boutique and v.supprime_le is null and v.actif
  )
  select coalesce(jsonb_agg(jsonb_build_object('variante_id', a.variante_id, 'libelle_ar', prive.libelle_variante(a.variante_id, 'ar'),
                                               'libelle_fr', prive.libelle_variante(a.variante_id, 'fr'), 'en_stock', a.en_stock)
                            order by a.en_stock), '[]'::jsonb)
  into v_ruptures from a where a.en_stock <= 0;

  with a as (
    select v.id as variante_id, s.en_stock, case when v.stock_minimum > 0 then v.stock_minimum else v_seuil_defaut end as seuil
    from public.variantes_produit v
    join (select l.variante_id, sum(l.quantite_restante) as en_stock from public.lots_stock l
          where l.boutique_id = p_boutique group by l.variante_id) s on s.variante_id = v.id
    where v.boutique_id = p_boutique and v.supprime_le is null and v.actif
  )
  select coalesce(jsonb_agg(jsonb_build_object('variante_id', a.variante_id, 'libelle_ar', prive.libelle_variante(a.variante_id, 'ar'),
                                               'libelle_fr', prive.libelle_variante(a.variante_id, 'fr'), 'en_stock', a.en_stock, 'seuil', a.seuil)
                            order by a.en_stock), '[]'::jsonb)
  into v_bas from a where a.seuil > 0 and a.en_stock > 0 and a.en_stock <= a.seuil;

  select coalesce(jsonb_agg(jsonb_build_object('lot_id', l.id, 'numero_lot', l.numero_lot, 'variante_id', l.variante_id,
                                               'libelle_ar', prive.libelle_variante(l.variante_id, 'ar'), 'libelle_fr', prive.libelle_variante(l.variante_id, 'fr'),
                                               'quantite', l.quantite_restante, 'date_expiration', l.date_expiration,
                                               'perime', l.date_expiration < current_date)
                            order by l.date_expiration), '[]'::jsonb)
  into v_expirations from public.lots_stock l
  where l.boutique_id = p_boutique and l.quantite_restante > 0 and l.date_expiration is not null
    and l.date_expiration <= current_date + greatest(p_jours, 0);

  return jsonb_build_object('ruptures', v_ruptures, 'seuil_bas', v_bas, 'expirations', v_expirations);
end;
$$;

create or replace function public.alertes_stock(p_boutique uuid, p_jours integer default 30)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform prive.exiger_permission(p_boutique, 'stock.lire');
  return prive.alertes_stock(p_boutique, p_jours);
end;
$$;

-- Tâche quotidienne : une notification de synthèse par boutique et par jour (propriétaire, manager, magasinière).
create or replace function public.generer_alertes_stock()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_boutique record;
  v_alertes jsonb;
  v_nb_rupture integer;
  v_nb_bas integer;
  v_nb_exp integer;
  v_ids uuid[] := '{}';
  v_nouveaux uuid[];
begin
  if not prive.est_service() then
    raise exception 'acces_refuse' using errcode = '42501';
  end if;
  for v_boutique in select b.id from public.boutiques b where b.statut in ('essai', 'actif', 'grace') loop
    if exists (select 1 from public.notifications n where n.boutique_id = v_boutique.id and n.type = 'stock_alerte' and n.cree_le >= date_trunc('day', now())) then
      continue;
    end if;
    v_alertes := prive.alertes_stock(v_boutique.id, 30);
    v_nb_rupture := jsonb_array_length(v_alertes -> 'ruptures');
    v_nb_bas := jsonb_array_length(v_alertes -> 'seuil_bas');
    v_nb_exp := jsonb_array_length(v_alertes -> 'expirations');
    if v_nb_rupture + v_nb_bas + v_nb_exp = 0 then
      continue;
    end if;
    v_nouveaux := prive.notifier_boutique_ids(
      v_boutique.id, 'stock.ecrire', 'stock_alerte', 'تنبيهات المخزون', 'Alertes de stock',
      format('نفاد: %s — منخفض: %s — قرب الانتهاء: %s', v_nb_rupture, v_nb_bas, v_nb_exp),
      format('Ruptures : %s — stock bas : %s — expirations : %s', v_nb_rupture, v_nb_bas, v_nb_exp),
      jsonb_build_object('ruptures', v_nb_rupture, 'seuil_bas', v_nb_bas, 'expirations', v_nb_exp));
    v_ids := v_ids || v_nouveaux;
  end loop;
  return jsonb_build_object('notification_ids', to_jsonb(v_ids), 'nombre', coalesce(array_length(v_ids, 1), 0));
end;
$$;

-- ---------------------------------------------------------------------------
-- Abonnements : expiration → grâce (7 jours, écriture encore possible) → suspension (lecture seule).
-- Rappels au propriétaire à J-7, J-3 et J-1 ; une notification par événement et par jour.
-- ---------------------------------------------------------------------------
create or replace function public.traiter_abonnements()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_abonnement record;
  v_grace integer := 0;
  v_suspendus integer := 0;
  v_rappels integer := 0;
  v_ids uuid[] := '{}';
  v_jours integer;
begin
  if not prive.est_service() then
    raise exception 'acces_refuse' using errcode = '42501';
  end if;

  -- Fin de période non renouvelée → grâce
  for v_abonnement in
    select a.id, a.boutique_id from public.abonnements a
    where a.statut in ('essai', 'actif') and a.fin_le is not null and a.fin_le < current_date for update
  loop
    update public.abonnements set statut = 'grace', grace_jusqu_au = fin_le + 7 where id = v_abonnement.id;
    update public.boutiques set statut = 'grace' where id = v_abonnement.boutique_id and statut in ('essai', 'actif');
    v_ids := v_ids || prive.notifier_boutique_ids(v_abonnement.boutique_id, 'abonnement.voir', 'abonnement',
      'انتهى اشتراكك', 'Abonnement expiré',
      'لديك 7 أيام لتجديد الاشتراك قبل التحويل إلى وضع القراءة فقط.',
      'Vous avez 7 jours pour renouveler avant le passage en lecture seule.',
      jsonb_build_object('evenement', 'grace'));
    v_grace := v_grace + 1;
  end loop;

  -- Fin de grâce → suspension (lecture seule)
  for v_abonnement in
    select a.id, a.boutique_id from public.abonnements a
    where a.statut = 'grace' and a.grace_jusqu_au is not null and a.grace_jusqu_au < current_date for update
  loop
    update public.abonnements set statut = 'suspendu' where id = v_abonnement.id;
    update public.boutiques set statut = 'suspendu' where id = v_abonnement.boutique_id and statut in ('grace', 'actif', 'essai');
    v_ids := v_ids || prive.notifier_boutique_ids(v_abonnement.boutique_id, 'abonnement.voir', 'abonnement',
      'تم إيقاف المتجر', 'Boutique suspendue',
      'تم تحويل متجرك إلى وضع القراءة فقط. تواصل مع الناشر لتجديد الاشتراك.',
      'Votre boutique est en lecture seule. Contactez l''éditeur pour renouveler.',
      jsonb_build_object('evenement', 'suspendu'));
    v_suspendus := v_suspendus + 1;
  end loop;

  -- Rappels d'expiration
  for v_abonnement in
    select a.id, a.boutique_id, (a.fin_le - current_date) as jours from public.abonnements a
    where a.statut in ('essai', 'actif') and a.fin_le is not null and (a.fin_le - current_date) in (7, 3, 1)
  loop
    v_jours := v_abonnement.jours;
    if exists (select 1 from public.notifications n where n.boutique_id = v_abonnement.boutique_id and n.type = 'abonnement'
               and n.donnees ->> 'evenement' = 'rappel' and (n.donnees ->> 'jours')::integer = v_jours and n.cree_le >= date_trunc('day', now())) then
      continue;
    end if;
    v_ids := v_ids || prive.notifier_boutique_ids(v_abonnement.boutique_id, 'abonnement.voir', 'abonnement',
      'اشتراكك على وشك الانتهاء', 'Abonnement bientôt expiré',
      format('ينتهي اشتراكك خلال %s يوم.', v_jours), format('Votre abonnement expire dans %s jour(s).', v_jours),
      jsonb_build_object('evenement', 'rappel', 'jours', v_jours));
    v_rappels := v_rappels + 1;
  end loop;

  return jsonb_build_object('grace', v_grace, 'suspendus', v_suspendus, 'rappels', v_rappels, 'notification_ids', to_jsonb(v_ids));
end;
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'rapport_synthese(uuid, date, date)', 'rapport_ventes(uuid, date, date, text)', 'rapport_produits(uuid, date, date, text, integer)',
    'rapport_stock(uuid)', 'rapport_impayes(uuid)', 'alertes_stock(uuid, integer)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated, service_role', f);
  end loop;
  foreach f in array array['generer_alertes_stock()', 'traiter_abonnements()'] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
    execute format('grant execute on function public.%s to service_role', f);
  end loop;
end;
$$;
