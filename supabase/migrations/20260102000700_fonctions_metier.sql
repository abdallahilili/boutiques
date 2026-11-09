-- =============================================================================
-- RPC métier (schéma public) : numérotation, vente, réception, ajustement, paiement, caisse.
-- Toutes sont transactionnelles et idempotentes (UUID générés côté appareil), contrôlent
-- l'appartenance, la permission et l'état de la boutique.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Numérotation
-- ---------------------------------------------------------------------------
create or replace function public.attribuer_numero_document(p_boutique_id uuid, p_type text)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
  perform prive.exiger_permission(p_boutique_id, 'documents.creer');
  perform prive.exiger_active(p_boutique_id);
  if p_type not in ('devis', 'bon_livraison', 'facture', 'avoir', 'ticket') then
    raise exception 'type_invalide' using errcode = 'P0001';
  end if;
  return prive.prochain_numero(p_boutique_id, p_type);
end;
$$;

-- Réserve une plage de numéros pour un appareil (ventes hors ligne). Les numéros non utilisés
-- restent à l'appareil ; une nouvelle plage n'est accordée que si moins de 25 numéros sont en réserve.
create or replace function public.reserver_plage_numeros(
  p_boutique_id uuid,
  p_type text,
  p_appareil_id uuid,
  p_taille integer default 20
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_utilisateur uuid := prive.exiger_permission(p_boutique_id, 'pos.vendre');
  v_annee integer;
  v_debut integer;
  v_non_utilises integer;
begin
  perform prive.exiger_active(p_boutique_id);
  if p_type not in ('facture', 'ticket') or p_taille not between 1 and 50 then
    raise exception 'parametres_invalides' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.appareils a where a.id = p_appareil_id and a.utilisateur_id = v_utilisateur) then
    raise exception 'appareil_invalide' using errcode = 'P0001';
  end if;
  v_annee := prive.annee_boutique(p_boutique_id);

  select coalesce(sum(pl.fin - pl.debut + 1 - (
    select count(*) from public.documents_vente d
    where d.boutique_id = pl.boutique_id and d.type::text = pl.type_document
      and d.numero like '%-' || pl.annee || '-%'
      and substring(d.numero from '[0-9]+$')::integer between pl.debut and pl.fin
  )), 0) into v_non_utilises
  from public.plages_numeros pl
  where pl.boutique_id = p_boutique_id and pl.appareil_id = p_appareil_id and pl.type_document = p_type and pl.annee = v_annee;
  if v_non_utilises >= 25 then
    raise exception 'plage_non_epuisee: % numéros encore en réserve', v_non_utilises using errcode = 'P0001';
  end if;

  insert into public.sequences_documents (boutique_id, type_document, annee)
  values (p_boutique_id, p_type, v_annee)
  on conflict do nothing;
  update public.sequences_documents
  set prochain_numero = prochain_numero + p_taille
  where boutique_id = p_boutique_id and type_document = p_type and annee = v_annee
  returning prochain_numero - p_taille into v_debut;

  insert into public.plages_numeros (boutique_id, type_document, annee, appareil_id, debut, fin)
  values (p_boutique_id, p_type, v_annee, p_appareil_id, v_debut, v_debut + p_taille - 1);

  return jsonb_build_object(
    'type', p_type, 'annee', v_annee, 'debut', v_debut, 'fin', v_debut + p_taille - 1,
    'prefixe', split_part(prive.formater_numero(p_boutique_id, p_type, v_annee, v_debut), '-', 1)
  );
end;
$$;

-- Vérifie qu'un numéro précalculé appartient à une plage réservée par l'appareil de l'appelante.
create or replace function prive.verifier_numero_plage(
  p_boutique uuid, p_type text, p_numero text, p_appareil uuid, p_utilisateur uuid
)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_m text[] := regexp_match(p_numero, '^([A-Z0-9]+)-([0-9]{4})-([0-9]+)$');
begin
  if v_m is null
     or p_appareil is null
     or not exists (
       select 1 from public.plages_numeros pl join public.appareils a on a.id = pl.appareil_id
       where pl.boutique_id = p_boutique and pl.type_document = p_type and pl.annee = v_m[2]::integer
         and pl.appareil_id = p_appareil and a.utilisateur_id = p_utilisateur
         and v_m[3]::integer between pl.debut and pl.fin
     )
     or p_numero <> prive.formater_numero(p_boutique, p_type, v_m[2]::integer, v_m[3]::integer) then
    raise exception 'numero_invalide: numéro hors plage réservée' using errcode = 'P0001';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Vente (POS) : ticket ou facture, paiements multiples, stock FIFO, coût figé.
