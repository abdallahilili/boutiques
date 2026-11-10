-- =============================================================================
-- Phase 2 — Documents : devis, bons de livraison, conversions, avoirs, annulations.
-- Aucun PDF n'est stocké ; aucune taxe. Numérotation sans trou (DEV / BL / FAC / AV).
-- emettre_document gagne trois paramètres (facture issue de BL : sans nouvelle sortie de stock,
-- échéance, document source) et réutilise l'en-tête commun.
-- =============================================================================

drop function prive.emettre_document(uuid, uuid, uuid, public.type_document_vente, uuid, public.canal_vente, uuid, text, numeric, text, jsonb, jsonb);

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
  p_paiements jsonb,
  p_sans_stock boolean default false,
  p_echeance date default null,
  p_source uuid default null
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
  v_entete := prive.construire_entete(p_boutique, p_client, p_utilisateur);

  insert into public.documents_vente (id, boutique_id, type, numero, statut, client_id, session_caisse_id, canal,
                                      sous_total, remise, total, paye, notes, entete, utilisateur_id, date_echeance, document_source_id)
  values (p_id, p_boutique, p_type, v_numero, v_statut, p_client, p_session, p_canal,
          v_sous_total, p_remise, v_total, v_paye, p_notes, v_entete, p_utilisateur, p_echeance, p_source);

  -- Lignes : verrous pris dans l'ordre des variantes (pas d'interblocage entre ventes concurrentes).
  for v_ligne in
    select (e.elem ->> 'id')::uuid as id, (e.elem ->> 'variante_id')::uuid as variante_id,
           e.elem ->> 'libelle_ar' as libelle_ar, e.elem ->> 'libelle_fr' as libelle_fr,
           (e.elem ->> 'quantite')::numeric as quantite, (e.elem ->> 'prix_unitaire')::numeric as prix_unitaire,
           coalesce((e.elem ->> 'remise')::numeric, 0) as remise, (e.elem ->> 'cout_unitaire')::numeric as cout_unitaire, e.ord::integer as ordre
    from jsonb_array_elements(p_lignes) with ordinality as e(elem, ord)
    order by variante_id nulls last, e.ord
  loop
    v_cout := case when p_sans_stock then coalesce(v_ligne.cout_unitaire, 0) else 0 end;
    if v_ligne.variante_id is not null and not p_sans_stock then
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

