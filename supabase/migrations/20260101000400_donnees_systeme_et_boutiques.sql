-- =============================================================================
-- Données système (permissions, rôles, plan d'essai) et fonctions de la plateforme :
-- création d'une boutique, enregistrement d'un paiement d'abonnement.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Catalogue des permissions
-- ---------------------------------------------------------------------------
insert into public.permissions (cle, module, nom_ar, nom_fr) values
  ('pos.vendre',          'pos',          'إجراء عمليات البيع',                  'Effectuer des ventes'),
  ('pos.modifier_prix',   'pos',          'تعديل الأسعار عند البيع',             'Modifier les prix en vente'),
  ('pos.remise',          'pos',          'منح تخفيضات',                         'Accorder des remises'),
  ('documents.creer',     'documents',    'إنشاء الوثائق',                       'Créer des documents'),
  ('documents.gerer',     'documents',    'إدارة الوثائق (إلغاء، تحويل)',        'Gérer les documents (annulation, conversion)'),
  ('produits.lire',       'produits',     'عرض المنتجات',                        'Consulter les produits'),
  ('produits.ecrire',     'produits',     'إنشاء المنتجات وتعديل الأسعار',       'Créer des produits et modifier les prix'),
  ('couts.voir',          'finance',      'عرض تكاليف الشراء والهوامش',          'Voir les coûts d''achat et les marges'),
  ('stock.lire',          'stock',        'عرض المخزون',                         'Consulter le stock'),
  ('stock.ecrire',        'stock',        'إدخال وإخراج وجرد المخزون',           'Entrées, sorties et inventaire du stock'),
  ('commandes.lire',      'commandes',    'عرض الطلبات',                         'Consulter les commandes'),
  ('commandes.gerer',     'commandes',    'إدارة الطلبات',                       'Gérer les commandes'),
  ('commandes.preparer',  'commandes',    'تجهيز الطلبات',                       'Préparer les commandes'),
  ('referentiels.lire',   'referentiels', 'عرض المراجع',                         'Consulter les référentiels'),
  ('referentiels.ecrire', 'referentiels', 'إدارة المراجع',                       'Gérer les référentiels'),
  ('clients.lire',        'clients',      'عرض الزبائن',                         'Consulter les clientes'),
  ('clients.ecrire',      'clients',      'إدارة الزبائن',                       'Gérer les clientes'),
  ('depenses.gerer',      'finance',      'إدارة المصاريف',                      'Gérer les dépenses'),
  ('rapports.financiers', 'finance',      'التقارير المالية',                    'Rapports financiers'),
  ('parametres.lire',     'parametres',   'عرض الإعدادات',                       'Consulter les paramètres'),
  ('parametres.gerer',    'parametres',   'إدارة إعدادات المتجر',                'Gérer les paramètres de la boutique'),
  ('employes.gerer',      'parametres',   'إدارة الموظفات',                      'Gérer les employées'),
  ('site.gerer',          'site',         'إدارة المتجر الإلكتروني',             'Gérer la boutique en ligne'),
  ('abonnement.voir',     'abonnement',   'عرض الاشتراك',                        'Consulter l''abonnement');

-- ---------------------------------------------------------------------------
-- Rôles système et matrice de permissions (§2.2 du cahier des charges)
-- ---------------------------------------------------------------------------
insert into public.roles (cle, nom_ar, nom_fr, systeme) values
  ('proprietaire', 'المالكة',       'Propriétaire', true),
  ('manager',      'المسيّرة',      'Manager',      true),
  ('vendeuse',     'البائعة',       'Vendeuse',     true),
  ('magasiniere',  'أمينة المخزن',  'Magasinière',  true);

insert into public.permissions_role (role_id, cle_permission, autorise)
select r.id, p.cle, true
from public.roles r
cross join public.permissions p
where r.boutique_id is null
  and (
    r.cle = 'proprietaire'
    or (r.cle = 'manager' and p.cle not in ('abonnement.voir', 'parametres.gerer', 'employes.gerer'))
    or (r.cle = 'vendeuse' and p.cle in (
      'pos.vendre', 'pos.remise', 'documents.creer', 'produits.lire', 'stock.lire',
      'commandes.lire', 'commandes.gerer', 'referentiels.lire', 'clients.lire', 'clients.ecrire'
    ))
    or (r.cle = 'magasiniere' and p.cle in (
      'produits.lire', 'stock.lire', 'stock.ecrire', 'commandes.lire', 'commandes.preparer', 'referentiels.lire'
    ))
  );

-- ---------------------------------------------------------------------------
-- Plan d'essai : donnée de fonctionnement (les plans payants et leurs prix sont
-- créés par l'éditeur depuis app_admin).
-- ---------------------------------------------------------------------------
insert into public.plans (code, nom_ar, nom_fr, description_ar, description_fr, limites, duree_essai_jours, ordre)
values (
  'essai', 'تجربة مجانية', 'Essai gratuit',
  'فترة تجريبية مجانية بكامل ميزات التطبيق', 'Période d''essai gratuite avec toutes les fonctions de l''application',
  '{"utilisateurs": 1, "produits": 50, "stockage_mo": 200, "boutique_en_ligne": true, "domaine_personnalise": false, "themes": 1, "rapports_avances": false}'::jsonb,
  14, 0
);

-- ---------------------------------------------------------------------------
-- Fonctions de la plateforme
-- ---------------------------------------------------------------------------

create or replace function prive.generer_code_boutique()
returns text
language plpgsql
volatile
as $$
declare
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
begin
  loop
    v_code := '';
    for i in 1..6 loop
      v_code := v_code || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from public.boutiques b where b.code_boutique = v_code);
  end loop;
  return v_code;