-- donnees : { id, boutique_id, type?, client_id?, canal?, session_caisse_id?, appareil_id?, numero?,
--             remise?, notes?, lignes: [{ id?, variante_id, quantite, prix_unitaire?, remise? }],
--             paiements: [{ id?, mode_paiement_id, montant, reference? }] }
-- ---------------------------------------------------------------------------
create or replace function public.enregistrer_vente(p_donnees jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_boutique uuid := (p_donnees ->> 'boutique_id')::uuid;
  v_id uuid := (p_donnees ->> 'id')::uuid;
  v_utilisateur uuid;
  v_type public.type_document_vente := coalesce(nullif(p_donnees ->> 'type', ''), 'facture')::public.type_document_vente;
  v_numero text := nullif(p_donnees ->> 'numero', '');
  v_remise numeric := coalesce((p_donnees ->> 'remise')::numeric, 0);
  v_lignes jsonb := '[]'::jsonb;
  v_element record;
  v_variante public.variantes_produit;
  v_prix numeric;
  v_remise_ligne numeric;
begin
  v_utilisateur := prive.exiger_permission(v_boutique, 'pos.vendre');
  if v_id is null then
    raise exception 'identifiant_requis' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.documents_vente d where d.id = v_id) then
    if not exists (select 1 from public.documents_vente d where d.id = v_id and d.boutique_id = v_boutique) then
      raise exception 'acces_refuse' using errcode = '42501';
    end if;
    return prive.resume_document(v_id);
  end if;

  perform prive.exiger_active(v_boutique);
  if v_type not in ('facture', 'ticket') then
    raise exception 'type_invalide: la caisse émet une facture ou un ticket' using errcode = 'P0001';
  end if;
  if jsonb_typeof(p_donnees -> 'lignes') is distinct from 'array'
     or jsonb_array_length(p_donnees -> 'lignes') not between 1 and 200 then
    raise exception 'lignes_invalides' using errcode = 'P0001';
  end if;
  if jsonb_typeof(coalesce(p_donnees -> 'paiements', '[]'::jsonb)) is distinct from 'array' then
    raise exception 'paiements_invalides' using errcode = 'P0001';
  end if;

  for v_element in select e.elem, e.ord from jsonb_array_elements(p_donnees -> 'lignes') with ordinality as e(elem, ord) loop
    select * into v_variante from public.variantes_produit v
    where v.id = (v_element.elem ->> 'variante_id')::uuid and v.boutique_id = v_boutique and v.supprime_le is null and v.actif;
    if not found then
      raise exception 'variante_introuvable' using errcode = 'P0001';
    end if;
    v_prix := coalesce((v_element.elem ->> 'prix_unitaire')::numeric, prive.prix_effectif(v_variante));
    if v_prix <> prive.prix_effectif(v_variante) and not prive.a_permission(v_boutique, 'pos.modifier_prix') then
      raise exception 'acces_refuse: permission pos.modifier_prix requise' using errcode = '42501';
    end if;
    v_remise_ligne := coalesce((v_element.elem ->> 'remise')::numeric, 0);
    if v_remise_ligne > 0 and not prive.a_permission(v_boutique, 'pos.remise') then
      raise exception 'acces_refuse: permission pos.remise requise' using errcode = '42501';
    end if;
    v_lignes := v_lignes || jsonb_build_object(
      'id', v_element.elem ->> 'id', 'variante_id', v_variante.id,
      'libelle_ar', prive.libelle_variante(v_variante.id, 'ar'), 'libelle_fr', prive.libelle_variante(v_variante.id, 'fr'),
      'quantite', (v_element.elem ->> 'quantite')::numeric, 'prix_unitaire', v_prix, 'remise', v_remise_ligne);
  end loop;
  if v_remise > 0 and not prive.a_permission(v_boutique, 'pos.remise') then
    raise exception 'acces_refuse: permission pos.remise requise' using errcode = '42501';
  end if;
  if v_numero is not null then
    perform prive.verifier_numero_plage(v_boutique, v_type::text, v_numero, (p_donnees ->> 'appareil_id')::uuid, v_utilisateur);
  end if;

  return prive.emettre_document(
    v_boutique, v_utilisateur, v_id, v_type,
    nullif(p_donnees ->> 'client_id', '')::uuid,
    coalesce(nullif(p_donnees ->> 'canal', ''), 'caisse')::public.canal_vente,
    nullif(p_donnees ->> 'session_caisse_id', '')::uuid,
    v_numero, v_remise, nullif(p_donnees ->> 'notes', ''), v_lignes, coalesce(p_donnees -> 'paiements', '[]'::jsonb)
  );
