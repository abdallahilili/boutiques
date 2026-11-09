-- =============================================================================
-- Fonctions internes (schéma prive) : contrôle d'accès, numérotation sans trou, lots FIFO/FEFO,
-- réservations, limitation de débit, émission d'un document de vente.
-- Elles ne sont appelées que par les RPC SECURITY DEFINER du schéma public.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Contrôle d'accès des RPC
-- ---------------------------------------------------------------------------
create or replace function prive.exiger_permission(p_boutique uuid, p_cle text)
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or p_boutique is null or not prive.a_permission(p_boutique, p_cle) then
    raise exception 'acces_refuse: permission % requise', p_cle using errcode = '42501';
  end if;
  return auth.uid();
end;
$$;

create or replace function prive.exiger_active(p_boutique uuid)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.boutique_est_active(p_boutique) then
    raise exception 'boutique_inactive: la boutique est en lecture seule' using errcode = 'P0001';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Numérotation : PREFIXE-AAAA-NNNN, sans trou (incrément dans la transaction de l'appelant).
-- ---------------------------------------------------------------------------
create or replace function prive.prefixe_par_defaut(p_type text)
returns text
language sql
immutable
as $$
  select case p_type
    when 'devis' then 'DEV' when 'bon_livraison' then 'BL' when 'facture' then 'FAC' when 'avoir' then 'AV'
    when 'ticket' then 'TIC' when 'lot' then 'LOT' when 'commande' then 'CMD' when 'reception' then 'ENT'
    when 'transfert' then 'TRF' else upper(left(p_type, 3))
  end;
$$;

create or replace function prive.annee_boutique(p_boutique uuid, p_date timestamptz default now())
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select extract(year from (p_date at time zone coalesce(b.fuseau_horaire, 'UTC')))::integer
  from public.boutiques b where b.id = p_boutique;
$$;

create or replace function prive.formater_numero(p_boutique uuid, p_type text, p_annee integer, p_numero integer)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select s.prefixe from public.sequences_documents s
                   where s.boutique_id = p_boutique and s.type_document = p_type and s.annee = p_annee),
                  prive.prefixe_par_defaut(p_type))
         || '-' || p_annee || '-' || lpad(p_numero::text, 4, '0');
$$;

create or replace function prive.prochain_numero(p_boutique uuid, p_type text, p_date timestamptz default now())
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_annee integer := prive.annee_boutique(p_boutique, p_date);
begin
  return prive.formater_numero(p_boutique, p_type, v_annee, prive.prochain_compteur(p_boutique, p_type, v_annee));
end;
$$;

-- ---------------------------------------------------------------------------
-- Prix effectif, libellés
-- ---------------------------------------------------------------------------
create or replace function prive.prix_effectif(v public.variantes_produit, p_instant timestamptz default now())
returns numeric
language sql
immutable
as $$
  select case
    when v.prix_promo is not null
         and (v.promo_debut is null or p_instant >= v.promo_debut)
         and (v.promo_fin is null or p_instant <= v.promo_fin)
    then v.prix_promo else v.prix_vente end;
$$;

