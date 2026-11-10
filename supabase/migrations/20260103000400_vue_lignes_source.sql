-- La vue des lignes (sans coûts pour les rôles sans « couts.voir ») expose aussi la ligne d'origine d'un
-- avoir, pour calculer côté application les quantités déjà avoirées.
create or replace view public.lignes_document_vente_vue with (security_barrier = true) as
select l.id, l.boutique_id, l.document_id, l.variante_id, l.libelle_ar, l.libelle_fr, l.quantite,
       l.prix_unitaire, l.remise, l.total, l.ordre,
       case when l.boutique_id = any (prive.boutiques_avec_permission('couts.voir')) then l.cout_unitaire end as cout_unitaire,
       l.ligne_source_id
from public.lignes_document_vente l
where l.boutique_id = any (prive.boutiques_avec_permission('documents.creer'));