exception
  when unique_violation then
    -- Deux envois simultanés du même UUID : le second renvoie le document déjà enregistré.
    if exists (select 1 from public.documents_vente d where d.id = v_id and d.boutique_id = v_boutique) then
      return prive.resume_document(v_id);
    end if;
    raise;
end;
$$;

-- ---------------------------------------------------------------------------
-- Règlement d'une facture (paiement partiel puis solde)
-- donnees : { id, document_id, mode_paiement_id, montant, reference?, session_caisse_id? }
-- ---------------------------------------------------------------------------
create or replace function public.enregistrer_paiement(p_donnees jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid := (p_donnees ->> 'id')::uuid;
  v_document public.documents_vente;
  v_boutique uuid;
  v_utilisateur uuid;
  v_montant numeric := (p_donnees ->> 'montant')::numeric;
  v_type_mode public.type_mode_paiement;
  v_paye numeric;
  v_statut public.statut_document_vente;
  v_session uuid := nullif(p_donnees ->> 'session_caisse_id', '')::uuid;
begin
  select d.boutique_id into v_boutique from public.documents_vente d where d.id = (p_donnees ->> 'document_id')::uuid;
  if v_boutique is null then
    raise exception 'document_introuvable' using errcode = 'P0001';
  end if;
  v_utilisateur := prive.exiger_permission(v_boutique, 'documents.creer');
  if v_id is null or v_montant is null or v_montant <= 0 then
    raise exception 'parametres_invalides' using errcode = 'P0001';
  end if;

  select * into v_document from public.documents_vente d where d.id = (p_donnees ->> 'document_id')::uuid for update;
  if exists (select 1 from public.paiements p where p.id = v_id and p.boutique_id = v_boutique) then
    return jsonb_build_object('document_id', v_document.id, 'statut', v_document.statut, 'paye', v_document.paye, 'reste', v_document.reste, 'rejoue', true);
  end if;

  perform prive.exiger_active(v_boutique);
  if v_document.type not in ('facture', 'ticket') or v_document.statut in ('annulee', 'brouillon') then
    raise exception 'document_non_payable' using errcode = 'P0001';
  end if;
  if v_montant > v_document.reste then
    raise exception 'paiement_excessif: reste à payer %', v_document.reste using errcode = 'P0001';
  end if;
  select m.type into v_type_mode from public.modes_paiement m
  where m.id = (p_donnees ->> 'mode_paiement_id')::uuid and m.boutique_id = v_boutique and m.actif;
  if v_type_mode is null or v_type_mode = 'credit' then
    raise exception 'mode_paiement_invalide' using errcode = 'P0001';
  end if;
  if v_session is not null and not exists (
    select 1 from public.sessions_caisse s
    where s.id = v_session and s.boutique_id = v_boutique and s.utilisateur_id = v_utilisateur and s.fermee_le is null
  ) then
    raise exception 'session_caisse_invalide' using errcode = 'P0001';
  end if;

  insert into public.paiements (id, boutique_id, document_id, client_id, mode_paiement_id, montant, session_caisse_id, reference, utilisateur_id)
  values (v_id, v_boutique, v_document.id, v_document.client_id, (p_donnees ->> 'mode_paiement_id')::uuid, v_montant, v_session,
          nullif(p_donnees ->> 'reference', ''), v_utilisateur);

  v_paye := v_document.paye + v_montant;
  v_statut := case when v_paye >= v_document.total then 'payee' else 'partiellement_payee' end;
  update public.documents_vente set paye = v_paye, statut = v_statut where id = v_document.id;
  if v_document.client_id is not null then
    update public.clients set solde = solde - v_montant where id = v_document.client_id;
  end if;
  update public.commandes
  set montant_paye = v_paye,
      statut_paiement = (case when v_paye >= total then 'paye' else 'partiel' end)::public.statut_paiement_commande
  where boutique_id = v_boutique and document_id = v_document.id;

  return jsonb_build_object('document_id', v_document.id, 'statut', v_statut, 'paye', v_paye, 'reste', v_document.total - v_paye, 'rejoue', false);
end;
$$;

-- ---------------------------------------------------------------------------
-- Réception de stock (bon d'entrée) : un lot par ligne, numéro LOT-AAAA-NNNN.
-- donnees : { id, boutique_id, fournisseur_id?, date_reception?, reference?, notes?, montant_paye?,
--             lignes: [{ id?, variante_id, quantite, cout_unitaire, date_expiration?, prix_vente? }] }
-- ---------------------------------------------------------------------------
create or replace function public.recevoir_stock(p_donnees jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_boutique uuid := (p_donnees ->> 'boutique_id')::uuid;
  v_id uuid := (p_donnees ->> 'id')::uuid;
  v_utilisateur uuid;
  v_fournisseur uuid := nullif(p_donnees ->> 'fournisseur_id', '')::uuid;
  v_paye numeric := coalesce((p_donnees ->> 'montant_paye')::numeric, 0);
  v_total numeric := 0;
  v_ligne record;
  v_ligne_id uuid;
  v_lot uuid;
  v_lots uuid[] := '{}';
begin
  v_utilisateur := prive.exiger_permission(v_boutique, 'stock.ecrire');
  if v_id is null then
    raise exception 'identifiant_requis' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.receptions_stock r where r.id = v_id) then
    if not exists (select 1 from public.receptions_stock r where r.id = v_id and r.boutique_id = v_boutique) then
      raise exception 'acces_refuse' using errcode = '42501';
    end if;
    return jsonb_build_object('id', v_id, 'rejoue', true);
  end if;

  perform prive.exiger_active(v_boutique);
  if jsonb_typeof(p_donnees -> 'lignes') is distinct from 'array'
     or jsonb_array_length(p_donnees -> 'lignes') not between 1 and 200 then
    raise exception 'lignes_invalides' using errcode = 'P0001';
  end if;
  if v_fournisseur is not null and not exists (
    select 1 from public.fournisseurs f where f.id = v_fournisseur and f.boutique_id = v_boutique and f.supprime_le is null
  ) then
    raise exception 'fournisseur_introuvable' using errcode = 'P0001';
  end if;

  for v_ligne in
    select (l.quantite * l.cout_unitaire) as montant, l.quantite, l.cout_unitaire, l.prix_vente
    from jsonb_to_recordset(p_donnees -> 'lignes') as l(quantite numeric, cout_unitaire numeric, prix_vente numeric)
  loop
    if v_ligne.quantite is null or v_ligne.cout_unitaire is null or v_ligne.quantite <= 0 or v_ligne.cout_unitaire < 0 then
      raise exception 'ligne_invalide' using errcode = 'P0001';
    end if;
    if v_ligne.prix_vente is not null and not prive.a_permission(v_boutique, 'produits.ecrire') then
      raise exception 'acces_refuse: permission produits.ecrire requise pour fixer un prix de vente' using errcode = '42501';
    end if;
    v_total := v_total + v_ligne.montant;
  end loop;
  v_total := round(v_total, 2);
  if v_paye > v_total then
    raise exception 'paiement_excessif' using errcode = 'P0001';
  end if;

  insert into public.receptions_stock (id, boutique_id, fournisseur_id, date_reception, reference, total, montant_paye, notes, utilisateur_id)
  values (v_id, v_boutique, v_fournisseur, coalesce((p_donnees ->> 'date_reception')::timestamptz, now()),
          nullif(p_donnees ->> 'reference', ''), v_total, v_paye, nullif(p_donnees ->> 'notes', ''), v_utilisateur);

  for v_ligne in
    select coalesce((e.elem ->> 'id')::uuid, gen_random_uuid()) as id,
           (e.elem ->> 'variante_id')::uuid as variante_id,
           (e.elem ->> 'quantite')::numeric as quantite,
           (e.elem ->> 'cout_unitaire')::numeric as cout_unitaire,
           (e.elem ->> 'date_expiration')::date as date_expiration,
           (e.elem ->> 'prix_vente')::numeric as prix_vente
    from jsonb_array_elements(p_donnees -> 'lignes') as e(elem)
    order by variante_id
  loop
    if not exists (select 1 from public.variantes_produit v where v.id = v_ligne.variante_id and v.boutique_id = v_boutique and v.supprime_le is null) then
      raise exception 'variante_introuvable' using errcode = 'P0001';
    end if;
    v_ligne_id := v_ligne.id;
    insert into public.lignes_reception_stock (id, boutique_id, reception_id, variante_id, quantite, cout_unitaire, date_expiration, prix_vente)
    values (v_ligne_id, v_boutique, v_id, v_ligne.variante_id, v_ligne.quantite, v_ligne.cout_unitaire, v_ligne.date_expiration, v_ligne.prix_vente);

    v_lot := prive.ajouter_lot(v_boutique, v_ligne.variante_id, v_ligne.quantite, v_ligne.cout_unitaire, v_ligne.date_expiration,
                               v_ligne_id, v_fournisseur, 'reception_stock', v_id, v_utilisateur);
    v_lots := v_lots || v_lot;

    if v_ligne.prix_vente is not null then
      update public.variantes_produit set prix_vente = v_ligne.prix_vente,
             prix_promo = case when prix_promo > v_ligne.prix_vente then null else prix_promo end
      where id = v_ligne.variante_id;
    end if;
  end loop;

  if v_fournisseur is not null and v_total - v_paye > 0 then
    update public.fournisseurs set solde = solde + (v_total - v_paye) where id = v_fournisseur;
  end if;

  return jsonb_build_object('id', v_id, 'total', v_total, 'lots', to_jsonb(v_lots), 'rejoue', false);
end;
$$;

-- ---------------------------------------------------------------------------
-- Ajustement de stock : sortie manuelle (motif obligatoire), retour fournisseur, inventaire.
-- donnees : { id, boutique_id, type, motif_id?, note?,
--             lignes: [{ id?, variante_id, quantite }]            -- sortie_manuelle / retour_fournisseur
--             lignes: [{ id?, variante_id, quantite_comptee }] }  -- inventaire
-- ---------------------------------------------------------------------------
create or replace function public.ajuster_stock(p_donnees jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_boutique uuid := (p_donnees ->> 'boutique_id')::uuid;
  v_id uuid := (p_donnees ->> 'id')::uuid;
  v_utilisateur uuid;
  v_type public.type_ajustement_stock := (p_donnees ->> 'type')::public.type_ajustement_stock;
  v_motif uuid := nullif(p_donnees ->> 'motif_id', '')::uuid;
  v_note text := nullif(p_donnees ->> 'note', '');
  v_ligne record;
  v_systeme numeric;
  v_ecart numeric;
  v_cout numeric;
  v_nb integer := 0;
begin
  v_utilisateur := prive.exiger_permission(v_boutique, 'stock.ecrire');
  if v_id is null or v_type is null then
    raise exception 'parametres_invalides' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.ajustements_stock a where a.id = v_id) then
    if not exists (select 1 from public.ajustements_stock a where a.id = v_id and a.boutique_id = v_boutique) then
      raise exception 'acces_refuse' using errcode = '42501';
    end if;
    return jsonb_build_object('id', v_id, 'rejoue', true);
  end if;

  perform prive.exiger_active(v_boutique);
  if jsonb_typeof(p_donnees -> 'lignes') is distinct from 'array'
     or jsonb_array_length(p_donnees -> 'lignes') not between 1 and 500 then
    raise exception 'lignes_invalides' using errcode = 'P0001';
  end if;
  if v_type = 'inventaire' then
    select m.id into v_motif from public.motifs_mouvement m where m.boutique_id = v_boutique and m.code = 'inventaire';
  elsif v_motif is null then
    raise exception 'motif_obligatoire: une sortie de stock exige un motif' using errcode = 'P0001';
  end if;
  if v_motif is not null and not exists (select 1 from public.motifs_mouvement m where m.id = v_motif and m.boutique_id = v_boutique) then
    raise exception 'motif_introuvable' using errcode = 'P0001';
  end if;

  insert into public.ajustements_stock (id, boutique_id, type, motif_id, note, utilisateur_id)
  values (v_id, v_boutique, v_type, v_motif, v_note, v_utilisateur);

  for v_ligne in
    select coalesce((e.elem ->> 'id')::uuid, gen_random_uuid()) as id,
           (e.elem ->> 'variante_id')::uuid as variante_id,
           (e.elem ->> 'quantite')::numeric as quantite,
           (e.elem ->> 'quantite_comptee')::numeric as quantite_comptee
    from jsonb_array_elements(p_donnees -> 'lignes') as e(elem)
    order by variante_id
  loop
    if not exists (select 1 from public.variantes_produit v where v.id = v_ligne.variante_id and v.boutique_id = v_boutique) then
      raise exception 'variante_introuvable' using errcode = 'P0001';
    end if;
    -- Verrou de la variante puis lecture du stock physique (somme des lots).
    perform 1 from public.variantes_produit v where v.id = v_ligne.variante_id for update;
    select coalesce(sum(l.quantite_restante), 0) into v_systeme
    from public.lots_stock l where l.boutique_id = v_boutique and l.variante_id = v_ligne.variante_id;

    if v_type = 'inventaire' then
      if v_ligne.quantite_comptee is null or v_ligne.quantite_comptee < 0 then
        raise exception 'ligne_invalide' using errcode = 'P0001';
      end if;
      v_ecart := v_ligne.quantite_comptee - v_systeme;
      if v_ecart < 0 then
        perform prive.consommer_stock(v_boutique, v_ligne.variante_id, -v_ecart, 'ajustement', 'ajustement_stock', v_id, v_utilisateur, v_motif, v_note, false);
      elsif v_ecart > 0 then
        select coalesce((select l.cout_unitaire from public.lots_stock l
                         where l.boutique_id = v_boutique and l.variante_id = v_ligne.variante_id and not l.decouvert
                         order by l.recu_le desc limit 1), 0) into v_cout;
        perform prive.ajouter_lot(v_boutique, v_ligne.variante_id, v_ecart, v_cout, null, null, null, 'ajustement_stock', v_id, v_utilisateur, 'ajustement', v_note);
      end if;
    else
      if v_ligne.quantite is null or v_ligne.quantite <= 0 then
        raise exception 'ligne_invalide' using errcode = 'P0001';
      end if;
      v_ecart := -v_ligne.quantite;
      perform prive.consommer_stock(
        v_boutique, v_ligne.variante_id, v_ligne.quantite,
        case v_type when 'retour_fournisseur' then 'retour_fournisseur' else 'sortie_manuelle' end::public.type_mouvement_stock,
        'ajustement_stock', v_id, v_utilisateur, v_motif, v_note);
    end if;

    insert into public.lignes_ajustement_stock (id, boutique_id, ajustement_id, variante_id, quantite_systeme, quantite_comptee, ecart)
    values (v_ligne.id, v_boutique, v_id, v_ligne.variante_id, v_systeme, v_ligne.quantite_comptee, v_ecart);
    v_nb := v_nb + 1;
  end loop;

  return jsonb_build_object('id', v_id, 'lignes', v_nb, 'rejoue', false);
end;
$$;

-- ---------------------------------------------------------------------------
-- Session de caisse : ouverture avec fond de caisse, clôture avec écart (rapport Z)
-- ---------------------------------------------------------------------------
create or replace function public.ouvrir_session_caisse(
  p_boutique_id uuid, p_id uuid, p_fond numeric default 0, p_appareil_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_utilisateur uuid := prive.exiger_permission(p_boutique_id, 'pos.vendre');
  v_session public.sessions_caisse;
begin
  select * into v_session from public.sessions_caisse s where s.id = p_id;
  if found then
    if v_session.boutique_id <> p_boutique_id then
      raise exception 'acces_refuse' using errcode = '42501';
    end if;
    return jsonb_build_object('id', v_session.id, 'ouverte_le', v_session.ouverte_le, 'rejoue', true);
  end if;
  perform prive.exiger_active(p_boutique_id);
  if p_fond < 0 then
    raise exception 'parametres_invalides' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.sessions_caisse s where s.boutique_id = p_boutique_id and s.utilisateur_id = v_utilisateur and s.fermee_le is null) then
    raise exception 'session_deja_ouverte' using errcode = 'P0001';
  end if;
  insert into public.sessions_caisse (id, boutique_id, utilisateur_id, appareil_id, fond_initial)
  values (p_id, p_boutique_id, v_utilisateur, p_appareil_id, p_fond)
  returning * into v_session;
  return jsonb_build_object('id', v_session.id, 'ouverte_le', v_session.ouverte_le, 'rejoue', false);
end;
$$;

-- Attendu = fond de caisse + espèces encaissées pendant la session. Retourne le rapport Z.
create or replace function public.fermer_session_caisse(p_session_id uuid, p_compte numeric, p_notes text default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session public.sessions_caisse;
  v_attendu numeric;
begin
  select * into v_session from public.sessions_caisse s where s.id = p_session_id for update;
  if not found then
    raise exception 'session_introuvable' using errcode = 'P0001';
  end if;
  perform prive.exiger_permission(v_session.boutique_id, 'pos.vendre');
  if v_session.utilisateur_id <> auth.uid() and not prive.a_permission(v_session.boutique_id, 'rapports.financiers') then
    raise exception 'acces_refuse: session d''une autre utilisatrice' using errcode = '42501';
  end if;
  if v_session.fermee_le is null then
    perform prive.exiger_active(v_session.boutique_id);
    if p_compte is null or p_compte < 0 then
      raise exception 'parametres_invalides' using errcode = 'P0001';
    end if;
    select v_session.fond_initial + coalesce(sum(p.montant), 0) into v_attendu
    from public.paiements p join public.modes_paiement m on m.id = p.mode_paiement_id
    where p.session_caisse_id = p_session_id and m.type = 'especes';
    update public.sessions_caisse
    set fermee_le = now(), attendu = v_attendu, compte = p_compte, ecart = p_compte - v_attendu, notes = p_notes
    where id = p_session_id
    returning * into v_session;
  end if;

  return jsonb_build_object(
    'id', v_session.id, 'ouverte_le', v_session.ouverte_le, 'fermee_le', v_session.fermee_le,
    'fond_initial', v_session.fond_initial, 'attendu', v_session.attendu, 'compte', v_session.compte, 'ecart', v_session.ecart,
    'nb_documents', (select count(*) from public.documents_vente d where d.session_caisse_id = p_session_id and d.statut <> 'annulee'),
    'total_ventes', (select coalesce(sum(d.total), 0) from public.documents_vente d where d.session_caisse_id = p_session_id and d.statut <> 'annulee'),
    'par_mode', coalesce((
      select jsonb_agg(jsonb_build_object('mode_paiement_id', t.mode_paiement_id, 'nom_ar', t.nom_ar, 'nom_fr', t.nom_fr, 'montant', t.montant))
      from (
        select p.mode_paiement_id, m.nom_ar, m.nom_fr, sum(p.montant) as montant
        from public.paiements p join public.modes_paiement m on m.id = p.mode_paiement_id
        where p.session_caisse_id = p_session_id group by p.mode_paiement_id, m.nom_ar, m.nom_fr
      ) t), '[]'::jsonb)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Droits d'exécution : réservés aux utilisatrices connectées (jamais anon).
-- ---------------------------------------------------------------------------
do $$
declare
  f text;
begin
  foreach f in array array[
    'attribuer_numero_document(uuid, text)',
    'reserver_plage_numeros(uuid, text, uuid, integer)',
    'enregistrer_vente(jsonb)',
    'enregistrer_paiement(jsonb)',
    'recevoir_stock(jsonb)',
    'ajuster_stock(jsonb)',
    'ouvrir_session_caisse(uuid, uuid, numeric, uuid)',
    'fermer_session_caisse(uuid, numeric, text)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated, service_role', f);
  end loop;
end;
$$;
