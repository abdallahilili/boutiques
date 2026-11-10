-- =============================================================================
-- Phase 2 — Hors ligne complet : dépenses et clientes créables hors ligne (RPC idempotentes rejouées depuis
-- l'outbox de l'application), alerte et validation des écarts de stock (stock négatif après synchronisation).
-- =============================================================================

-- Dépense : identifiant fourni par l'appareil, rejeu sans effet.
-- donnees : { id, boutique_id, categorie_id?, montant, date_depense?, motif?, mode_paiement_id? }
create or replace function public.enregistrer_depense(p_donnees jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_boutique uuid := (p_donnees ->> 'boutique_id')::uuid;
  v_id uuid := (p_donnees ->> 'id')::uuid;
  v_utilisateur uuid;
  v_montant numeric := (p_donnees ->> 'montant')::numeric;
begin
  v_utilisateur := prive.exiger_permission(v_boutique, 'depenses.gerer');
  if v_id is null then
    raise exception 'identifiant_requis' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.depenses d where d.id = v_id) then
    if not exists (select 1 from public.depenses d where d.id = v_id and d.boutique_id = v_boutique) then
      raise exception 'acces_refuse' using errcode = '42501';
    end if;
    return jsonb_build_object('id', v_id, 'rejoue', true);
  end if;
  perform prive.exiger_active(v_boutique);
  if v_montant is null or v_montant <= 0 then
    raise exception 'parametres_invalides: montant' using errcode = 'P0001';
  end if;
  insert into public.depenses (id, boutique_id, categorie_id, montant, date_depense, motif, mode_paiement_id, utilisateur_id)
  values (v_id, v_boutique, nullif(p_donnees ->> 'categorie_id', '')::uuid, v_montant,
          coalesce((p_donnees ->> 'date_depense')::date, current_date), nullif(p_donnees ->> 'motif', ''),
          nullif(p_donnees ->> 'mode_paiement_id', '')::uuid, v_utilisateur);
  return jsonb_build_object('id', v_id, 'rejoue', false);
end;
$$;

-- Cliente : création ou mise à jour par identifiant (le solde n'est jamais modifiable ici).
-- donnees : { id, boutique_id, nom_ar?, nom_fr?, telephone?, whatsapp?, adresse?, ville?, plafond_credit?, notes? }
create or replace function public.enregistrer_client(p_donnees jsonb)
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
  v_utilisateur := prive.exiger_permission(v_boutique, 'clients.ecrire');
  if v_id is null then
    raise exception 'identifiant_requis' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.clients c where c.id = v_id) then
    if not exists (select 1 from public.clients c where c.id = v_id and c.boutique_id = v_boutique) then
      raise exception 'acces_refuse' using errcode = '42501';
    end if;
    perform prive.exiger_active(v_boutique);
    update public.clients
    set nom_ar = nullif(p_donnees ->> 'nom_ar', ''), nom_fr = nullif(p_donnees ->> 'nom_fr', ''),
        telephone = nullif(p_donnees ->> 'telephone', ''), whatsapp = nullif(p_donnees ->> 'whatsapp', ''),
        adresse = nullif(p_donnees ->> 'adresse', ''), ville = nullif(p_donnees ->> 'ville', ''),
        plafond_credit = (p_donnees ->> 'plafond_credit')::numeric, notes = nullif(p_donnees ->> 'notes', '')
    where id = v_id;
    return jsonb_build_object('id', v_id, 'cree', false);
  end if;
  perform prive.exiger_active(v_boutique);
  insert into public.clients (id, boutique_id, nom_ar, nom_fr, telephone, whatsapp, adresse, ville, plafond_credit, notes, cree_par)
  values (v_id, v_boutique, nullif(p_donnees ->> 'nom_ar', ''), nullif(p_donnees ->> 'nom_fr', ''), nullif(p_donnees ->> 'telephone', ''),
          nullif(p_donnees ->> 'whatsapp', ''), nullif(p_donnees ->> 'adresse', ''), nullif(p_donnees ->> 'ville', ''),
          (p_donnees ->> 'plafond_credit')::numeric, nullif(p_donnees ->> 'notes', ''), v_utilisateur);
  return jsonb_build_object('id', v_id, 'cree', true);
end;
$$;

-- ---------------------------------------------------------------------------
-- Écarts de stock : une vente synchronisée après coup peut rendre le stock négatif (lot « découvert »).
-- Une notification est créée ; la commerçante valide l'écart (le stock est remis à zéro par un mouvement tracé).
-- ---------------------------------------------------------------------------
create or replace function prive.trg_alerte_ecart_stock()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ids uuid[];
begin
  if new.decouvert and new.quantite_restante < 0
     and (tg_op = 'INSERT' or old.quantite_restante >= 0 or new.quantite_restante < old.quantite_restante) then
    v_ids := prive.notifier_boutique_ids(
      new.boutique_id, 'stock.ecrire', 'ecart_stock', 'فرق في المخزون', 'Écart de stock à valider',
      prive.libelle_variante(new.variante_id, 'ar') || ' : ' || new.quantite_restante::text,
      prive.libelle_variante(new.variante_id, 'fr') || ' : ' || new.quantite_restante::text,
      jsonb_build_object('variante_id', new.variante_id, 'quantite', new.quantite_restante));
  end if;
  return null;
end;
$$;
create trigger alerte_ecart_stock after insert or update of quantite_restante on public.lots_stock
  for each row when (new.decouvert) execute function prive.trg_alerte_ecart_stock();

create or replace function public.ecarts_stock(p_boutique uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform prive.exiger_permission(p_boutique, 'stock.lire');
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
             'variante_id', l.variante_id, 'libelle_ar', prive.libelle_variante(l.variante_id, 'ar'),
             'libelle_fr', prive.libelle_variante(l.variante_id, 'fr'), 'quantite', l.quantite_restante) order by l.quantite_restante), '[]'::jsonb)
    from public.lots_stock l
    where l.boutique_id = p_boutique and l.decouvert and l.quantite_restante < 0
  );
end;
$$;

-- Validation : mouvement d'ajustement positif qui ramène le découvert à zéro (historique conservé).
create or replace function public.valider_ecart_stock(p_boutique uuid, p_variante uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_utilisateur uuid;
  v_lot public.lots_stock;
begin
  v_utilisateur := prive.exiger_permission(p_boutique, 'stock.ecrire');
  perform prive.exiger_active(p_boutique);
  select * into v_lot from public.lots_stock l
  where l.boutique_id = p_boutique and l.variante_id = p_variante and l.decouvert and l.quantite_restante < 0 for update;
  if not found then
    return jsonb_build_object('variante_id', p_variante, 'valide', false);
  end if;
  insert into public.mouvements_stock (boutique_id, variante_id, lot_id, type, quantite, cout_unitaire, source_type, utilisateur_id, note)
  values (p_boutique, p_variante, v_lot.id, 'ajustement', -v_lot.quantite_restante, v_lot.cout_unitaire, 'ecart_valide', v_utilisateur, 'écart de stock validé');
  update public.lots_stock set quantite_restante = 0 where id = v_lot.id;
  return jsonb_build_object('variante_id', p_variante, 'valide', true, 'regularise', -v_lot.quantite_restante);
end;
$$;

do $$
declare
  f text;
begin
  foreach f in array array['enregistrer_depense(jsonb)', 'enregistrer_client(jsonb)', 'ecarts_stock(uuid)', 'valider_ecart_stock(uuid, uuid)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated, service_role', f);
  end loop;
end;
$$;
