-- =============================================================================
-- Création d'une boutique avec ses données de départ (catégories, couleurs, modes de paiement,
-- unités, motifs, domaine, site) + statistiques de la console éditeur.
-- =============================================================================

-- Sous-domaine libre : tient compte des sous-domaines déjà attribués (modifiables par l'éditeur).
create or replace function prive.slug_disponible(p_base text)
returns text
language plpgsql
stable
as $$
declare
  v_base text := prive.slugifier(p_base);
  v_candidat text;
  v_i integer := 1;
begin
  if length(v_base) < 3 or v_base = any (prive.slugs_reserves()) then
    v_base := left('boutique-' || v_base, 38);
  end if;
  v_candidat := v_base;
  while exists (select 1 from public.boutiques b where b.slug = v_candidat)
        or exists (select 1 from public.domaines_boutique d where d.sous_domaine = v_candidat) loop
    v_i := v_i + 1;
    v_candidat := left(v_base, 38 - length(v_i::text) - 1) || '-' || v_i;
  end loop;
  return v_candidat;
end;
$$;

create or replace function prive.initialiser_boutique(p_boutique uuid, p_slug text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.boutiques
  set parametres = parametres || '{"stock_negatif_autorise": false, "seuil_stock_defaut": 2, "decimales": 0}'::jsonb
  where id = p_boutique;

  insert into public.categories (boutique_id, nom_ar, nom_fr, ordre) values
    (p_boutique, 'حقائب', 'Sacs', 1),
    (p_boutique, 'إكسسوارات', 'Accessoires', 2),
    (p_boutique, 'مكياج', 'Maquillage', 3),
    (p_boutique, 'ملاحف', 'Voiles (melhafas)', 4);

  insert into public.couleurs (boutique_id, nom_ar, nom_fr, code_hex, ordre) values
    (p_boutique, 'أسود', 'Noir', '#000000', 1),
    (p_boutique, 'أبيض', 'Blanc', '#FFFFFF', 2),
    (p_boutique, 'أحمر', 'Rouge', '#E53935', 3),
    (p_boutique, 'أزرق', 'Bleu', '#1E88E5', 4),
    (p_boutique, 'أخضر', 'Vert', '#43A047', 5),
    (p_boutique, 'أصفر', 'Jaune', '#FDD835', 6),
    (p_boutique, 'وردي', 'Rose', '#EC407A', 7),
    (p_boutique, 'بنفسجي', 'Violet', '#8E24AA', 8),
    (p_boutique, 'بني', 'Marron', '#6D4C41', 9),
    (p_boutique, 'بيج', 'Beige', '#D7C4A3', 10),
    (p_boutique, 'رمادي', 'Gris', '#9E9E9E', 11),
    (p_boutique, 'برتقالي', 'Orange', '#FB8C00', 12),
    (p_boutique, 'ذهبي', 'Doré', '#D4AF37', 13),
    (p_boutique, 'فضي', 'Argenté', '#C0C0C0', 14);

  insert into public.modes_paiement (boutique_id, nom_ar, nom_fr, type, icone, par_defaut, ordre) values
    (p_boutique, 'نقداً', 'Espèces', 'especes', 'cash', true, 1),
    (p_boutique, 'بنكيلي', 'Bankily', 'mobile_money', 'phone', false, 2),
    (p_boutique, 'مصرفي', 'Masrvi', 'mobile_money', 'phone', false, 3),
    (p_boutique, 'سداد', 'Sedad', 'mobile_money', 'phone', false, 4),
    (p_boutique, 'بطاقة', 'Carte', 'carte', 'card', false, 5),
    (p_boutique, 'آجل (دين)', 'Crédit (à recevoir)', 'credit', 'credit', false, 6);

  insert into public.unites (boutique_id, nom_ar, nom_fr, abreviation) values
    (p_boutique, 'قطعة', 'Pièce', 'pce'),
    (p_boutique, 'زوج', 'Paire', 'pr'),
    (p_boutique, 'متر', 'Mètre', 'm'),
    (p_boutique, 'علبة', 'Boîte', 'bte');

  insert into public.motifs_mouvement (boutique_id, code, nom_ar, nom_fr) values
    (p_boutique, 'casse', 'كسر', 'Casse'),
    (p_boutique, 'perte', 'فقدان', 'Perte'),
    (p_boutique, 'vol', 'سرقة', 'Vol'),
    (p_boutique, 'cadeau', 'هدية', 'Cadeau'),
    (p_boutique, 'usage_interne', 'استعمال داخلي', 'Usage interne'),
    (p_boutique, 'retour_fournisseur', 'إرجاع للمورد', 'Retour fournisseur'),
    (p_boutique, 'inventaire', 'جرد', 'Inventaire');

  insert into public.categories_depenses (boutique_id, nom_ar, nom_fr) values
    (p_boutique, 'إيجار', 'Loyer'),
    (p_boutique, 'نقل', 'Transport'),
    (p_boutique, 'رواتب', 'Salaires'),
    (p_boutique, 'كهرباء وماء', 'Électricité et eau'),
    (p_boutique, 'أخرى', 'Autres');

  insert into public.domaines_boutique (boutique_id, sous_domaine) values (p_boutique, p_slug);
  insert into public.parametres_site (boutique_id, theme_id)
  values (p_boutique, (select t.id from public.themes_site t where t.code = 'classique'));
end;
$$;

-- Version complète : boutique, abonnement d'essai, membre propriétaire, référentiels et site par défaut.
create or replace function public.creer_boutique_avec_defauts(
  p_commercante_id uuid,
  p_nom_ar text,
  p_nom_fr text,
  p_slug text,
  p_type_activite text default null,
  p_telephone text default null,
  p_devise text default 'MRU',
  p_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_boutique uuid;
  v_utilisateur uuid;
  v_plan public.plans;
begin
  select c.utilisateur_id into v_utilisateur from public.commercantes c where c.id = p_commercante_id;
  if v_utilisateur is null then
    raise exception 'commercante_introuvable' using errcode = 'P0001';
  end if;
  select * into v_plan from public.plans where code = 'essai';

  insert into public.boutiques (id, commercante_id, nom_ar, nom_fr, slug, code_boutique, type_activite, telephone, whatsapp, devise, statut)
  values (coalesce(p_id, gen_random_uuid()), p_commercante_id, p_nom_ar, p_nom_fr, p_slug, prive.generer_code_boutique(),
          p_type_activite, p_telephone, p_telephone, p_devise, 'essai')
  returning id into v_boutique;

  insert into public.abonnements (boutique_id, plan_id, statut, debut_le, fin_le)
  values (v_boutique, v_plan.id, 'essai', current_date, current_date + coalesce(v_plan.duree_essai_jours, 14));

  insert into public.membres_boutique (boutique_id, utilisateur_id, role_id, statut)
  values (v_boutique, v_utilisateur, (select r.id from public.roles r where r.boutique_id is null and r.cle = 'proprietaire'), 'actif');

  perform prive.initialiser_boutique(v_boutique, p_slug);
  return v_boutique;
end;
$$;
revoke all on function public.creer_boutique_avec_defauts(uuid, text, text, text, text, text, text, uuid) from public, anon, authenticated;
grant execute on function public.creer_boutique_avec_defauts(uuid, text, text, text, text, text, text, uuid) to service_role;

-- ---------------------------------------------------------------------------
-- Tableau de bord de la console éditeur
-- ---------------------------------------------------------------------------
create or replace function public.admin_statistiques()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not prive.est_admin_plateforme() then
    raise exception 'acces_refuse: réservé à l''éditeur' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'boutiques', (select coalesce(jsonb_object_agg(s.statut, s.nb), '{}'::jsonb)
                  from (select b.statut, count(*) as nb from public.boutiques b group by b.statut) s),
    'mrr', (select coalesce(sum(greatest(p.prix_mensuel - a.remise, 0)), 0)
            from public.abonnements a join public.plans p on p.id = a.plan_id where a.statut = 'actif'),
    'nouvelles_inscriptions_mois', (select count(*) from public.boutiques b where b.cree_le >= date_trunc('month', now())),
    'expirent_sous_7_jours', (select count(*) from public.abonnements a
                              where a.statut in ('essai', 'actif') and a.fin_le between current_date and current_date + 7),
    'commandes_en_ligne_30j', (select count(*) from public.commandes c where c.cree_le >= now() - interval '30 days'),
    'evolution', (select coalesce(jsonb_agg(jsonb_build_object('mois', to_char(m.mois, 'YYYY-MM'),
                    'boutiques', (select count(*) from public.boutiques b where date_trunc('month', b.cree_le) = m.mois),
                    'commandes', (select count(*) from public.commandes c where date_trunc('month', c.cree_le) = m.mois))
                  order by m.mois), '[]'::jsonb)
                  from (select generate_series(date_trunc('month', now()) - interval '5 months', date_trunc('month', now()), interval '1 month') as mois) m)
  );
end;
$$;
revoke all on function public.admin_statistiques() from public, anon;
grant execute on function public.admin_statistiques() to authenticated, service_role;