-- Rapport de caisse : les remboursements d'avoir en espèces diminuent l'attendu.
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
    select v_session.fond_initial + coalesce(sum(case when d.type = 'avoir' then -p.montant else p.montant end), 0) into v_attendu
    from public.paiements p join public.modes_paiement m on m.id = p.mode_paiement_id
    left join public.documents_vente d on d.id = p.document_id
    where p.session_caisse_id = p_session_id and m.type = 'especes';
    update public.sessions_caisse
    set fermee_le = now(), attendu = v_attendu, compte = p_compte, ecart = p_compte - v_attendu, notes = p_notes
    where id = p_session_id
    returning * into v_session;
  end if;

  return jsonb_build_object(
    'id', v_session.id, 'ouverte_le', v_session.ouverte_le, 'fermee_le', v_session.fermee_le,
    'fond_initial', v_session.fond_initial, 'attendu', v_session.attendu, 'compte', v_session.compte, 'ecart', v_session.ecart,
    'nb_documents', (select count(*) from public.documents_vente d where d.session_caisse_id = p_session_id and d.statut <> 'annulee' and d.type <> 'avoir'),
    'total_ventes', (select coalesce(sum(case when d.type = 'avoir' then -d.total else d.total end), 0) from public.documents_vente d where d.session_caisse_id = p_session_id and d.statut <> 'annulee'),
    'par_mode', coalesce((
      select jsonb_agg(jsonb_build_object('mode_paiement_id', t.mode_paiement_id, 'nom_ar', t.nom_ar, 'nom_fr', t.nom_fr, 'montant', t.montant))
      from (
        select p.mode_paiement_id, m.nom_ar, m.nom_fr, sum(case when d.type = 'avoir' then -p.montant else p.montant end) as montant
        from public.paiements p join public.modes_paiement m on m.id = p.mode_paiement_id
        left join public.documents_vente d on d.id = p.document_id
        where p.session_caisse_id = p_session_id group by p.mode_paiement_id, m.nom_ar, m.nom_fr
      ) t), '[]'::jsonb)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Liens entre documents (regroupement de plusieurs BL en une facture) et lignes d'avoir
-- ---------------------------------------------------------------------------
create table public.documents_liens (
  boutique_id uuid not null references public.boutiques (id) on delete cascade,
  document_id uuid not null,
  source_id uuid not null,
  primary key (document_id, source_id),
  foreign key (boutique_id, document_id) references public.documents_vente (boutique_id, id) on delete cascade,
  foreign key (boutique_id, source_id) references public.documents_vente (boutique_id, id)
);
create index documents_liens_source_idx on public.documents_liens (boutique_id, source_id);
revoke insert, update, delete on public.documents_liens from authenticated;
select prive.creer_politiques_boutique('public.documents_liens', 'documents.creer');

alter table public.lignes_document_vente add column ligne_source_id uuid;
alter table public.lignes_document_vente
  add constraint lignes_document_vente_source_fk foreign key (boutique_id, ligne_source_id) references public.lignes_document_vente (boutique_id, id);
create index lignes_document_vente_source_idx on public.lignes_document_vente (boutique_id, ligne_source_id) where ligne_source_id is not null;

-- ---------------------------------------------------------------------------
-- En-tête figé à l'émission (boutique, cliente, vendeuse)
-- ---------------------------------------------------------------------------
create or replace function prive.construire_entete(p_boutique uuid, p_client uuid, p_utilisateur uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_boutique public.boutiques;
  v_client public.clients;
begin
  select * into v_boutique from public.boutiques where id = p_boutique;
  if p_client is not null then
    select * into v_client from public.clients where id = p_client and boutique_id = p_boutique;
  end if;
  return jsonb_build_object(
    'nom_ar', v_boutique.nom_ar, 'nom_fr', v_boutique.nom_fr, 'logo_url', v_boutique.logo_url,
    'adresse', v_boutique.adresse, 'ville', v_boutique.ville, 'telephone', v_boutique.telephone,
    'whatsapp', v_boutique.whatsapp, 'devise', v_boutique.devise,
    'pied_page_ar', v_boutique.parametres ->> 'pied_page_ar', 'pied_page_fr', v_boutique.parametres ->> 'pied_page_fr',
    'conditions_ar', v_boutique.parametres ->> 'conditions_ar', 'conditions_fr', v_boutique.parametres ->> 'conditions_fr',
    'client', case when p_client is null then null else jsonb_build_object(
      'nom_ar', v_client.nom_ar, 'nom_fr', v_client.nom_fr, 'telephone', v_client.telephone, 'adresse', v_client.adresse) end,
    'vendeuse', (select coalesce(p.nom_ar, p.nom_fr) from public.profils p where p.id = p_utilisateur)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Lignes : validation, libellés et prix résolus côté serveur ; retourne le sous-total.
-- p_lignes : [{ id?, variante_id?, libelle_ar?, libelle_fr?, quantite, prix_unitaire?, remise?, cout_unitaire? }]
-- ---------------------------------------------------------------------------
create or replace function prive.inserer_lignes(p_boutique uuid, p_document uuid, p_lignes jsonb, p_verifier_prix boolean)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v_element record;
  v_variante public.variantes_produit;
  v_prix numeric;
  v_remise numeric;
  v_quantite numeric;
  v_total numeric;
  v_sous_total numeric := 0;
  v_libelle_ar text;
  v_libelle_fr text;
begin
  if jsonb_typeof(p_lignes) is distinct from 'array' or jsonb_array_length(p_lignes) not between 1 and 200 then
    raise exception 'lignes_invalides' using errcode = 'P0001';
  end if;
  for v_element in select e.elem, e.ord from jsonb_array_elements(p_lignes) with ordinality as e(elem, ord) loop
    v_quantite := (v_element.elem ->> 'quantite')::numeric;
    v_remise := coalesce((v_element.elem ->> 'remise')::numeric, 0);
    if v_quantite is null or v_quantite <= 0 or v_remise < 0 then
      raise exception 'ligne_invalide' using errcode = 'P0001';
    end if;
    v_variante := null;
    v_libelle_ar := nullif(v_element.elem ->> 'libelle_ar', '');
    v_libelle_fr := nullif(v_element.elem ->> 'libelle_fr', '');
    if nullif(v_element.elem ->> 'variante_id', '') is not null then
      select * into v_variante from public.variantes_produit v
      where v.id = (v_element.elem ->> 'variante_id')::uuid and v.boutique_id = p_boutique and v.supprime_le is null;
      if not found then
        raise exception 'variante_introuvable' using errcode = 'P0001';
      end if;
      v_libelle_ar := coalesce(v_libelle_ar, prive.libelle_variante(v_variante.id, 'ar'));
      v_libelle_fr := coalesce(v_libelle_fr, prive.libelle_variante(v_variante.id, 'fr'));
    end if;
    if coalesce(v_libelle_ar, v_libelle_fr) is null then
      raise exception 'ligne_invalide: libellé requis' using errcode = 'P0001';
    end if;
    v_prix := coalesce((v_element.elem ->> 'prix_unitaire')::numeric, case when v_variante.id is not null then prive.prix_effectif(v_variante) end);
    if v_prix is null or v_prix < 0 then
      raise exception 'ligne_invalide: prix requis' using errcode = 'P0001';
    end if;
    if p_verifier_prix then
      if v_variante.id is not null and v_prix <> prive.prix_effectif(v_variante) and not prive.a_permission(p_boutique, 'pos.modifier_prix') then
        raise exception 'acces_refuse: permission pos.modifier_prix requise' using errcode = '42501';
      end if;
      if v_remise > 0 and not prive.a_permission(p_boutique, 'pos.remise') then
        raise exception 'acces_refuse: permission pos.remise requise' using errcode = '42501';
      end if;
    end if;
    v_total := round(v_quantite * v_prix - v_remise, 2);
    if v_total < 0 then
      raise exception 'ligne_invalide: remise supérieure au montant' using errcode = 'P0001';
    end if;
    insert into public.lignes_document_vente (id, boutique_id, document_id, variante_id, libelle_ar, libelle_fr,
                                              quantite, prix_unitaire, remise, cout_unitaire, total, ordre)
    values (coalesce((v_element.elem ->> 'id')::uuid, gen_random_uuid()), p_boutique, p_document, v_variante.id, v_libelle_ar, v_libelle_fr,
            v_quantite, v_prix, v_remise, coalesce((v_element.elem ->> 'cout_unitaire')::numeric, 0), v_total, v_element.ord::integer);
    v_sous_total := v_sous_total + v_total;
  end loop;
  return v_sous_total;
end;
$$;

-- ---------------------------------------------------------------------------
-- Création d'un document sans impact stock ni paiement (devis, bon de livraison brouillon)
-- ---------------------------------------------------------------------------
create or replace function prive.creer_document_simple(
  p_boutique uuid, p_utilisateur uuid, p_id uuid, p_type public.type_document_vente, p_statut public.statut_document_vente,
  p_client uuid, p_source uuid, p_echeance date, p_remise numeric, p_notes text, p_lignes jsonb,
  p_canal public.canal_vente, p_verifier_prix boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sous_total numeric;
  v_numero text;
begin
  if p_client is not null and not exists (
    select 1 from public.clients c where c.id = p_client and c.boutique_id = p_boutique and c.supprime_le is null
  ) then
    raise exception 'client_introuvable' using errcode = 'P0001';
  end if;
  if p_remise < 0 then
    raise exception 'remise_invalide' using errcode = 'P0001';
  end if;
  v_numero := prive.prochain_numero(p_boutique, p_type::text);
  insert into public.documents_vente (id, boutique_id, type, numero, statut, client_id, document_source_id, canal,
                                      date_echeance, sous_total, remise, total, paye, notes, entete, utilisateur_id)
  values (p_id, p_boutique, p_type, v_numero, p_statut, p_client, p_source, coalesce(p_canal, 'caisse'),
          p_echeance, 0, 0, 0, 0, p_notes, prive.construire_entete(p_boutique, p_client, p_utilisateur), p_utilisateur);
  v_sous_total := prive.inserer_lignes(p_boutique, p_id, p_lignes, p_verifier_prix);
  if p_remise > v_sous_total then
    raise exception 'remise_invalide' using errcode = 'P0001';
  end if;
  update public.documents_vente set sous_total = v_sous_total, remise = p_remise, total = v_sous_total - p_remise where id = p_id;
  return jsonb_build_object('id', p_id, 'numero', v_numero, 'statut', p_statut, 'total', v_sous_total - p_remise, 'paye', 0,
                            'reste', v_sous_total - p_remise, 'rejoue', false);
end;
$$;

-- Restitue au stock les quantités d'un document annulé (nouveau lot au coût figé de la ligne).
create or replace function prive.restituer_stock_document(p_document public.documents_vente, p_utilisateur uuid, p_note text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ligne record;
begin
  for v_ligne in
    select l.variante_id, l.quantite, l.cout_unitaire from public.lignes_document_vente l
    where l.document_id = p_document.id and l.variante_id is not null order by l.variante_id
  loop
    perform prive.ajouter_lot(p_document.boutique_id, v_ligne.variante_id, v_ligne.quantite, v_ligne.cout_unitaire, null, null, null,
                              'document_vente', p_document.id, p_utilisateur, 'retour_client', p_note);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Devis : aucun impact sur le stock. Validité = date_echeance (30 jours par défaut).
-- donnees : { id, boutique_id, client_id?, date_validite?, remise?, notes?, canal?, statut? ('brouillon' | 'envoye'), lignes }
-- ---------------------------------------------------------------------------
create or replace function public.creer_devis(p_donnees jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_boutique uuid := (p_donnees ->> 'boutique_id')::uuid;
  v_id uuid := (p_donnees ->> 'id')::uuid;
  v_utilisateur uuid;
  v_statut public.statut_document_vente := coalesce(nullif(p_donnees ->> 'statut', ''), 'brouillon')::public.statut_document_vente;
  v_validite date;
begin
  v_utilisateur := prive.exiger_permission(v_boutique, 'documents.creer');
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
  if v_statut not in ('brouillon', 'envoye') then
    raise exception 'statut_invalide' using errcode = 'P0001';
  end if;
  v_validite := coalesce(
    (p_donnees ->> 'date_validite')::date,
    current_date + coalesce((select (b.parametres ->> 'validite_devis_jours')::integer from public.boutiques b where b.id = v_boutique), 30)
  );
  return prive.creer_document_simple(
    v_boutique, v_utilisateur, v_id, 'devis', v_statut, nullif(p_donnees ->> 'client_id', '')::uuid, null, v_validite,
    coalesce((p_donnees ->> 'remise')::numeric, 0), nullif(p_donnees ->> 'notes', ''), p_donnees -> 'lignes',
    coalesce(nullif(p_donnees ->> 'canal', ''), 'caisse')::public.canal_vente, true
  );
end;
$$;

-- Modification d'un devis tant qu'il est en brouillon (les lignes sont remplacées).
create or replace function public.modifier_devis(p_donnees jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document public.documents_vente;
  v_utilisateur uuid;
  v_client uuid;
  v_sous_total numeric;
  v_remise numeric;
begin
  select * into v_document from public.documents_vente d where d.id = (p_donnees ->> 'id')::uuid for update;
  if not found or v_document.type <> 'devis' then
    raise exception 'document_introuvable' using errcode = 'P0001';
  end if;
  v_utilisateur := prive.exiger_permission(v_document.boutique_id, 'documents.creer');
  perform prive.exiger_active(v_document.boutique_id);
  if v_document.statut <> 'brouillon' then
    raise exception 'document_non_modifiable: seul un brouillon est modifiable' using errcode = 'P0001';
  end if;
  v_client := case when p_donnees ? 'client_id' then nullif(p_donnees ->> 'client_id', '')::uuid else v_document.client_id end;
  if v_client is not null and not exists (
    select 1 from public.clients c where c.id = v_client and c.boutique_id = v_document.boutique_id and c.supprime_le is null
  ) then
    raise exception 'client_introuvable' using errcode = 'P0001';
  end if;
  delete from public.lignes_document_vente where document_id = v_document.id;
  v_sous_total := prive.inserer_lignes(v_document.boutique_id, v_document.id, p_donnees -> 'lignes', true);
  v_remise := coalesce((p_donnees ->> 'remise')::numeric, v_document.remise);
  if v_remise < 0 or v_remise > v_sous_total then
    raise exception 'remise_invalide' using errcode = 'P0001';
  end if;
  update public.documents_vente
  set client_id = v_client, sous_total = v_sous_total, remise = v_remise, total = v_sous_total - v_remise,
      date_echeance = coalesce((p_donnees ->> 'date_validite')::date, date_echeance),
      notes = case when p_donnees ? 'notes' then nullif(p_donnees ->> 'notes', '') else notes end,
      entete = prive.construire_entete(v_document.boutique_id, v_client, v_utilisateur)
  where id = v_document.id;
  return prive.resume_document(v_document.id) || jsonb_build_object('rejoue', false);
end;
$$;

-- Transitions d'un devis : brouillon → envoyé → accepté / refusé (expiré par la tâche quotidienne).
create or replace function public.changer_statut_devis(p_id uuid, p_statut public.statut_document_vente)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document public.documents_vente;
begin
  select * into v_document from public.documents_vente d where d.id = p_id for update;
  if not found or v_document.type <> 'devis' then
    raise exception 'document_introuvable' using errcode = 'P0001';
  end if;
  perform prive.exiger_permission(v_document.boutique_id, 'documents.creer');
  if v_document.statut = p_statut then
    return prive.resume_document(p_id);
  end if;
  perform prive.exiger_active(v_document.boutique_id);
  if not ((v_document.statut = 'brouillon' and p_statut in ('envoye', 'accepte', 'refuse'))
          or (v_document.statut = 'envoye' and p_statut in ('accepte', 'refuse'))) then
    raise exception 'transition_invalide: % → %', v_document.statut, p_statut using errcode = 'P0001';
  end if;
  if p_statut in ('envoye', 'accepte') and v_document.date_echeance is not null and v_document.date_echeance < current_date then
    update public.documents_vente set statut = 'expire' where id = p_id;
    raise exception 'devis_expire' using errcode = 'P0001';
  end if;
  update public.documents_vente set statut = p_statut where id = p_id;
  return prive.resume_document(p_id);
end;
$$;

-- Tâche quotidienne (service uniquement) : les devis non acceptés dont la validité est dépassée expirent.
create or replace function public.expirer_devis_perimes()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nombre integer;
begin
  if not prive.est_service() then
    raise exception 'acces_refuse' using errcode = '42501';
  end if;
  update public.documents_vente set statut = 'expire'
  where type = 'devis' and statut in ('brouillon', 'envoye') and date_echeance < current_date;
  get diagnostics v_nombre = row_count;
  return v_nombre;
end;
$$;

-- ---------------------------------------------------------------------------
-- Bon de livraison : brouillon libre ; la sortie de stock a lieu à la validation.
-- donnees : { id, boutique_id, client_id?, remise?, notes?, canal?, lignes }
-- ---------------------------------------------------------------------------
create or replace function public.creer_bon_livraison(p_donnees jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_boutique uuid := (p_donnees ->> 'boutique_id')::uuid;
  v_id uuid := (p_donnees ->> 'id')::uuid;
  v_utilisateur uuid;
begin
  v_utilisateur := prive.exiger_permission(v_boutique, 'documents.creer');
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
  return prive.creer_document_simple(
    v_boutique, v_utilisateur, v_id, 'bon_livraison', 'brouillon', nullif(p_donnees ->> 'client_id', '')::uuid, null, null,
    coalesce((p_donnees ->> 'remise')::numeric, 0), nullif(p_donnees ->> 'notes', ''), p_donnees -> 'lignes',
    coalesce(nullif(p_donnees ->> 'canal', ''), 'caisse')::public.canal_vente, true
  );
end;
$$;

-- brouillon → validé (sortie de stock FIFO/FEFO, coût figé) → livré.
create or replace function public.changer_statut_bon_livraison(p_id uuid, p_statut public.statut_document_vente)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document public.documents_vente;
  v_utilisateur uuid;
  v_ligne record;
  v_cout numeric;
begin
  select * into v_document from public.documents_vente d where d.id = p_id for update;
  if not found or v_document.type <> 'bon_livraison' then
    raise exception 'document_introuvable' using errcode = 'P0001';
  end if;
  v_utilisateur := prive.exiger_permission(v_document.boutique_id, 'documents.creer');
  if v_document.statut = p_statut then
    return prive.resume_document(p_id);
  end if;
  perform prive.exiger_active(v_document.boutique_id);
  if v_document.statut = 'brouillon' and p_statut = 'valide' then
    for v_ligne in
      select l.id, l.variante_id, l.quantite from public.lignes_document_vente l
      where l.document_id = p_id and l.variante_id is not null order by l.variante_id, l.ordre
    loop
      v_cout := prive.consommer_stock(v_document.boutique_id, v_ligne.variante_id, v_ligne.quantite, 'sortie_vente', 'document_vente', p_id, v_utilisateur);
      update public.lignes_document_vente set cout_unitaire = v_cout where id = v_ligne.id;
    end loop;
  elsif not (v_document.statut = 'valide' and p_statut = 'livre') then
    raise exception 'transition_invalide: % → %', v_document.statut, p_statut using errcode = 'P0001';
  end if;
  update public.documents_vente set statut = p_statut where id = p_id;
  return prive.resume_document(p_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- Conversion : devis → BL ou facture ; un ou plusieurs BL (même cliente) → facture.
-- donnees : { id (nouveau document), type_cible, source_id | source_ids, notes?, client_id?, date_echeance?,
--             session_caisse_id?, paiements? }
-- ---------------------------------------------------------------------------
create or replace function public.convertir_document(p_donnees jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid := (p_donnees ->> 'id')::uuid;
  v_cible public.type_document_vente := (p_donnees ->> 'type_cible')::public.type_document_vente;
  v_ids uuid[];
  v_source public.documents_vente;
  v_nombre integer := 0;
  v_boutique uuid;
  v_utilisateur uuid;
  v_type public.type_document_vente;
  v_client uuid;
  v_canal public.canal_vente;
  v_lignes jsonb;
  v_remise numeric := 0;
  v_resultat jsonb;
  v_notes text := nullif(p_donnees ->> 'notes', '');
begin
  select coalesce(array_agg(distinct x.v), '{}') into v_ids
  from (select (jsonb_array_elements_text(coalesce(p_donnees -> 'source_ids', '[]'::jsonb)))::uuid as v
        union select nullif(p_donnees ->> 'source_id', '')::uuid) x
  where x.v is not null;
  if v_id is null or coalesce(array_length(v_ids, 1), 0) = 0 or v_cible is null then
    raise exception 'parametres_invalides' using errcode = 'P0001';
  end if;
  select d.boutique_id into v_boutique from public.documents_vente d where d.id = v_ids[1];
  if v_boutique is null then
    raise exception 'document_introuvable' using errcode = 'P0001';
  end if;
  v_utilisateur := prive.exiger_permission(v_boutique, 'documents.gerer');
  if exists (select 1 from public.documents_vente d where d.id = v_id) then
    if not exists (select 1 from public.documents_vente d where d.id = v_id and d.boutique_id = v_boutique) then
      raise exception 'acces_refuse' using errcode = '42501';
    end if;
    return prive.resume_document(v_id);
  end if;
  perform prive.exiger_active(v_boutique);

  for v_source in select * from public.documents_vente d where d.id = any (v_ids) order by d.id for update loop
    v_nombre := v_nombre + 1;
    if v_source.boutique_id <> v_boutique then
      raise exception 'acces_refuse' using errcode = '42501';
    end if;
    if v_type is not null and v_source.type <> v_type then
      raise exception 'conversion_impossible: types de sources différents' using errcode = 'P0001';
    end if;
    v_type := v_source.type;
    if v_nombre = 1 then
      v_client := v_source.client_id;
      v_canal := v_source.canal;
    elsif v_source.client_id is distinct from v_client then
      raise exception 'clients_differents: les documents regroupés doivent concerner la même cliente' using errcode = 'P0001';
    end if;
    if v_source.statut = 'annulee' then
      raise exception 'document_annule' using errcode = 'P0001';
    end if;
    if v_source.type = 'devis' then
      if v_source.statut not in ('brouillon', 'envoye', 'accepte') then
        raise exception 'devis_non_convertible: statut %', v_source.statut using errcode = 'P0001';
      end if;
      if v_source.date_echeance is not null and v_source.date_echeance < current_date then
        raise exception 'devis_expire' using errcode = 'P0001';
      end if;
    elsif v_source.type = 'bon_livraison' then
      if v_source.statut not in ('valide', 'livre') then
        raise exception 'bl_non_valide: validez le bon de livraison avant de le facturer' using errcode = 'P0001';
      end if;
    else
      raise exception 'conversion_impossible: type % non convertible', v_source.type using errcode = 'P0001';
    end if;
    if exists (
      select 1 from public.documents_liens k join public.documents_vente d on d.id = k.document_id
      where k.source_id = v_source.id and d.statut <> 'annulee' and d.type in ('bon_livraison', 'facture')
    ) then
      raise exception 'deja_converti: % a déjà été converti', v_source.numero using errcode = 'P0001';
    end if;
    v_remise := v_remise + v_source.remise;
  end loop;
  if v_nombre <> array_length(v_ids, 1) then
    raise exception 'document_introuvable' using errcode = 'P0001';
  end if;
  if not ((v_type = 'devis' and v_nombre = 1 and v_cible in ('bon_livraison', 'facture'))
          or (v_type = 'bon_livraison' and v_cible = 'facture')) then
    raise exception 'conversion_impossible: % → %', v_type, v_cible using errcode = 'P0001';
  end if;
  v_client := coalesce(v_client, nullif(p_donnees ->> 'client_id', '')::uuid);

  select jsonb_agg(jsonb_build_object(
           'variante_id', l.variante_id, 'libelle_ar', l.libelle_ar, 'libelle_fr', l.libelle_fr, 'quantite', l.quantite,
           'prix_unitaire', l.prix_unitaire, 'remise', l.remise, 'cout_unitaire', l.cout_unitaire)
         order by d.date_emission, d.id, l.ordre)
  into v_lignes
  from public.lignes_document_vente l join public.documents_vente d on d.id = l.document_id
  where d.id = any (v_ids);

  if v_cible = 'bon_livraison' then
    v_resultat := prive.creer_document_simple(v_boutique, v_utilisateur, v_id, 'bon_livraison', 'brouillon', v_client, v_ids[1], null,
                                              v_remise, v_notes, v_lignes, v_canal, false);
  else
    v_resultat := prive.emettre_document(
      v_boutique, v_utilisateur, v_id, 'facture', v_client, v_canal, nullif(p_donnees ->> 'session_caisse_id', '')::uuid, null,
      v_remise, v_notes, v_lignes, coalesce(p_donnees -> 'paiements', '[]'::jsonb),
      v_type = 'bon_livraison', (p_donnees ->> 'date_echeance')::date, v_ids[1]
    );
  end if;

  insert into public.documents_liens (boutique_id, document_id, source_id)
  select v_boutique, v_id, s from unnest(v_ids) s;
  if v_type = 'devis' then
    update public.documents_vente set statut = 'accepte' where id = v_ids[1] and statut in ('brouillon', 'envoye');
  elsif v_cible = 'facture' then
    update public.documents_vente set statut = 'facture' where id = any (v_ids);
  end if;
  return v_resultat;
end;
$$;

-- ---------------------------------------------------------------------------
-- Avoir : depuis une facture ou un ticket. Retour en stock optionnel. Règlement :
--  1) imputé d'abord sur le reste à payer de la facture ; 2) remboursé (espèces, etc.) ;
--  3) le solde éventuel est porté au crédit de la cliente (identifiée).
-- donnees : { id, facture_id, motif?, retour_stock?, session_caisse_id?,
--             lignes: [{ ligne_id, quantite }], remboursements?: [{ id?, mode_paiement_id, montant, reference? }] }
-- ---------------------------------------------------------------------------
create or replace function public.creer_avoir(p_donnees jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid := (p_donnees ->> 'id')::uuid;
  v_source public.documents_vente;
  v_utilisateur uuid;
  v_retour boolean := coalesce((p_donnees ->> 'retour_stock')::boolean, false);
  v_session uuid := nullif(p_donnees ->> 'session_caisse_id', '')::uuid;
  v_element record;
  v_orig public.lignes_document_vente;
  v_deja numeric;
  v_quantite numeric;
  v_remise_ligne numeric;
  v_total_ligne numeric;
  v_sous_total numeric := 0;
  v_remise numeric;
  v_total numeric;
  v_total_avoirs numeric;
  v_applique numeric;
  v_du numeric;
  v_rembourse numeric := 0;
  v_credit numeric;
  v_paiement record;
  v_type_mode public.type_mode_paiement;
  v_numero text;
  v_paye_source numeric;
begin
  select * into v_source from public.documents_vente d where d.id = (p_donnees ->> 'facture_id')::uuid for update;
  if not found then
    raise exception 'document_introuvable' using errcode = 'P0001';
  end if;
  v_utilisateur := prive.exiger_permission(v_source.boutique_id, 'documents.gerer');
  if v_id is null then
    raise exception 'identifiant_requis' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.documents_vente d where d.id = v_id) then
    if not exists (select 1 from public.documents_vente d where d.id = v_id and d.boutique_id = v_source.boutique_id) then
      raise exception 'acces_refuse' using errcode = '42501';
    end if;
    return prive.resume_document(v_id);
  end if;
  perform prive.exiger_active(v_source.boutique_id);
  if v_source.type not in ('facture', 'ticket') or v_source.statut not in ('emise', 'partiellement_payee', 'payee') then
    raise exception 'document_non_avoirable' using errcode = 'P0001';
  end if;
  if jsonb_typeof(p_donnees -> 'lignes') is distinct from 'array' or jsonb_array_length(p_donnees -> 'lignes') not between 1 and 200 then
    raise exception 'lignes_invalides' using errcode = 'P0001';
  end if;
  if v_session is not null and not exists (
    select 1 from public.sessions_caisse s
    where s.id = v_session and s.boutique_id = v_source.boutique_id and s.utilisateur_id = v_utilisateur and s.fermee_le is null
  ) then
    raise exception 'session_caisse_invalide' using errcode = 'P0001';
  end if;

  v_numero := prive.prochain_numero(v_source.boutique_id, 'avoir');
  insert into public.documents_vente (id, boutique_id, type, numero, statut, client_id, document_source_id, canal, sous_total, remise, total,
                                      paye, notes, entete, utilisateur_id)
  values (v_id, v_source.boutique_id, 'avoir', v_numero, 'emise', v_source.client_id, v_source.id, v_source.canal, 0, 0, 0, 0,
          nullif(p_donnees ->> 'motif', ''), prive.construire_entete(v_source.boutique_id, v_source.client_id, v_utilisateur), v_utilisateur);

  for v_element in select e.elem, e.ord from jsonb_array_elements(p_donnees -> 'lignes') with ordinality as e(elem, ord) order by (e.elem ->> 'ligne_id') loop
    select * into v_orig from public.lignes_document_vente l
    where l.id = (v_element.elem ->> 'ligne_id')::uuid and l.document_id = v_source.id;
    if not found then
      raise exception 'ligne_introuvable' using errcode = 'P0001';
    end if;
    v_quantite := (v_element.elem ->> 'quantite')::numeric;
    select coalesce(sum(l.quantite), 0) into v_deja from public.lignes_document_vente l where l.ligne_source_id = v_orig.id;
    if v_quantite is null or v_quantite <= 0 or v_quantite + v_deja > v_orig.quantite then
      raise exception 'quantite_avoir_excessive: ligne % (facturé %, déjà avoiré %)', v_orig.id, v_orig.quantite, v_deja using errcode = 'P0001';
    end if;
    v_remise_ligne := round(v_orig.remise * v_quantite / v_orig.quantite, 2);
    v_total_ligne := round(v_quantite * v_orig.prix_unitaire - v_remise_ligne, 2);
    insert into public.lignes_document_vente (id, boutique_id, document_id, variante_id, libelle_ar, libelle_fr, quantite, prix_unitaire,
                                              remise, cout_unitaire, total, ordre, ligne_source_id)
    values (gen_random_uuid(), v_source.boutique_id, v_id, v_orig.variante_id, v_orig.libelle_ar, v_orig.libelle_fr, v_quantite,
            v_orig.prix_unitaire, v_remise_ligne, v_orig.cout_unitaire, v_total_ligne, v_element.ord::integer, v_orig.id);
    v_sous_total := v_sous_total + v_total_ligne;
    if v_retour and v_orig.variante_id is not null then
      perform prive.ajouter_lot(v_source.boutique_id, v_orig.variante_id, v_quantite, v_orig.cout_unitaire, null, null, null,
                                'document_vente', v_id, v_utilisateur, 'retour_client', 'avoir ' || v_numero);
    end if;
  end loop;

  v_remise := case when v_source.sous_total > 0 then round(v_sous_total * v_source.remise / v_source.sous_total, 2) else 0 end;
  v_total := v_sous_total - v_remise;
  select coalesce(sum(a.total), 0) into v_total_avoirs from public.documents_vente a
  where a.type = 'avoir' and a.document_source_id = v_source.id and a.statut <> 'annulee' and a.id <> v_id;
  if v_total_avoirs + v_total > v_source.total then
    raise exception 'avoir_excessif: total des avoirs supérieur à la facture' using errcode = 'P0001';
  end if;

  v_applique := least(v_total, v_source.reste);
  v_du := v_total - v_applique;
  for v_paiement in
    select coalesce(pm.id, gen_random_uuid()) as id, pm.mode_paiement_id, pm.montant, pm.reference
    from jsonb_to_recordset(coalesce(p_donnees -> 'remboursements', '[]'::jsonb)) as pm(id uuid, mode_paiement_id uuid, montant numeric, reference text)
  loop
    select m.type into v_type_mode from public.modes_paiement m
    where m.id = v_paiement.mode_paiement_id and m.boutique_id = v_source.boutique_id and m.actif;
    if v_type_mode is null or v_type_mode = 'credit' or v_paiement.montant is null or v_paiement.montant <= 0 then
      raise exception 'mode_paiement_invalide' using errcode = 'P0001';
    end if;
    insert into public.paiements (id, boutique_id, document_id, client_id, mode_paiement_id, montant, session_caisse_id, reference, utilisateur_id)
    values (v_paiement.id, v_source.boutique_id, v_id, v_source.client_id, v_paiement.mode_paiement_id, v_paiement.montant, v_session,
            v_paiement.reference, v_utilisateur);
    v_rembourse := v_rembourse + v_paiement.montant;
  end loop;
  if v_rembourse > v_du then
    raise exception 'remboursement_excessif: à rembourser au plus %', v_du using errcode = 'P0001';
  end if;
  v_credit := v_du - v_rembourse;
  if v_credit > 0 and v_source.client_id is null then
    raise exception 'client_requis: le solde de l''avoir exige une cliente identifiée' using errcode = 'P0001';
  end if;

  v_paye_source := v_source.paye + v_applique;
  update public.documents_vente
  set paye = v_paye_source,
      statut = (case when v_paye_source >= total then 'payee' when v_paye_source > 0 then 'partiellement_payee' else 'emise' end)::public.statut_document_vente
  where id = v_source.id;
  if v_source.client_id is not null and v_applique + v_credit > 0 then
    update public.clients set solde = solde - (v_applique + v_credit) where id = v_source.client_id;
  end if;
  update public.documents_vente
  set sous_total = v_sous_total, remise = v_remise, total = v_total, paye = v_total, statut = 'payee'
  where id = v_id;
  insert into public.documents_liens (boutique_id, document_id, source_id) values (v_source.boutique_id, v_id, v_source.id);

  return jsonb_build_object('id', v_id, 'numero', v_numero, 'statut', 'payee', 'total', v_total, 'applique', v_applique,
                            'rembourse', v_rembourse, 'credit_cliente', v_credit, 'rejoue', false);
end;
$$;

-- ---------------------------------------------------------------------------
-- Annulation tracée. Une facture déjà encaissée ne s'annule pas : elle se corrige par un avoir.
-- ---------------------------------------------------------------------------
create or replace function public.annuler_document(p_id uuid, p_motif text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document public.documents_vente;
  v_utilisateur uuid;
begin
  select * into v_document from public.documents_vente d where d.id = p_id for update;
  if not found then
    raise exception 'document_introuvable' using errcode = 'P0001';
  end if;
  v_utilisateur := prive.exiger_permission(v_document.boutique_id, 'documents.gerer');
  if v_document.statut = 'annulee' then
    return prive.resume_document(p_id);
  end if;
  perform prive.exiger_active(v_document.boutique_id);
  if nullif(trim(p_motif), '') is null then
    raise exception 'motif_requis' using errcode = 'P0001';
  end if;

  if v_document.type = 'avoir' then
    raise exception 'annulation_impossible: un avoir ne s''annule pas' using errcode = 'P0001';
  elsif v_document.type = 'devis' then
    if v_document.statut in ('accepte') and exists (
      select 1 from public.documents_liens k join public.documents_vente d on d.id = k.document_id
      where k.source_id = p_id and d.statut <> 'annulee') then
      raise exception 'annulation_impossible: devis déjà converti' using errcode = 'P0001';
    end if;
  elsif v_document.type = 'bon_livraison' then
    if v_document.statut = 'facture' then
      raise exception 'annulation_impossible: bon de livraison déjà facturé' using errcode = 'P0001';
    end if;
    if v_document.statut in ('valide', 'livre') then
      perform prive.restituer_stock_document(v_document, v_utilisateur, 'annulation ' || v_document.numero);
    end if;
  else
    if v_document.paye > 0 or exists (
      select 1 from public.documents_vente a where a.type = 'avoir' and a.document_source_id = p_id and a.statut <> 'annulee') then
      raise exception 'annulation_impossible: facture encaissée ou avoirée, créez un avoir' using errcode = 'P0001';
    end if;
    -- Facture issue de bons de livraison : le stock reste sorti (propre aux BL) et les BL redeviennent facturables.
    if exists (select 1 from public.documents_liens k join public.documents_vente s on s.id = k.source_id
               where k.document_id = p_id and s.type = 'bon_livraison') then
      update public.documents_vente set statut = 'livre'
      where id in (select k.source_id from public.documents_liens k where k.document_id = p_id);
    else
      perform prive.restituer_stock_document(v_document, v_utilisateur, 'annulation ' || v_document.numero);
    end if;
    if v_document.client_id is not null and v_document.reste > 0 then
      update public.clients set solde = solde - v_document.reste where id = v_document.client_id;
    end if;
  end if;

  update public.documents_vente set statut = 'annulee', annule_le = now(), motif_annulation = trim(p_motif) where id = p_id;
  return prive.resume_document(p_id) || jsonb_build_object('rejoue', false);
end;
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'creer_devis(jsonb)', 'modifier_devis(jsonb)', 'changer_statut_devis(uuid, public.statut_document_vente)',
    'creer_bon_livraison(jsonb)', 'changer_statut_bon_livraison(uuid, public.statut_document_vente)',
    'convertir_document(jsonb)', 'creer_avoir(jsonb)', 'annuler_document(uuid, text)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated, service_role', f);
  end loop;
end;
$$;
revoke all on function public.expirer_devis_perimes() from public, anon, authenticated;
grant execute on function public.expirer_devis_perimes() to service_role;
