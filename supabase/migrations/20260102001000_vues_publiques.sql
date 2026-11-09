-- =============================================================================
-- Vues publiques de la boutique en ligne (lecture anonyme) : seules les boutiques actives dont
-- le site est publié sont visibles ; jamais de coûts ni de stock exact (sauf si la boutique l'affiche).
-- Les vues appartiennent à postgres : le filtrage est explicite et aucune écriture n'est possible.
-- =============================================================================

create view public.parametres_boutique_publics with (security_barrier = true) as
select b.id as boutique_id, b.slug, b.nom_ar, b.nom_fr, b.logo_url, b.devise, b.langue_par_defaut,
       b.telephone, b.whatsapp, b.adresse, b.ville,
       ps.theme_id, t.code as theme_code, ps.config_theme, ps.favicon_url, ps.liens_sociaux, ps.referencement,
       ps.infos_paiement, ps.horaires, ps.commande_minimale, ps.livraison_active, ps.retrait_boutique_actif,
       ps.paiement_livraison_actif, ps.mobile_money_actif, ps.afficher_stock, ps.masquer_epuises,
       ps.message_confirmation_ar, ps.message_confirmation_fr, ps.langues_activees
from public.boutiques b
join public.parametres_site ps on ps.boutique_id = b.id and ps.publie
left join public.themes_site t on t.id = ps.theme_id
where b.statut in ('essai', 'actif', 'grace');

create view public.categories_publiques with (security_barrier = true) as
select c.id, c.boutique_id, c.parent_id, c.nom_ar, c.nom_fr, c.image_url, c.ordre
from public.categories c
join public.parametres_boutique_publics pb on pb.boutique_id = c.boutique_id
where c.actif and c.visible_en_ligne;

create view public.couleurs_publiques with (security_barrier = true) as
select c.id, c.boutique_id, c.nom_ar, c.nom_fr, c.code_hex, c.ordre
from public.couleurs c
join public.parametres_boutique_publics pb on pb.boutique_id = c.boutique_id
where c.actif;

create view public.modeles_publics with (security_barrier = true) as
select m.id, m.boutique_id, m.categorie_id, m.nom_ar, m.nom_fr
from public.modeles m
join public.parametres_boutique_publics pb on pb.boutique_id = m.boutique_id
where m.actif;

-- Variantes vendables : prix effectif (promo active), disponibilité sans révéler le stock exact.
create view public.variantes_publiques with (security_barrier = true) as
select v.id, v.boutique_id, v.produit_id, v.modele_id, v.couleur_id, v.taille_id,
       prive.prix_effectif(v) as prix,
       v.prix_vente as prix_normal,
       prive.prix_effectif(v) < v.prix_vente as en_promo,
       v.image_url,
       m.nom_ar as modele_nom_ar, m.nom_fr as modele_nom_fr,
       c.nom_ar as couleur_nom_ar, c.nom_fr as couleur_nom_fr, c.code_hex as couleur_hex,
       t.nom_ar as taille_nom_ar, t.nom_fr as taille_nom_fr,
       d.disponible <= 0 as epuisee,
       case when pb.afficher_stock then greatest(d.disponible, 0) end as stock_visible
from public.variantes_produit v
join public.produits p on p.id = v.produit_id and p.statut = 'actif' and p.visible_en_ligne and p.supprime_le is null
join public.parametres_boutique_publics pb on pb.boutique_id = v.boutique_id
left join public.modeles m on m.id = v.modele_id
left join public.couleurs c on c.id = v.couleur_id
left join public.tailles t on t.id = v.taille_id
cross join lateral (
  select coalesce((select sum(l.quantite_restante) from public.lots_stock l where l.variante_id = v.id), 0)
         - prive.quantite_reservee(v.boutique_id, v.id) as disponible
) d
where v.actif and v.supprime_le is null and not (pb.masquer_epuises and d.disponible <= 0);

-- Produits visibles : épinglés en tête (epingle, ordre_epinglage), puis ordre des catégories, puis ordre du produit.
create view public.produits_publics with (security_barrier = true) as
select p.id, p.boutique_id, p.slug, p.nom_ar, p.nom_fr, p.description_ar, p.description_fr,
       p.categorie_id, cat.ordre as categorie_ordre, p.marque_id, p.epingle, p.ordre_epinglage, p.ordre, p.etiquettes, p.cree_le,
       agg.prix_min, agg.prix_normal_min, agg.en_promo, agg.epuise,
       (select i.url from public.images_produit i where i.produit_id = p.id order by i.principale desc, i.ordre limit 1) as image_url
from public.produits p
join public.parametres_boutique_publics pb on pb.boutique_id = p.boutique_id
left join public.categories cat on cat.id = p.categorie_id
cross join lateral (
  select min(vp.prix) as prix_min, min(vp.prix_normal) as prix_normal_min,
         coalesce(bool_or(vp.en_promo), false) as en_promo, coalesce(bool_and(vp.epuisee), true) as epuise
  from public.variantes_publiques vp where vp.produit_id = p.id
) agg
where p.statut = 'actif' and p.visible_en_ligne and p.supprime_le is null and agg.prix_min is not null;

create view public.images_publiques with (security_barrier = true) as
select i.id, i.boutique_id, i.produit_id, i.variante_id, i.url, i.principale, i.ordre
from public.images_produit i
join public.produits_publics pp on pp.id = i.produit_id;

create view public.zones_livraison_publiques with (security_barrier = true) as
select z.id, z.boutique_id, z.nom_ar, z.nom_fr, z.frais, z.delai_jours
from public.zones_livraison z
join public.parametres_boutique_publics pb on pb.boutique_id = z.boutique_id
where z.actif;

create view public.sections_site_publiques with (security_barrier = true) as
select s.id, s.boutique_id, s.type, s.titre_ar, s.titre_fr, s.contenu_ar, s.contenu_fr, s.config, s.ordre
from public.sections_site s
join public.parametres_boutique_publics pb on pb.boutique_id = s.boutique_id
where s.visible;

create view public.pages_site_publiques with (security_barrier = true) as
select g.id, g.boutique_id, g.slug, g.titre_ar, g.titre_fr, g.contenu_ar, g.contenu_fr, g.ordre
from public.pages_site g
join public.parametres_boutique_publics pb on pb.boutique_id = g.boutique_id
where g.visible;

create view public.bannieres_site_publiques with (security_barrier = true) as
select b.id, b.boutique_id, b.image_url, b.titre_ar, b.titre_fr, b.lien, b.ordre
from public.bannieres_site b
join public.parametres_boutique_publics pb on pb.boutique_id = b.boutique_id
where b.actif;

do $$
declare
  v text;
begin
  foreach v in array array[
    'parametres_boutique_publics', 'categories_publiques', 'couleurs_publiques', 'modeles_publics', 'variantes_publiques',
    'produits_publics', 'images_publiques', 'zones_livraison_publiques', 'sections_site_publiques',
    'pages_site_publiques', 'bannieres_site_publiques'
  ] loop
    execute format('revoke all on public.%I from public, anon, authenticated', v);
    execute format('grant select on public.%I to anon, authenticated', v);
  end loop;
end;
$$;
