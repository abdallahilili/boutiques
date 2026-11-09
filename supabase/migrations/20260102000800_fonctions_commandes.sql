-- =============================================================================
-- Commandes en ligne : RPC publique (visiteuse anonyme), suivi, justificatif, résolution du domaine,
-- changement de statut, génération de la facture. Prix et stock sont toujours revérifiés côté serveur.
-- =============================================================================

-- Résout la boutique à partir du nom d'hôte (sous-domaine ou domaine personnalisé vérifié).
create or replace function public.resoudre_boutique(p_hote text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'boutique_id', b.id,
    'slug', b.slug,
    'disponible', b.statut in ('essai', 'actif', 'grace') and coalesce(ps.publie, false)
  )
  from public.domaines_boutique d
  join public.boutiques b on b.id = d.boutique_id
  left join public.parametres_site ps on ps.boutique_id = b.id
  where lower(d.domaine_personnalise) = lower(p_hote) and d.statut_dns = 'verifie'
     or (position('.' in p_hote) > 0 and d.sous_domaine = split_part(lower(p_hote), '.', 1))
  order by (lower(d.domaine_personnalise) = lower(p_hote)) desc nulls last
  limit 1;
$$;

-- Résumé public d'une commande (page de confirmation).
create or replace function prive.resume_commande(p_id uuid, p_rejoue boolean)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object('id', c.id, 'numero', c.numero, 'statut', c.statut, 'sous_total', c.sous_total,
                            'frais_livraison', c.frais_livraison, 'total', c.total, 'rejoue', p_rejoue)
  from public.commandes c where c.id = p_id;
$$;

