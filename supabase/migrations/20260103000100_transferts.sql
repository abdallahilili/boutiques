-- =============================================================================
-- Phase 2 — Transferts de stock entre commerçantes (deux boutiques de la plateforme).
-- L'émettrice envoie (sortie de stock FIFO/FEFO immédiate, transfert « en attente ») ; la destinataire
-- accepte (réception + lots au prix de transfert, prix de vente propres, correspondance ou création
-- des produits) ou refuse (le stock revient à l'émettrice). Écritures uniquement par fonctions
-- SECURITY DEFINER : c'est la seule opération qui touche deux boutiques.
-- Suivi financier : à l'acceptation, la destinataire est portée comme cliente de l'émettrice
-- (solde dû) et l'émettrice comme fournisseur de la destinataire. Le coût d'achat de l'émettrice
-- n'est jamais visible de la destinataire (il reste dans ses mouvements de stock).
-- =============================================================================

create type public.statut_transfert as enum ('en_attente', 'accepte', 'refuse', 'annule');

create table public.transferts (
  id uuid primary key default gen_random_uuid(),
  numero text not null,
  boutique_emettrice_id uuid not null references public.boutiques (id) on delete cascade,
  boutique_destinataire_id uuid not null references public.boutiques (id) on delete cascade,
  statut public.statut_transfert not null default 'en_attente',
  note text,
  total numeric(14, 2) not null default 0 check (total >= 0),
  envoye_par uuid references public.profils (id),
  repondu_par uuid references public.profils (id),
  reception_id uuid,
  cree_le timestamptz not null default now(),
  repondu_le timestamptz,
  constraint transferts_boutiques_differentes check (boutique_emettrice_id <> boutique_destinataire_id),
  unique (boutique_emettrice_id, numero)
);
create index transferts_emettrice_idx on public.transferts (boutique_emettrice_id, cree_le desc);
create index transferts_destinataire_idx on public.transferts (boutique_destinataire_id, cree_le desc);

create table public.lignes_transfert (
  id uuid primary key default gen_random_uuid(),
  transfert_id uuid not null references public.transferts (id) on delete cascade,
  variante_emettrice_id uuid not null references public.variantes_produit (id),
  variante_destinataire_id uuid references public.variantes_produit (id),
  libelle_ar text,
  libelle_fr text,
  quantite numeric(14, 3) not null check (quantite > 0),
  prix_unitaire numeric(14, 2) not null check (prix_unitaire >= 0),
  total numeric(14, 2) not null check (total >= 0),
  ordre integer not null default 0
);
create index lignes_transfert_idx on public.lignes_transfert (transfert_id);

-- Lecture : les deux boutiques concernées. Aucune écriture cliente.
alter table public.transferts enable row level security;
alter table public.lignes_transfert enable row level security;
revoke insert, update, delete on public.transferts, public.lignes_transfert from authenticated;
create policy lecture_transferts on public.transferts for select to authenticated
  using (boutique_emettrice_id = any ((select prive.boutiques_avec_permission('stock.lire'))::uuid[])
         or boutique_destinataire_id = any ((select prive.boutiques_avec_permission('stock.lire'))::uuid[]));
create policy lecture_lignes_transfert on public.lignes_transfert for select to authenticated
  using (transfert_id in (select t.id from public.transferts t));

-- Liens vers l'autre boutique : cliente côté émettrice, fournisseur côté destinataire.
alter table public.clients add column boutique_liee_id uuid references public.boutiques (id) on delete set null;
alter table public.fournisseurs add column boutique_liee_id uuid references public.boutiques (id) on delete set null;
create unique index clients_boutique_liee_idx on public.clients (boutique_id, boutique_liee_id) where boutique_liee_id is not null;
create unique index fournisseurs_boutique_liee_idx on public.fournisseurs (boutique_id, boutique_liee_id) where boutique_liee_id is not null;

-- Utilisatrices d'une boutique disposant d'une permission (destinataires des notifications).
create or replace function prive.utilisatrices_avec_permission(p_boutique uuid, p_cle text)
returns setof uuid
language sql
stable
security definer
set search_path = public
as $$
  select distinct m.utilisateur_id
  from public.membres_boutique m
  join public.permissions_role pr on pr.role_id = m.role_id and pr.cle_permission = p_cle and pr.autorise
  where m.boutique_id = p_boutique and m.statut = 'actif';
$$;

create or replace function prive.notifier_boutique(
  p_boutique uuid, p_permission text, p_type text, p_titre_ar text, p_titre_fr text, p_corps_ar text, p_corps_fr text,
  p_donnees jsonb, p_auteur uuid
)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.notifications (boutique_id, utilisateur_id, type, titre_ar, titre_fr, corps_ar, corps_fr, cible, donnees, cree_par)
  select p_boutique, u, p_type, p_titre_ar, p_titre_fr, p_corps_ar, p_corps_fr, 'boutique', p_donnees, p_auteur
  from prive.utilisatrices_avec_permission(p_boutique, p_permission) u;
$$;

create or replace function prive.nom_boutique(p_boutique uuid, p_langue text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select case when p_langue = 'ar' then coalesce(b.nom_ar, b.nom_fr) else coalesce(b.nom_fr, b.nom_ar) end
  from public.boutiques b where b.id = p_boutique;
$$;

-- Remet en stock (émettrice) les quantités sorties par un transfert, au coût exact de la sortie.
create or replace function prive.restituer_stock_transfert(p_transfert public.transferts, p_utilisateur uuid, p_note text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mouvement record;
begin
  for v_mouvement in
    select m.variante_id, -m.quantite as quantite, coalesce(m.cout_unitaire, 0) as cout
    from public.mouvements_stock m
    where m.boutique_id = p_transfert.boutique_emettrice_id and m.source_type = 'transfert' and m.source_id = p_transfert.id
      and m.type = 'transfert_sortie'
    order by m.variante_id, m.cree_le
  loop
    perform prive.ajouter_lot(p_transfert.boutique_emettrice_id, v_mouvement.variante_id, v_mouvement.quantite, v_mouvement.cout, null,
                              null, null, 'transfert', p_transfert.id, p_utilisateur, 'transfert_entree', p_note);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Envoi
-- donnees : { id, boutique_id, destinataire: { code_boutique? | telephone? }, note?,
--             lignes: [{ variante_id, quantite, prix_unitaire? }] }
-- ---------------------------------------------------------------------------
create or replace function public.envoyer_transfert(p_donnees jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid := (p_donnees ->> 'id')::uuid;
  v_boutique uuid := (p_donnees ->> 'boutique_id')::uuid;
  v_utilisateur uuid;
  v_code text := upper(trim(coalesce(p_donnees #>> '{destinataire,code_boutique}', '')));
  v_tel text := prive.normaliser_telephone(p_donnees #>> '{destinataire,telephone}');
  v_destinataire public.boutiques;
  v_element record;
  v_variante public.variantes_produit;
  v_prix numeric;
  v_quantite numeric;
  v_total numeric := 0;
  v_numero text;
begin
  v_utilisateur := prive.exiger_permission(v_boutique, 'stock.ecrire');
  if v_id is null then
    raise exception 'identifiant_requis' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.transferts t where t.id = v_id) then
    if not exists (select 1 from public.transferts t where t.id = v_id and t.boutique_emettrice_id = v_boutique) then
      raise exception 'acces_refuse' using errcode = '42501';
    end if;
    return (select jsonb_build_object('id', t.id, 'numero', t.numero, 'statut', t.statut, 'total', t.total, 'rejoue', true)
            from public.transferts t where t.id = v_id);
  end if;
  perform prive.exiger_active(v_boutique);

  select * into v_destinataire from public.boutiques b
  where b.id <> v_boutique and b.statut in ('essai', 'actif', 'grace')
    and ((v_code <> '' and b.code_boutique = v_code) or (v_code = '' and v_tel is not null and v_tel <> '' and b.telephone = v_tel));
  if not found then
    raise exception 'destinataire_introuvable' using errcode = 'P0001';
  end if;
  if jsonb_typeof(p_donnees -> 'lignes') is distinct from 'array' or jsonb_array_length(p_donnees -> 'lignes') not between 1 and 200 then
    raise exception 'lignes_invalides' using errcode = 'P0001';
  end if;

  v_numero := prive.prochain_numero(v_boutique, 'transfert');
  insert into public.transferts (id, numero, boutique_emettrice_id, boutique_destinataire_id, note, envoye_par)
  values (v_id, v_numero, v_boutique, v_destinataire.id, nullif(p_donnees ->> 'note', ''), v_utilisateur);

  for v_element in
    select e.elem, e.ord from jsonb_array_elements(p_donnees -> 'lignes') with ordinality as e(elem, ord)
    order by (e.elem ->> 'variante_id'), e.ord
  loop
    v_quantite := (v_element.elem ->> 'quantite')::numeric;
    if v_quantite is null or v_quantite <= 0 then
      raise exception 'ligne_invalide' using errcode = 'P0001';
    end if;
    select * into v_variante from public.variantes_produit v
    where v.id = (v_element.elem ->> 'variante_id')::uuid and v.boutique_id = v_boutique and v.supprime_le is null and v.actif;
    if not found then
      raise exception 'variante_introuvable' using errcode = 'P0001';
    end if;
    v_prix := coalesce((v_element.elem ->> 'prix_unitaire')::numeric, coalesce(v_variante.prix_gros, prive.prix_effectif(v_variante)));
    if v_prix < 0 then
      raise exception 'ligne_invalide: prix' using errcode = 'P0001';
    end if;
    perform prive.consommer_stock(v_boutique, v_variante.id, v_quantite, 'transfert_sortie', 'transfert', v_id, v_utilisateur);
    insert into public.lignes_transfert (transfert_id, variante_emettrice_id, libelle_ar, libelle_fr, quantite, prix_unitaire, total, ordre)
    values (v_id, v_variante.id, prive.libelle_variante(v_variante.id, 'ar'), prive.libelle_variante(v_variante.id, 'fr'),
            v_quantite, v_prix, round(v_quantite * v_prix, 2), v_element.ord::integer);
    v_total := v_total + round(v_quantite * v_prix, 2);
  end loop;
  update public.transferts set total = v_total where id = v_id;

  perform prive.notifier_boutique(
    v_destinataire.id, 'stock.ecrire', 'transfert',
    'تحويل مخزون وارد', 'Transfert de stock reçu',
    prive.nom_boutique(v_boutique, 'ar') || ' — ' || v_numero, prive.nom_boutique(v_boutique, 'fr') || ' — ' || v_numero,
    jsonb_build_object('transfert_id', v_id, 'statut', 'en_attente'), v_utilisateur);

  return jsonb_build_object('id', v_id, 'numero', v_numero, 'statut', 'en_attente', 'total', v_total,
                            'destinataire_id', v_destinataire.id, 'rejoue', false);
end;
$$;

-- ---------------------------------------------------------------------------
-- Réponse de la destinataire
-- donnees : { transfert_id, decision: 'accepter' | 'refuser',
--             correspondances: [{ ligne_id, variante_id? , creer?: boolean, prix_vente? }] }
-- ---------------------------------------------------------------------------
create or replace function public.repondre_transfert(p_donnees jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_transfert public.transferts;
  v_utilisateur uuid;
  v_decision text := p_donnees ->> 'decision';
  v_ligne record;
  v_corr jsonb;
  v_variante uuid;
  v_prix_vente numeric;
  v_produit uuid;
  v_fournisseur uuid;
  v_client uuid;
  v_reception uuid := gen_random_uuid();
  v_ligne_reception uuid;
begin
  if v_decision not in ('accepter', 'refuser') then
    raise exception 'parametres_invalides' using errcode = 'P0001';
  end if;
  select * into v_transfert from public.transferts t where t.id = (p_donnees ->> 'transfert_id')::uuid for update;
  if not found then
    raise exception 'transfert_introuvable' using errcode = 'P0001';
  end if;
  v_utilisateur := prive.exiger_permission(v_transfert.boutique_destinataire_id, 'stock.ecrire');
  if v_transfert.statut <> 'en_attente' then
    if v_transfert.statut = (case v_decision when 'accepter' then 'accepte' else 'refuse' end)::public.statut_transfert then
      return jsonb_build_object('id', v_transfert.id, 'statut', v_transfert.statut, 'rejoue', true);
    end if;
    raise exception 'transfert_deja_traite: %', v_transfert.statut using errcode = 'P0001';
  end if;
  perform prive.exiger_active(v_transfert.boutique_destinataire_id);

  if v_decision = 'refuser' then
    perform prive.restituer_stock_transfert(v_transfert, v_utilisateur, 'transfert refusé ' || v_transfert.numero);
    update public.transferts set statut = 'refuse', repondu_par = v_utilisateur, repondu_le = now() where id = v_transfert.id;
  else
    -- Fournisseur (côté destinataire) et cliente (côté émettrice) liés à l'autre boutique.
    select f.id into v_fournisseur from public.fournisseurs f
    where f.boutique_id = v_transfert.boutique_destinataire_id and f.boutique_liee_id = v_transfert.boutique_emettrice_id;
    if v_fournisseur is null then
      insert into public.fournisseurs (boutique_id, nom_ar, nom_fr, boutique_liee_id, cree_par)
      values (v_transfert.boutique_destinataire_id, prive.nom_boutique(v_transfert.boutique_emettrice_id, 'ar'),
              prive.nom_boutique(v_transfert.boutique_emettrice_id, 'fr'), v_transfert.boutique_emettrice_id, v_utilisateur)
      returning id into v_fournisseur;
    end if;
    select c.id into v_client from public.clients c
    where c.boutique_id = v_transfert.boutique_emettrice_id and c.boutique_liee_id = v_transfert.boutique_destinataire_id;
    if v_client is null then
      insert into public.clients (boutique_id, nom_ar, nom_fr, boutique_liee_id)
      values (v_transfert.boutique_emettrice_id, prive.nom_boutique(v_transfert.boutique_destinataire_id, 'ar'),
              prive.nom_boutique(v_transfert.boutique_destinataire_id, 'fr'), v_transfert.boutique_destinataire_id)
      returning id into v_client;
    end if;

    insert into public.receptions_stock (id, boutique_id, fournisseur_id, transfert_id, reference, total, montant_paye, notes, utilisateur_id)
    values (v_reception, v_transfert.boutique_destinataire_id, v_fournisseur, v_transfert.id, v_transfert.numero, v_transfert.total, 0,
            v_transfert.note, v_utilisateur);

    for v_ligne in select * from public.lignes_transfert l where l.transfert_id = v_transfert.id order by l.ordre loop
      v_corr := null;
      select c into v_corr from jsonb_array_elements(coalesce(p_donnees -> 'correspondances', '[]'::jsonb)) c
      where (c ->> 'ligne_id')::uuid = v_ligne.id limit 1;
      if v_corr is null then
        raise exception 'correspondance_requise: ligne %', v_ligne.id using errcode = 'P0001';
      end if;
      v_prix_vente := (v_corr ->> 'prix_vente')::numeric;
      if coalesce((v_corr ->> 'creer')::boolean, false) then
        if v_prix_vente is null or v_prix_vente < 0 then
          raise exception 'prix_vente_requis: ligne %', v_ligne.id using errcode = 'P0001';
        end if;
        insert into public.produits (boutique_id, nom_ar, nom_fr, cree_par)
        values (v_transfert.boutique_destinataire_id, v_ligne.libelle_ar, v_ligne.libelle_fr, v_utilisateur)
        returning id into v_produit;
        insert into public.variantes_produit (boutique_id, produit_id, prix_vente, cree_par)
        values (v_transfert.boutique_destinataire_id, v_produit, v_prix_vente, v_utilisateur)
        returning id into v_variante;
      else
        v_variante := (v_corr ->> 'variante_id')::uuid;
        if v_variante is null or not exists (
          select 1 from public.variantes_produit v
          where v.id = v_variante and v.boutique_id = v_transfert.boutique_destinataire_id and v.supprime_le is null
        ) then
          raise exception 'variante_introuvable: ligne %', v_ligne.id using errcode = 'P0001';
        end if;
      end if;

      v_ligne_reception := gen_random_uuid();
      insert into public.lignes_reception_stock (id, boutique_id, reception_id, variante_id, quantite, cout_unitaire, prix_vente)
      values (v_ligne_reception, v_transfert.boutique_destinataire_id, v_reception, v_variante, v_ligne.quantite, v_ligne.prix_unitaire, v_prix_vente);
      perform prive.ajouter_lot(v_transfert.boutique_destinataire_id, v_variante, v_ligne.quantite, v_ligne.prix_unitaire, null,
                                v_ligne_reception, v_fournisseur, 'reception_stock', v_reception, v_utilisateur, 'transfert_entree');
      if v_prix_vente is not null and not coalesce((v_corr ->> 'creer')::boolean, false) then
        update public.variantes_produit set prix_vente = v_prix_vente,
               prix_promo = case when prix_promo > v_prix_vente then null else prix_promo end
        where id = v_variante;
      end if;
      update public.lignes_transfert set variante_destinataire_id = v_variante where id = v_ligne.id;
    end loop;

    update public.fournisseurs set solde = solde + v_transfert.total where id = v_fournisseur;
    update public.clients set solde = solde + v_transfert.total where id = v_client;
    update public.transferts set statut = 'accepte', repondu_par = v_utilisateur, repondu_le = now(), reception_id = v_reception
    where id = v_transfert.id;
  end if;

  perform prive.notifier_boutique(
    v_transfert.boutique_emettrice_id, 'stock.ecrire', 'transfert',
    case when v_decision = 'accepter' then 'تم قبول التحويل' else 'تم رفض التحويل' end,
    case when v_decision = 'accepter' then 'Transfert accepté' else 'Transfert refusé' end,
    prive.nom_boutique(v_transfert.boutique_destinataire_id, 'ar') || ' — ' || v_transfert.numero,
    prive.nom_boutique(v_transfert.boutique_destinataire_id, 'fr') || ' — ' || v_transfert.numero,
    jsonb_build_object('transfert_id', v_transfert.id, 'statut', case when v_decision = 'accepter' then 'accepte' else 'refuse' end),
    v_utilisateur);

  return jsonb_build_object('id', v_transfert.id, 'statut', case when v_decision = 'accepter' then 'accepte' else 'refuse' end, 'rejoue', false);
end;
$$;

-- L'émettrice peut annuler tant que la destinataire n'a pas répondu (le stock revient).
create or replace function public.annuler_transfert(p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_transfert public.transferts;
  v_utilisateur uuid;
begin
  select * into v_transfert from public.transferts t where t.id = p_id for update;
  if not found then
    raise exception 'transfert_introuvable' using errcode = 'P0001';
  end if;
  v_utilisateur := prive.exiger_permission(v_transfert.boutique_emettrice_id, 'stock.ecrire');
  if v_transfert.statut = 'annule' then
    return jsonb_build_object('id', p_id, 'statut', 'annule', 'rejoue', true);
  end if;
  if v_transfert.statut <> 'en_attente' then
    raise exception 'transfert_deja_traite: %', v_transfert.statut using errcode = 'P0001';
  end if;
  perform prive.restituer_stock_transfert(v_transfert, v_utilisateur, 'transfert annulé ' || v_transfert.numero);
  update public.transferts set statut = 'annule', repondu_par = v_utilisateur, repondu_le = now() where id = p_id;
  return jsonb_build_object('id', p_id, 'statut', 'annule', 'rejoue', false);
end;
$$;

do $$
declare
  f text;
begin
  foreach f in array array['envoyer_transfert(jsonb)', 'repondre_transfert(jsonb)', 'annuler_transfert(uuid)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated, service_role', f);
  end loop;
end;
$$;