-- Libellé « produit - modèle - couleur - taille » dans une langue (repli sur l'autre langue).
create or replace function prive.libelle_variante(p_variante uuid, p_langue text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select concat_ws(' - ',
    case when p_langue = 'ar' then coalesce(p.nom_ar, p.nom_fr) else coalesce(p.nom_fr, p.nom_ar) end,
    case when p_langue = 'ar' then coalesce(m.nom_ar, m.nom_fr) else coalesce(m.nom_fr, m.nom_ar) end,
    case when p_langue = 'ar' then coalesce(c.nom_ar, c.nom_fr) else coalesce(c.nom_fr, c.nom_ar) end,
    case when p_langue = 'ar' then coalesce(t.nom_ar, t.nom_fr) else coalesce(t.nom_fr, t.nom_ar) end)
  from public.variantes_produit v
  join public.produits p on p.id = v.produit_id
  left join public.modeles m on m.id = v.modele_id
  left join public.couleurs c on c.id = v.couleur_id
  left join public.tailles t on t.id = v.taille_id
  where v.id = p_variante;
$$;

-- ---------------------------------------------------------------------------
-- Limitation de débit des RPC publiques
-- ---------------------------------------------------------------------------
create or replace function prive.limiter_debit(p_cle text, p_max integer, p_fenetre interval)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_compteur integer;
begin
  insert into public.limites_debit (cle, compteur, fenetre_debut)
  values (p_cle, 1, now())
  on conflict (cle) do update set
    compteur = case when public.limites_debit.fenetre_debut < now() - p_fenetre then 1 else public.limites_debit.compteur + 1 end,
    fenetre_debut = case when public.limites_debit.fenetre_debut < now() - p_fenetre then now() else public.limites_debit.fenetre_debut end
  returning compteur into v_compteur;
  if v_compteur > p_max then
    raise exception 'trop_de_requetes: réessayez plus tard' using errcode = 'P0001';
  end if;
end;
$$;

-- Adresse IP du visiteur (en-têtes PostgREST) ; null hors requête API.
create or replace function prive.adresse_ip()
returns text
language sql
stable
as $$
  select nullif(trim(split_part(coalesce(nullif(current_setting('request.headers', true), '')::json ->> 'x-forwarded-for', ''), ',', 1)), '');
$$;

-- ---------------------------------------------------------------------------
-- Lots : création (avec absorption d'un éventuel découvert) et consommation FIFO / FEFO
-- ---------------------------------------------------------------------------
create or replace function prive.ajouter_lot(
  p_boutique uuid,
  p_variante uuid,
  p_quantite numeric,
  p_cout numeric,
  p_expiration date,
  p_ligne_reception uuid,
  p_fournisseur uuid,
  p_source_type text,
  p_source_id uuid,
  p_utilisateur uuid,
  p_type public.type_mouvement_stock default 'entree',
  p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lot uuid := gen_random_uuid();
  v_decouvert public.lots_stock;
  v_absorbe numeric := 0;
begin
  -- Verrou de la variante : sérialise réceptions, ventes et ajustements concurrents.
  perform 1 from public.variantes_produit v where v.id = p_variante and v.boutique_id = p_boutique for update;
  if not found then
    raise exception 'variante_introuvable' using errcode = 'P0001';
  end if;

  select * into v_decouvert from public.lots_stock l
  where l.boutique_id = p_boutique and l.variante_id = p_variante and l.decouvert and l.quantite_restante < 0
  for update;
  if found then
    v_absorbe := least(-v_decouvert.quantite_restante, p_quantite);
  end if;

  insert into public.lots_stock (id, boutique_id, variante_id, numero_lot, quantite_initiale, quantite_restante,
                                 cout_unitaire, date_expiration, ligne_reception_id, fournisseur_id)
  values (v_lot, p_boutique, p_variante, prive.prochain_numero(p_boutique, 'lot'), p_quantite, p_quantite - v_absorbe,
          p_cout, p_expiration, p_ligne_reception, p_fournisseur);

  insert into public.mouvements_stock (boutique_id, variante_id, lot_id, type, quantite, cout_unitaire, source_type, source_id, utilisateur_id, note)
  values (p_boutique, p_variante, v_lot, p_type, p_quantite, p_cout, p_source_type, p_source_id, p_utilisateur, p_note);

  if v_absorbe > 0 then
    update public.lots_stock set quantite_restante = quantite_restante + v_absorbe where id = v_decouvert.id;
    insert into public.mouvements_stock (boutique_id, variante_id, lot_id, type, quantite, cout_unitaire, source_type, source_id, utilisateur_id, note)
    values (p_boutique, p_variante, v_decouvert.id, 'ajustement', v_absorbe, v_decouvert.cout_unitaire, 'absorption_decouvert', v_lot, p_utilisateur, null),
           (p_boutique, p_variante, v_lot, 'ajustement', -v_absorbe, p_cout, 'absorption_decouvert', v_decouvert.id, p_utilisateur, null);
  end if;
  return v_lot;
end;
$$;

-- Quantité réservée (commandes en ligne non encore consommées) d'une variante.
create or replace function prive.quantite_reservee(p_boutique uuid, p_variante uuid)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(sum(m.quantite), 0) from public.mouvements_stock m
  where m.boutique_id = p_boutique and m.variante_id = p_variante and m.type in ('reservation', 'liberation');
$$;

-- Consomme p_quantite d'une variante : lots expirant le plus tôt d'abord (FEFO), puis les plus anciens (FIFO).
-- Retourne le coût unitaire moyen pondéré (figé sur la ligne de vente).
-- Stock insuffisant : exception, sauf si la boutique autorise le stock négatif (lot « découvert »).
create or replace function prive.consommer_stock(
  p_boutique uuid,
  p_variante uuid,
  p_quantite numeric,
  p_type public.type_mouvement_stock,
  p_source_type text,
  p_source_id uuid,
  p_utilisateur uuid,
  p_motif uuid default null,
  p_note text default null,
  p_respecter_reservation boolean default true
)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v_lot record;
  v_restant numeric := p_quantite;
  v_pris numeric;
  v_cout_total numeric := 0;
  v_negatif boolean := coalesce((select (b.parametres ->> 'stock_negatif_autorise')::boolean from public.boutiques b where b.id = p_boutique), false);
  v_disponible numeric;
  v_cout_decouvert numeric;
  v_lot_decouvert uuid;
begin
  if p_quantite <= 0 then
    raise exception 'quantite_invalide' using errcode = 'P0001';
  end if;
  perform 1 from public.variantes_produit v where v.id = p_variante and v.boutique_id = p_boutique for update;
  if not found then
    raise exception 'variante_introuvable' using errcode = 'P0001';
  end if;

  select coalesce(sum(l.quantite_restante), 0) into v_disponible
  from public.lots_stock l where l.boutique_id = p_boutique and l.variante_id = p_variante;
  if p_respecter_reservation then
    v_disponible := v_disponible - prive.quantite_reservee(p_boutique, p_variante);
  end if;
  if v_disponible < p_quantite and not v_negatif then
    raise exception 'stock_insuffisant: variante % (disponible %, demandé %)', p_variante, v_disponible, p_quantite
      using errcode = 'P0001';
  end if;

  for v_lot in
    select l.id, l.quantite_restante, l.cout_unitaire
    from public.lots_stock l
    where l.boutique_id = p_boutique and l.variante_id = p_variante and l.quantite_restante > 0 and not l.decouvert
    order by l.date_expiration nulls last, l.recu_le, l.numero_lot
    for update
  loop
    exit when v_restant <= 0;
    v_pris := least(v_lot.quantite_restante, v_restant);
    update public.lots_stock set quantite_restante = quantite_restante - v_pris where id = v_lot.id;
    insert into public.mouvements_stock (boutique_id, variante_id, lot_id, type, quantite, cout_unitaire, source_type, source_id, motif_id, note, utilisateur_id)
    values (p_boutique, p_variante, v_lot.id, p_type, -v_pris, v_lot.cout_unitaire, p_source_type, p_source_id, p_motif, p_note, p_utilisateur);
    v_cout_total := v_cout_total + v_pris * v_lot.cout_unitaire;
    v_restant := v_restant - v_pris;
  end loop;

  if v_restant > 0 then
    -- Stock négatif autorisé : le manque est porté par un lot « découvert » (coût = dernier coût connu).
    select coalesce((select l.cout_unitaire from public.lots_stock l
                     where l.boutique_id = p_boutique and l.variante_id = p_variante and not l.decouvert
                     order by l.recu_le desc limit 1), 0)
    into v_cout_decouvert;
    select l.id into v_lot_decouvert from public.lots_stock l
    where l.boutique_id = p_boutique and l.variante_id = p_variante and l.decouvert for update;
    if v_lot_decouvert is null then
      insert into public.lots_stock (boutique_id, variante_id, numero_lot, quantite_initiale, quantite_restante, cout_unitaire, decouvert)
      values (p_boutique, p_variante, 'DEC-' || p_variante, 0, 0, v_cout_decouvert, true)
      returning id into v_lot_decouvert;
    end if;
    update public.lots_stock set quantite_restante = quantite_restante - v_restant where id = v_lot_decouvert;
    insert into public.mouvements_stock (boutique_id, variante_id, lot_id, type, quantite, cout_unitaire, source_type, source_id, motif_id, note, utilisateur_id)
    values (p_boutique, p_variante, v_lot_decouvert, p_type, -v_restant, v_cout_decouvert, p_source_type, p_source_id, p_motif, p_note, p_utilisateur);
    v_cout_total := v_cout_total + v_restant * v_cout_decouvert;
  end if;

  return round(v_cout_total / p_quantite, 4);
end;
$$;

-- ---------------------------------------------------------------------------
-- Émission d'un document de vente (facture ou ticket) : lignes, stock FIFO, paiements, solde client.
-- p_lignes : [{ id, variante_id?, libelle_ar, libelle_fr, quantite, prix_unitaire, remise }]
--            (variante_id absent = ligne de service, sans stock : ex. frais de livraison)
-- p_paiements : [{ id?, mode_paiement_id, montant, reference? }]
-- ---------------------------------------------------------------------------
create or replace function prive.emettre_document(
  p_boutique uuid,
  p_utilisateur uuid,
  p_id uuid,
  p_type public.type_document_vente,
  p_client uuid,
  p_canal public.canal_vente,
  p_session uuid,
  p_numero text,
  p_remise numeric,
  p_notes text,
  p_lignes jsonb,
  p_paiements jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ligne record;
  v_paiement record;
  v_boutique public.boutiques;
  v_client public.clients;
  v_sous_total numeric := 0;
  v_total numeric;
  v_paye numeric := 0;
  v_reste numeric;
  v_statut public.statut_document_vente;
  v_numero text;
  v_cout numeric;
  v_entete jsonb;
  v_type_mode public.type_mode_paiement;
  v_total_ligne numeric;
begin
  select * into v_boutique from public.boutiques where id = p_boutique;
  if p_client is not null then
    select * into v_client from public.clients where id = p_client and boutique_id = p_boutique and supprime_le is null;
    if not found then
      raise exception 'client_introuvable' using errcode = 'P0001';
    end if;
  end if;
  if p_session is not null and not exists (
    select 1 from public.sessions_caisse s
    where s.id = p_session and s.boutique_id = p_boutique and s.utilisateur_id = p_utilisateur and s.fermee_le is null
  ) then
    raise exception 'session_caisse_invalide' using errcode = 'P0001';
  end if;

  -- Totaux calculés par le serveur à partir des quantités, prix et remises de chaque ligne.
  for v_ligne in
    select (l.quantite * l.prix_unitaire - coalesce(l.remise, 0)) as net, l.quantite, l.prix_unitaire, coalesce(l.remise, 0) as remise
    from jsonb_to_recordset(p_lignes) as l(quantite numeric, prix_unitaire numeric, remise numeric)
  loop
    if v_ligne.quantite is null or v_ligne.prix_unitaire is null
       or v_ligne.quantite <= 0 or v_ligne.prix_unitaire < 0 or v_ligne.remise < 0 or v_ligne.net < 0 then
      raise exception 'ligne_invalide' using errcode = 'P0001';
    end if;
    v_sous_total := v_sous_total + round(v_ligne.net, 2);
  end loop;
  if p_remise < 0 or p_remise > v_sous_total then
    raise exception 'remise_invalide' using errcode = 'P0001';
  end if;
  v_total := v_sous_total - p_remise;

  -- Paiements : crédit = non payé ; somme limitée au total ; reste à crédit réservé aux clientes identifiées.
  for v_paiement in
    select pm.montant, pm.mode_paiement_id
    from jsonb_to_recordset(p_paiements) as pm(montant numeric, mode_paiement_id uuid)
  loop
    select m.type into v_type_mode from public.modes_paiement m
    where m.id = v_paiement.mode_paiement_id and m.boutique_id = p_boutique and m.actif;
    if v_type_mode is null then
      raise exception 'mode_paiement_invalide' using errcode = 'P0001';
    end if;
    if v_paiement.montant <= 0 then
      raise exception 'montant_paiement_invalide' using errcode = 'P0001';
    end if;
    if v_type_mode <> 'credit' then
      v_paye := v_paye + v_paiement.montant;
    end if;
  end loop;
  if v_paye > v_total then
    raise exception 'paiement_excessif: payé % pour un total de %', v_paye, v_total using errcode = 'P0001';
  end if;
  v_reste := v_total - v_paye;
  if v_reste > 0 then
    if p_type = 'ticket' then
      raise exception 'paiement_incomplet: un ticket doit être payé en totalité' using errcode = 'P0001';
    end if;
    if p_client is null then
      raise exception 'client_requis: le crédit exige une cliente identifiée' using errcode = 'P0001';
    end if;
    if v_client.plafond_credit is not null and v_client.solde + v_reste > v_client.plafond_credit then
      raise exception 'plafond_credit_depasse: plafond % (solde % + %)', v_client.plafond_credit, v_client.solde, v_reste
        using errcode = 'P0001';
    end if;
  end if;
  v_statut := case when v_reste = 0 then 'payee' when v_paye > 0 then 'partiellement_payee' else 'emise' end;

  v_numero := coalesce(p_numero, prive.prochain_numero(p_boutique, p_type::text));
  v_entete := jsonb_build_object(
    'nom_ar', v_boutique.nom_ar, 'nom_fr', v_boutique.nom_fr, 'logo_url', v_boutique.logo_url,
    'adresse', v_boutique.adresse, 'ville', v_boutique.ville, 'telephone', v_boutique.telephone,
    'whatsapp', v_boutique.whatsapp, 'devise', v_boutique.devise,
    'pied_page_ar', v_boutique.parametres ->> 'pied_page_ar', 'pied_page_fr', v_boutique.parametres ->> 'pied_page_fr',
    'conditions_ar', v_boutique.parametres ->> 'conditions_ar', 'conditions_fr', v_boutique.parametres ->> 'conditions_fr',
    'client', case when p_client is null then null else jsonb_build_object(
      'nom_ar', v_client.nom_ar, 'nom_fr', v_client.nom_fr, 'telephone', v_client.telephone, 'adresse', v_client.adresse) end,
    'vendeuse', (select coalesce(p.nom_ar, p.nom_fr) from public.profils p where p.id = p_utilisateur)
  );

  insert into public.documents_vente (id, boutique_id, type, numero, statut, client_id, session_caisse_id, canal,
                                      sous_total, remise, total, paye, notes, entete, utilisateur_id)
  values (p_id, p_boutique, p_type, v_numero, v_statut, p_client, p_session, p_canal,
          v_sous_total, p_remise, v_total, v_paye, p_notes, v_entete, p_utilisateur);

  -- Lignes : verrous pris dans l'ordre des variantes (pas d'interblocage entre ventes concurrentes).
  for v_ligne in
    select (e.elem ->> 'id')::uuid as id, (e.elem ->> 'variante_id')::uuid as variante_id,
           e.elem ->> 'libelle_ar' as libelle_ar, e.elem ->> 'libelle_fr' as libelle_fr,
           (e.elem ->> 'quantite')::numeric as quantite, (e.elem ->> 'prix_unitaire')::numeric as prix_unitaire,
           coalesce((e.elem ->> 'remise')::numeric, 0) as remise, e.ord::integer as ordre
    from jsonb_array_elements(p_lignes) with ordinality as e(elem, ord)
    order by variante_id nulls last, e.ord
  loop
    v_cout := 0;
    if v_ligne.variante_id is not null then
      v_cout := prive.consommer_stock(p_boutique, v_ligne.variante_id, v_ligne.quantite, 'sortie_vente', 'document_vente', p_id, p_utilisateur);
    end if;
    v_total_ligne := round(v_ligne.quantite * v_ligne.prix_unitaire - v_ligne.remise, 2);
    insert into public.lignes_document_vente (id, boutique_id, document_id, variante_id, libelle_ar, libelle_fr,
                                              quantite, prix_unitaire, remise, cout_unitaire, total, ordre)
    values (coalesce(v_ligne.id, gen_random_uuid()), p_boutique, p_id, v_ligne.variante_id, v_ligne.libelle_ar, v_ligne.libelle_fr,
            v_ligne.quantite, v_ligne.prix_unitaire, v_ligne.remise, v_cout, v_total_ligne, v_ligne.ordre);
  end loop;

  for v_paiement in
    select coalesce(pm.id, gen_random_uuid()) as id, pm.mode_paiement_id, pm.montant, pm.reference
    from jsonb_to_recordset(p_paiements) as pm(id uuid, mode_paiement_id uuid, montant numeric, reference text)
    where (select m.type from public.modes_paiement m where m.id = pm.mode_paiement_id) <> 'credit'
  loop
    insert into public.paiements (id, boutique_id, document_id, client_id, mode_paiement_id, montant, session_caisse_id, reference, utilisateur_id)
    values (v_paiement.id, p_boutique, p_id, p_client, v_paiement.mode_paiement_id, v_paiement.montant, p_session, v_paiement.reference, p_utilisateur);
  end loop;

  if p_client is not null and v_reste > 0 then
    update public.clients set solde = solde + v_reste where id = p_client;
  end if;

  return jsonb_build_object('id', p_id, 'numero', v_numero, 'statut', v_statut, 'total', v_total, 'paye', v_paye, 'reste', v_reste, 'rejoue', false);
end;
$$;

-- Résumé d'un document déjà enregistré (rejeu idempotent).
create or replace function prive.resume_document(p_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object('id', d.id, 'numero', d.numero, 'statut', d.statut, 'total', d.total, 'paye', d.paye, 'reste', d.reste, 'rejoue', true)
  from public.documents_vente d where d.id = p_id;
$$;