-- Libère les réservations d'une commande (annulation ou émission du document).
create or replace function prive.liberer_reservations(p_commande public.commandes, p_utilisateur uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ligne record;
begin
  for v_ligne in
    select l.variante_id, l.quantite from public.lignes_commande l
    where l.commande_id = p_commande.id and l.boutique_id = p_commande.boutique_id
    order by l.variante_id
  loop
    perform 1 from public.variantes_produit v where v.id = v_ligne.variante_id for update;
    insert into public.mouvements_stock (boutique_id, variante_id, type, quantite, source_type, source_id, utilisateur_id)
    values (p_commande.boutique_id, v_ligne.variante_id, 'liberation', -v_ligne.quantite, 'commande', p_commande.id, p_utilisateur);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Passer une commande (anonyme ou cliente connectée)
-- donnees : { id, nom_client, telephone, adresse?, ville?, zone_id?, mode_livraison?, mode_paiement?,
--             notes?, miel (champ piège anti-robot : doit rester vide),
--             lignes: [{ variante_id, quantite }] }
-- ---------------------------------------------------------------------------
create or replace function public.passer_commande_en_ligne(p_slug text, p_donnees jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_boutique public.boutiques;
  v_param public.parametres_site;
  v_id uuid := (p_donnees ->> 'id')::uuid;
  v_nom text := trim(coalesce(p_donnees ->> 'nom_client', ''));
  v_tel text := prive.normaliser_telephone(p_donnees ->> 'telephone');
  v_mode_livraison public.mode_livraison := coalesce(nullif(p_donnees ->> 'mode_livraison', ''), 'livraison')::public.mode_livraison;
  v_mode_paiement public.mode_paiement_commande := coalesce(nullif(p_donnees ->> 'mode_paiement', ''), 'a_la_livraison')::public.mode_paiement_commande;
  v_adresse text := nullif(trim(coalesce(p_donnees ->> 'adresse', '')), '');
  v_zone public.zones_livraison;
  v_frais numeric := 0;
  v_element record;
  v_variante public.variantes_produit;
  v_prix numeric;
  v_sous_total numeric := 0;
  v_lignes jsonb := '[]'::jsonb;
  v_compte uuid;
  v_numero text;
  v_ip text := prive.adresse_ip();
begin
  if coalesce(p_donnees ->> 'miel', '') <> '' then
    raise exception 'requete_invalide' using errcode = 'P0001';
  end if;
  select * into v_boutique from public.boutiques b where b.slug = p_slug;
  select * into v_param from public.parametres_site ps where ps.boutique_id = v_boutique.id;
  if v_boutique.id is null or v_boutique.statut not in ('essai', 'actif', 'grace') or not coalesce(v_param.publie, false) then
    raise exception 'boutique_indisponible' using errcode = 'P0001';
  end if;
  if v_id is null then
    raise exception 'identifiant_requis' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.commandes c where c.id = v_id) then
    if not exists (select 1 from public.commandes c where c.id = v_id and c.boutique_id = v_boutique.id) then
      raise exception 'requete_invalide' using errcode = 'P0001';
    end if;
    return prive.resume_commande(v_id, true);
  end if;

  if length(v_nom) not between 2 and 120 or v_tel !~ '^[0-9]{8,15}$' then
    raise exception 'donnees_invalides: nom ou téléphone invalide' using errcode = 'P0001';
  end if;
  perform prive.limiter_debit('commande:tel:' || v_boutique.id || ':' || v_tel, 5, interval '1 hour');
  if v_ip is not null then
    perform prive.limiter_debit('commande:ip:' || v_ip, 30, interval '1 hour');
  end if;

  if jsonb_typeof(p_donnees -> 'lignes') is distinct from 'array'
     or jsonb_array_length(p_donnees -> 'lignes') not between 1 and 50 then
    raise exception 'lignes_invalides' using errcode = 'P0001';
  end if;

  if v_mode_livraison = 'livraison' then
    if not v_param.livraison_active then
      raise exception 'livraison_indisponible' using errcode = 'P0001';
    end if;
    if v_adresse is null then
      raise exception 'adresse_requise' using errcode = 'P0001';
    end if;
    if nullif(p_donnees ->> 'zone_id', '') is not null then
      select * into v_zone from public.zones_livraison z
      where z.id = (p_donnees ->> 'zone_id')::uuid and z.boutique_id = v_boutique.id and z.actif;
      if not found then
        raise exception 'zone_invalide' using errcode = 'P0001';
      end if;
      v_frais := v_zone.frais;
    end if;
  elsif not v_param.retrait_boutique_actif then
    raise exception 'retrait_indisponible' using errcode = 'P0001';
  end if;
  if (v_mode_paiement = 'a_la_livraison' and not v_param.paiement_livraison_actif)
     or (v_mode_paiement = 'mobile_money' and not v_param.mobile_money_actif)
     or v_mode_paiement in ('especes') then
    raise exception 'mode_paiement_indisponible' using errcode = 'P0001';
  end if;

  -- Lignes regroupées par variante, verrouillées dans l'ordre ; prix et disponibilité décidés par le serveur.
  for v_element in
    select (e.elem ->> 'variante_id')::uuid as variante_id, sum((e.elem ->> 'quantite')::numeric) as quantite
    from jsonb_array_elements(p_donnees -> 'lignes') as e(elem)
    group by 1 order by 1
  loop
    if v_element.quantite is null or v_element.quantite <= 0 or v_element.quantite > 999 then
      raise exception 'quantite_invalide' using errcode = 'P0001';
    end if;
    select v.* into v_variante
    from public.variantes_produit v join public.produits p on p.id = v.produit_id
    where v.id = v_element.variante_id and v.boutique_id = v_boutique.id and v.actif and v.supprime_le is null
      and p.statut = 'actif' and p.visible_en_ligne and p.supprime_le is null
    for update of v;
    if not found then
      raise exception 'produit_indisponible' using errcode = 'P0001';
    end if;
    if (select coalesce(sum(l.quantite_restante), 0) from public.lots_stock l where l.variante_id = v_variante.id)
       - prive.quantite_reservee(v_boutique.id, v_variante.id) < v_element.quantite then
      raise exception 'stock_insuffisant: %', prive.libelle_variante(v_variante.id, 'fr') using errcode = 'P0001';
    end if;
    v_prix := prive.prix_effectif(v_variante);
    v_sous_total := v_sous_total + round(v_element.quantite * v_prix, 2);
    v_lignes := v_lignes || jsonb_build_object(
      'variante_id', v_variante.id, 'quantite', v_element.quantite, 'prix_unitaire', v_prix,
      'libelle_ar', prive.libelle_variante(v_variante.id, 'ar'), 'libelle_fr', prive.libelle_variante(v_variante.id, 'fr'));
  end loop;
  if v_sous_total < v_param.commande_minimale then
    raise exception 'commande_minimale: minimum %', v_param.commande_minimale using errcode = 'P0001';
  end if;

  select c.id into v_compte from public.comptes_clientes_site c where c.utilisateur_id = auth.uid() and c.boutique_id = v_boutique.id;
  v_numero := prive.prochain_numero(v_boutique.id, 'commande');

  insert into public.commandes (id, boutique_id, numero, canal, compte_client_id, nom_client, telephone, adresse, ville, zone_id,
                                mode_livraison, frais_livraison, mode_paiement, sous_total, total, notes)
  values (v_id, v_boutique.id, v_numero, 'site_web', v_compte, v_nom, v_tel, v_adresse, nullif(trim(coalesce(p_donnees ->> 'ville', '')), ''), v_zone.id,
          v_mode_livraison, v_frais, v_mode_paiement, v_sous_total, v_sous_total + v_frais, nullif(trim(coalesce(p_donnees ->> 'notes', '')), ''));

  insert into public.lignes_commande (boutique_id, commande_id, variante_id, quantite, prix_unitaire, libelle_ar, libelle_fr, total)
  select v_boutique.id, v_id, (l ->> 'variante_id')::uuid, (l ->> 'quantite')::numeric, (l ->> 'prix_unitaire')::numeric,
         l ->> 'libelle_ar', l ->> 'libelle_fr', round((l ->> 'quantite')::numeric * (l ->> 'prix_unitaire')::numeric, 2)
  from jsonb_array_elements(v_lignes) as l;

  -- Réservation du stock (libérée à l'annulation, consommée à l'émission du document).
  insert into public.mouvements_stock (boutique_id, variante_id, type, quantite, source_type, source_id)
  select v_boutique.id, (l ->> 'variante_id')::uuid, 'reservation', (l ->> 'quantite')::numeric, 'commande', v_id
  from jsonb_array_elements(v_lignes) as l;

  insert into public.historique_statuts_commande (boutique_id, commande_id, statut) values (v_boutique.id, v_id, 'nouvelle');

  -- Notification in-app (le push FCM est envoyé par Edge Function) aux membres qui gèrent les commandes.
  insert into public.notifications (boutique_id, utilisateur_id, type, titre_ar, titre_fr, corps_ar, corps_fr, cible, donnees)
  select v_boutique.id, m.utilisateur_id, 'commande_nouvelle', 'طلب جديد', 'Nouvelle commande',
         v_numero || ' — ' || v_nom, v_numero || ' — ' || v_nom, 'boutique',
         jsonb_build_object('commande_id', v_id, 'numero', v_numero)
  from public.membres_boutique m
  join public.permissions_role pr on pr.role_id = m.role_id and pr.autorise and pr.cle_permission = 'commandes.lire'
  where m.boutique_id = v_boutique.id and m.statut = 'actif';

  return prive.resume_commande(v_id, false);
exception
  when unique_violation then
    if exists (select 1 from public.commandes c where c.id = v_id and c.boutique_id = v_boutique.id) then
      return prive.resume_commande(v_id, true);
    end if;
    raise;
end;
$$;

-- Suivi sans compte : numéro + téléphone. Même erreur si le numéro ou le téléphone est faux.
create or replace function public.suivre_commande(p_slug text, p_numero text, p_telephone text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_commande public.commandes;
  v_tel text := prive.normaliser_telephone(p_telephone);
  v_ip text := prive.adresse_ip();
begin
  perform prive.limiter_debit('suivi:tel:' || v_tel, 20, interval '1 hour');
  if v_ip is not null then
    perform prive.limiter_debit('suivi:ip:' || v_ip, 60, interval '1 hour');
  end if;
  select c.* into v_commande
  from public.commandes c join public.boutiques b on b.id = c.boutique_id
  where b.slug = p_slug and c.numero = upper(trim(p_numero)) and c.telephone = v_tel;
  if not found then
    raise exception 'commande_introuvable' using errcode = 'P0001';
  end if;
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

-- Rattache une preuve de paiement (déjà envoyée dans payment-proofs) à la commande de la visiteuse.
create or replace function public.joindre_justificatif_commande(p_slug text, p_commande_id uuid, p_telephone text, p_chemin text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_commande public.commandes;
begin
  perform prive.limiter_debit('justificatif:tel:' || prive.normaliser_telephone(p_telephone), 10, interval '1 hour');
  select c.* into v_commande
  from public.commandes c join public.boutiques b on b.id = c.boutique_id
  where c.id = p_commande_id and b.slug = p_slug and c.telephone = prive.normaliser_telephone(p_telephone);
  if not found or p_chemin not like v_commande.boutique_id || '/commandes/' || v_commande.id || '/%' then
    raise exception 'commande_introuvable' using errcode = 'P0001';
  end if;
  update public.commandes set justificatif_url = p_chemin where id = v_commande.id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Facture d'une commande : libère la réservation, sort le stock (FIFO), fige le coût.
-- ---------------------------------------------------------------------------
create or replace function prive.creer_document_commande(
  p_commande public.commandes, p_utilisateur uuid, p_document uuid, p_paiements jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_client uuid := p_commande.client_id;
  v_lignes jsonb;
  v_resultat jsonb;
begin
  if v_client is null then
    select c.id into v_client from public.clients c
    where c.boutique_id = p_commande.boutique_id and c.telephone = p_commande.telephone and c.supprime_le is null
    order by c.cree_le limit 1;
    if v_client is null then
      insert into public.clients (boutique_id, nom_ar, nom_fr, telephone, whatsapp, adresse, ville, cree_par)
      values (p_commande.boutique_id, p_commande.nom_client, p_commande.nom_client, p_commande.telephone, p_commande.telephone,
              p_commande.adresse, p_commande.ville, p_utilisateur)
      returning id into v_client;
    end if;
    update public.commandes set client_id = v_client where id = p_commande.id;
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
           'variante_id', l.variante_id, 'libelle_ar', l.libelle_ar, 'libelle_fr', l.libelle_fr,
           'quantite', l.quantite, 'prix_unitaire', l.prix_unitaire, 'remise', 0) order by l.id), '[]'::jsonb)
  into v_lignes
  from public.lignes_commande l where l.commande_id = p_commande.id;
  if p_commande.frais_livraison > 0 then
    v_lignes := v_lignes || jsonb_build_object('libelle_ar', 'رسوم التوصيل', 'libelle_fr', 'Frais de livraison',
                                               'quantite', 1, 'prix_unitaire', p_commande.frais_livraison, 'remise', 0);
  end if;

  perform prive.liberer_reservations(p_commande, p_utilisateur);
  v_resultat := prive.emettre_document(
    p_commande.boutique_id, p_utilisateur, p_document, 'facture', v_client, p_commande.canal, null, null, 0,
    'Commande ' || p_commande.numero, v_lignes, p_paiements);

  update public.commandes
  set document_id = p_document,
      montant_paye = (v_resultat ->> 'paye')::numeric,
      statut_paiement = (case when (v_resultat ->> 'reste')::numeric = 0 then 'paye'
                              when (v_resultat ->> 'paye')::numeric > 0 then 'partiel' else 'non_paye' end)::public.statut_paiement_commande
  where id = p_commande.id;
  return v_resultat;
end;
$$;

-- donnees : { commande_id, id (UUID du document), paiements?: [{ id?, mode_paiement_id, montant, reference? }] }
create or replace function public.generer_document_commande(p_donnees jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_commande public.commandes;
  v_utilisateur uuid;
  v_document uuid := (p_donnees ->> 'id')::uuid;
begin
  select c.* into v_commande from public.commandes c where c.id = (p_donnees ->> 'commande_id')::uuid for update;
  if not found then
    raise exception 'commande_introuvable' using errcode = 'P0001';
  end if;
  v_utilisateur := prive.exiger_permission(v_commande.boutique_id, 'commandes.gerer');
  if v_commande.document_id is not null then
    return prive.resume_document(v_commande.document_id);
  end if;
  perform prive.exiger_active(v_commande.boutique_id);
  if v_document is null or v_commande.statut in ('nouvelle', 'annulee', 'retournee') then
    raise exception 'commande_non_facturable: confirmez d''abord la commande' using errcode = 'P0001';
  end if;
  return prive.creer_document_commande(v_commande, v_utilisateur, v_document, coalesce(p_donnees -> 'paiements', '[]'::jsonb));
end;
$$;

-- ---------------------------------------------------------------------------
-- Changement de statut : règles de transition + réservation / libération / sortie de stock.
-- (le retour d'une commande livrée passe par un avoir : phase 2)
-- ---------------------------------------------------------------------------
create or replace function public.changer_statut_commande(p_commande_id uuid, p_statut public.statut_commande, p_note text default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_commande public.commandes;
  v_utilisateur uuid;
  v_permis boolean;
begin
  select c.* into v_commande from public.commandes c where c.id = p_commande_id for update;
  if not found then
    raise exception 'commande_introuvable' using errcode = 'P0001';
  end if;
  v_utilisateur := auth.uid();
  v_permis := prive.a_permission(v_commande.boutique_id, 'commandes.gerer')
    or (p_statut in ('en_preparation', 'prete') and prive.a_permission(v_commande.boutique_id, 'commandes.preparer'));
  if v_utilisateur is null or not v_permis then
    raise exception 'acces_refuse: permission commandes.gerer requise' using errcode = '42501';
  end if;
  if v_commande.statut = p_statut then
    return jsonb_build_object('id', v_commande.id, 'statut', v_commande.statut, 'rejoue', true);
  end if;
  perform prive.exiger_active(v_commande.boutique_id);

  if not ((v_commande.statut, p_statut) in (
    ('nouvelle', 'confirmee'), ('nouvelle', 'annulee'),
    ('confirmee', 'en_preparation'), ('confirmee', 'annulee'),
    ('en_preparation', 'prete'), ('en_preparation', 'annulee'),
    ('prete', 'expediee'), ('prete', 'livree'), ('prete', 'annulee'),
    ('expediee', 'livree')
  )) then
    raise exception 'transition_invalide: % → %', v_commande.statut, p_statut using errcode = 'P0001';
  end if;

  if p_statut = 'annulee' then
    if v_commande.document_id is not null then
      raise exception 'annulation_impossible: un document est déjà émis (avoir requis)' using errcode = 'P0001';
    end if;
    perform prive.liberer_reservations(v_commande, v_utilisateur);
  elsif p_statut = 'livree' and v_commande.document_id is null then
    perform prive.creer_document_commande(v_commande, v_utilisateur, gen_random_uuid(), '[]'::jsonb);
  end if;

  update public.commandes set statut = p_statut where id = v_commande.id;
  insert into public.historique_statuts_commande (boutique_id, commande_id, statut, utilisateur_id, note)
  values (v_commande.boutique_id, v_commande.id, p_statut, v_utilisateur, p_note);

  return jsonb_build_object('id', v_commande.id, 'statut', p_statut, 'rejoue', false);
end;
$$;

-- Droits d'exécution
revoke all on function public.resoudre_boutique(text) from public;
grant execute on function public.resoudre_boutique(text) to anon, authenticated, service_role;
revoke all on function public.passer_commande_en_ligne(text, jsonb) from public;
grant execute on function public.passer_commande_en_ligne(text, jsonb) to anon, authenticated, service_role;
revoke all on function public.suivre_commande(text, text, text) from public;
grant execute on function public.suivre_commande(text, text, text) to anon, authenticated, service_role;
revoke all on function public.joindre_justificatif_commande(text, uuid, text, text) from public;
grant execute on function public.joindre_justificatif_commande(text, uuid, text, text) to anon, authenticated, service_role;
revoke all on function public.generer_document_commande(jsonb) from public, anon;
grant execute on function public.generer_document_commande(jsonb) to authenticated, service_role;
revoke all on function public.changer_statut_commande(uuid, public.statut_commande, text) from public, anon;
grant execute on function public.changer_statut_commande(uuid, public.statut_commande, text) to authenticated, service_role;