end;
$$;

-- Crée la boutique, la membre propriétaire et l'abonnement d'essai. Réservé au service_role
-- (appelée par admin-create-merchant ; p_id permet un rejeu idempotent). Les référentiels par défaut sont ajoutés par la
-- migration des référentiels, qui redéfinit cette fonction.
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

  insert into public.boutiques (id, commercante_id, nom_ar, nom_fr, slug, code_boutique, type_activite, telephone, devise, statut)
  values (coalesce(p_id, gen_random_uuid()), p_commercante_id, p_nom_ar, p_nom_fr, p_slug, prive.generer_code_boutique(), p_type_activite, p_telephone, p_devise, 'essai')
  returning id into v_boutique;

  insert into public.abonnements (boutique_id, plan_id, statut, debut_le, fin_le)
  values (v_boutique, v_plan.id, 'essai', current_date, current_date + coalesce(v_plan.duree_essai_jours, 14));

  insert into public.membres_boutique (boutique_id, utilisateur_id, role_id, statut)
  values (v_boutique, v_utilisateur, (select r.id from public.roles r where r.boutique_id is null and r.cle = 'proprietaire'), 'actif');

  return v_boutique;
end;
$$;
revoke all on function public.creer_boutique_avec_defauts(uuid, text, text, text, text, text, text, uuid) from public, anon, authenticated;
grant execute on function public.creer_boutique_avec_defauts(uuid, text, text, text, text, text, text, uuid) to service_role;

-- Enregistre un paiement d'abonnement (éditeur uniquement), prolonge l'abonnement et
-- réactive immédiatement la boutique (essai, grâce ou suspension).
create or replace function public.enregistrer_paiement_abonnement(
  p_abonnement_id uuid,
  p_montant numeric,
  p_mode public.mode_paiement_abonnement,
  p_reference text default null,
  p_justificatif_url text default null,
  p_periode_mois integer default 1,
  p_paye_le timestamptz default now()
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_abonnement public.abonnements;
  v_paiement uuid;
  v_base date;
begin
  if not (prive.est_admin_plateforme() or prive.est_service()) then
    raise exception 'acces_refuse: réservé à l''éditeur' using errcode = '42501';
  end if;

  select * into v_abonnement from public.abonnements where id = p_abonnement_id for update;
  if not found then
    raise exception 'abonnement_introuvable' using errcode = 'P0001';
  end if;

  insert into public.paiements_abonnement (abonnement_id, boutique_id, montant, devise, mode, reference, justificatif_url, paye_le, periode_mois, enregistre_par)
  values (
    p_abonnement_id, v_abonnement.boutique_id, p_montant,
    (select b.devise from public.boutiques b where b.id = v_abonnement.boutique_id),
    p_mode, p_reference, p_justificatif_url, p_paye_le, p_periode_mois, auth.uid()
  )
  returning id into v_paiement;

  v_base := greatest(current_date, coalesce(v_abonnement.fin_le, current_date));
  update public.abonnements
  set statut = 'actif',
      fin_le = (v_base + make_interval(months => p_periode_mois))::date,
      grace_jusqu_au = null
  where id = p_abonnement_id;

  update public.boutiques set statut = 'actif'
  where id = v_abonnement.boutique_id and statut in ('essai', 'grace', 'suspendu');

  return v_paiement;
end;
$$;
revoke all on function public.enregistrer_paiement_abonnement(uuid, numeric, public.mode_paiement_abonnement, text, text, integer, timestamptz) from public, anon;
grant execute on function public.enregistrer_paiement_abonnement(uuid, numeric, public.mode_paiement_abonnement, text, text, integer, timestamptz) to authenticated, service_role;
