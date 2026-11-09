-- La boutique en ligne a besoin de la configuration par défaut du thème actif (mise en page).
create or replace view public.parametres_boutique_publics with (security_barrier = true) as
select b.id as boutique_id, b.slug, b.nom_ar, b.nom_fr, b.logo_url, b.devise, b.langue_par_defaut,
       b.telephone, b.whatsapp, b.adresse, b.ville,
       ps.theme_id, t.code as theme_code, ps.config_theme, ps.favicon_url, ps.liens_sociaux, ps.referencement,
       ps.infos_paiement, ps.horaires, ps.commande_minimale, ps.livraison_active, ps.retrait_boutique_actif,
       ps.paiement_livraison_actif, ps.mobile_money_actif, ps.afficher_stock, ps.masquer_epuises,
       ps.message_confirmation_ar, ps.message_confirmation_fr, ps.langues_activees,
       t.schema_config as theme_schema
from public.boutiques b
join public.parametres_site ps on ps.boutique_id = b.id and ps.publie
left join public.themes_site t on t.id = ps.theme_id
where b.statut in ('essai', 'actif', 'grace');

grant select on public.parametres_boutique_publics to anon, authenticated;
