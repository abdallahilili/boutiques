-- Icône de catégorie : choisie dans une liste prédéfinie quand la catégorie n'a pas d'image.
-- Valeur = clé de la liste (ex. « robe », « sac »), interprétée par les applications ; l'image a priorité.
alter table public.categories add column icone text check (icone ~ '^[a-z_]{1,30}$');

-- Vitrine : la colonne est ajoutée en fin de vue.
create or replace view public.categories_publiques with (security_barrier = true) as
select c.id, c.boutique_id, c.parent_id, c.nom_ar, c.nom_fr, c.image_url, c.ordre, c.icone
from public.categories c
join public.parametres_boutique_publics pb on pb.boutique_id = c.boutique_id
where c.actif and c.visible_en_ligne;
