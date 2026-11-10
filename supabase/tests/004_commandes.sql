-- Commandes en ligne : prix et stock revérifiés côté serveur, réservation, anti-spam, suivi,
-- transitions de statut, facture issue d'une commande, vues publiques.
begin;
create extension if not exists pgtap with schema extensions;
select plan(48);

-- ---------------------------------------------------------------------------
-- Jeu de données : boutique A (propriétaire + magasinière), 1 cliente avec compte, catalogue
-- ---------------------------------------------------------------------------
insert into auth.users (id, email) values
  ('a0000000-0000-0000-0000-00000000000a', 'owner@test.local'),
  ('d0000000-0000-0000-0000-00000000000d', 'magasiniere@test.local'),
  ('e0000000-0000-0000-0000-00000000000e', 'cliente@test.local');
insert into public.profils (id, nom_fr, telephone) values
  ('a0000000-0000-0000-0000-00000000000a', 'Owner', '22236000001'),
  ('d0000000-0000-0000-0000-00000000000d', 'Magasinière', '22236000004');
insert into public.commercantes (id, utilisateur_id, nom_fr, telephone)
values ('a1000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-00000000000a', 'Commerçante', '22236000001');
select public.creer_boutique_avec_defauts('a1000000-0000-0000-0000-000000000001', null, 'Boutique A', 'boutique-a',
                                          p_id => 'a2000000-0000-0000-0000-000000000001');
insert into public.plans (id, code, nom_ar, nom_fr, limites) values ('f0000000-0000-0000-0000-000000000001', 'test_illimite', 'اختبار', 'Test', '{}'::jsonb);
update public.abonnements set plan_id = 'f0000000-0000-0000-0000-000000000001' where boutique_id = 'a2000000-0000-0000-0000-000000000001';
insert into public.membres_boutique (boutique_id, utilisateur_id, role_id)
values ('a2000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-00000000000d', (select id from public.roles where boutique_id is null and cle = 'magasiniere'));
insert into public.comptes_clientes_site (id, boutique_id, utilisateur_id, nom, telephone)
values ('ae000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-00000000000e', 'Cliente Web', '22236000009');

insert into public.produits (id, boutique_id, nom_ar, nom_fr, epingle, ordre_epinglage, categorie_id) values
  ('a3000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'ملحفة', 'Melhafa', true, 1,
   (select id from public.categories where boutique_id = 'a2000000-0000-0000-0000-000000000001' and nom_fr = 'Sacs')),
  ('a3000000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000001', 'مخفي', 'Produit caché', false, null, null);
update public.produits set visible_en_ligne = false where id = 'a3000000-0000-0000-0000-000000000002';
insert into public.variantes_produit (id, boutique_id, produit_id, prix_vente, prix_promo) values
  ('a4000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 1000, 800),
  ('a4000000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 500, null);
select prive.ajouter_lot('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001', 10, 100, null, null, null, 'test', null, null);
select prive.ajouter_lot('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000002', 10, 100, null, null, null, 'test', null, null);
insert into public.zones_livraison (id, boutique_id, nom_fr, frais) values ('a9000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'Centre-ville', 200);

-- ---------------------------------------------------------------------------
-- Vues publiques (visiteuse anonyme)
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;
select is((select count(*) from public.produits_publics), 1::bigint, 'seuls les produits visibles en ligne sont publics');
select is((select prix_min from public.produits_publics where slug is not null limit 1), 800::numeric, 'prix public = prix promotionnel actif');
select is((select epingle from public.produits_publics limit 1), true, 'les produits épinglés sont exposés (tri côté boutique)');
select is((select count(*) from public.variantes_publiques), 1::bigint, 'variantes des seuls produits visibles');
select is((select stock_visible from public.variantes_publiques limit 1), 10::numeric, 'stock affiché si la boutique le souhaite');
select throws_ok($$select * from public.produits$$, '42501', null, 'tables métier inaccessibles à la visiteuse');
select throws_ok($$select * from public.lots_stock$$, '42501', null, 'lots (coûts) inaccessibles à la visiteuse');
select is((public.resoudre_boutique('boutique-a.plateforme.com')) ->> 'slug', 'boutique-a', 'résolution de la boutique par sous-domaine');
select is(public.resoudre_boutique('inconnue.plateforme.com'), null, 'sous-domaine inconnu');

-- ---------------------------------------------------------------------------
-- Commande anonyme : prix serveur, réservation, idempotence
-- ---------------------------------------------------------------------------
select public.passer_commande_en_ligne('boutique-a', jsonb_build_object(
  'id', 'b1000000-0000-0000-0000-000000000001', 'nom_client', 'Fatima', 'telephone', '36 00 00 77', 'adresse', 'Tevragh Zeina',
  'zone_id', 'a9000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 2, 'prix_unitaire', 1))));
select is((public.passer_commande_en_ligne('boutique-a', jsonb_build_object(
  'id', 'b1000000-0000-0000-0000-000000000001', 'nom_client', 'Fatima', 'telephone', '36 00 00 77', 'adresse', 'x',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 2))))) ->> 'rejoue', 'true',
  'rejeu idempotent de la commande');
select throws_like($$select public.passer_commande_en_ligne('boutique-a', jsonb_build_object(
  'id', 'b1000000-0000-0000-0000-000000000002', 'nom_client', 'Robot', 'telephone', '36000088', 'adresse', 'x', 'miel', 'spam',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1))))$$,
  'requete_invalide%', 'champ piège anti-robot');
select throws_like($$select public.passer_commande_en_ligne('boutique-a', jsonb_build_object(
  'id', 'b1000000-0000-0000-0000-000000000003', 'nom_client', 'Aïcha', 'telephone', '36000099', 'adresse', 'x',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 9))))$$,
  'stock_insuffisant%', 'stock vérifié côté serveur (réservations déduites)');
select throws_like($$select public.passer_commande_en_ligne('boutique-a', jsonb_build_object(
  'id', 'b1000000-0000-0000-0000-000000000004', 'nom_client', 'Aïcha', 'telephone', '36000099', 'adresse', 'x',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000002', 'quantite', 1))))$$,
  'produit_indisponible%', 'produit masqué : commande refusée');
select throws_like($$select public.passer_commande_en_ligne('boutique-a', jsonb_build_object(
  'id', 'b1000000-0000-0000-0000-000000000005', 'nom_client', 'Aïcha', 'telephone', '36000099', 'mode_livraison', 'livraison',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1))))$$,
  'adresse_requise%', 'adresse obligatoire pour une livraison');
-- Limitation de débit : 5 commandes par heure et par numéro
select public.passer_commande_en_ligne('boutique-a', jsonb_build_object(
  'id', 'b1000000-0000-0000-0000-00000000000' || i, 'nom_client', 'Spam', 'telephone', '36000055', 'mode_livraison', 'retrait',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1))))
from generate_series(6, 9) as i;
select public.passer_commande_en_ligne('boutique-a', jsonb_build_object(
  'id', 'b1000000-0000-0000-0000-000000000010', 'nom_client', 'Spam', 'telephone', '36000055', 'mode_livraison', 'retrait',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1))));
select throws_like($$select public.passer_commande_en_ligne('boutique-a', jsonb_build_object(
  'id', 'b1000000-0000-0000-0000-000000000011', 'nom_client', 'Spam', 'telephone', '36000055', 'mode_livraison', 'retrait',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1))))$$,
  'trop_de_requetes%', 'limitation de débit sur la RPC publique');
select throws_ok($$select * from public.commandes$$, '42501', null, 'la visiteuse ne lit pas les commandes');

-- Suivi sans compte
select throws_like($$select public.suivre_commande('boutique-a', 'CMD-0000-0001', '36000077')$$, 'commande_introuvable%', 'numéro inconnu');
select is((public.suivre_commande('boutique-a', (select 'CMD-' || to_char(now(), 'YYYY') || '-0001'), '22236000077')) ->> 'statut', 'nouvelle', 'suivi par numéro + téléphone');
select throws_like($$select public.suivre_commande('boutique-a', 'CMD-' || to_char(now(), 'YYYY') || '-0001', '36000000')$$, 'commande_introuvable%', 'mauvais téléphone : même erreur');
-- Suivi par téléphone seul : liste des commandes de ce numéro dans cette boutique
select cmp_ok(jsonb_array_length(public.suivre_commandes_par_telephone('boutique-a', '36000077')), '>=', 1, 'suivi par téléphone seul : commandes retournées');
select is(public.suivre_commandes_par_telephone('boutique-a', '36000099'), '[]'::jsonb, 'téléphone sans commande : liste vide');
select is(public.suivre_commandes_par_telephone('boutique-inexistante', '36000077'), '[]'::jsonb, 'autre boutique : rien');
reset role;
select set_config('request.jwt.claims', '', true);

select is((select total from public.commandes where id = 'b1000000-0000-0000-0000-000000000001'), 1800::numeric, 'total = promo 800 × 2 + livraison 200 (prix du navigateur ignoré)');
select is((select numero from public.commandes where id = 'b1000000-0000-0000-0000-000000000001'),
          'CMD-' || to_char(now() at time zone 'Africa/Nouakchott', 'YYYY') || '-0001', 'numéro de commande');
select is((select sum(quantite_restante) from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000001'), 10::numeric, 'le stock physique n''est pas modifié à la création');
select is(prive.quantite_reservee('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001'), 7::numeric, 'stock réservé (2 + 5 × 1)');
select cmp_ok((select count(*) from public.notifications where type = 'commande_nouvelle'), '>=', 2::bigint, 'notification in-app aux membres');

-- ---------------------------------------------------------------------------
-- Gestion par la boutique : transitions, libération, facture
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select is((select count(*) from public.commandes where id = 'b1000000-0000-0000-0000-000000000001'), 1::bigint, 'la propriétaire voit la commande');
select throws_like($$select public.changer_statut_commande('b1000000-0000-0000-0000-000000000001', 'prete')$$, 'transition_invalide%', 'transition interdite');
select public.changer_statut_commande('b1000000-0000-0000-0000-000000000001', 'confirmee');
select throws_like($$select public.generer_document_commande(jsonb_build_object('commande_id', 'b1000000-0000-0000-0000-000000000006', 'id', gen_random_uuid()))$$,
  'commande_non_facturable%', 'facturation impossible avant confirmation');
select public.changer_statut_commande('b1000000-0000-0000-0000-000000000006', 'annulee');
reset role;
select set_config('request.jwt.claims', '', true);
select is(prive.quantite_reservee('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001'), 6::numeric, 'l''annulation libère la réservation');

select set_config('request.jwt.claims', '{"sub":"d0000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
set local role authenticated;
select lives_ok($$select public.changer_statut_commande('b1000000-0000-0000-0000-000000000001', 'en_preparation')$$, 'la magasinière prépare la commande');
select throws_ok($$select public.changer_statut_commande('b1000000-0000-0000-0000-000000000007', 'confirmee')$$, '42501', null, 'la magasinière ne confirme pas');
reset role;
select set_config('request.jwt.claims', '', true);

select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.generer_document_commande(jsonb_build_object('commande_id', 'b1000000-0000-0000-0000-000000000001', 'id', 'b2000000-0000-0000-0000-000000000001'));
select is((public.generer_document_commande(jsonb_build_object('commande_id', 'b1000000-0000-0000-0000-000000000001', 'id', gen_random_uuid()))) ->> 'rejoue',
  'true', 'génération de facture idempotente');
select throws_like($$select public.changer_statut_commande('b1000000-0000-0000-0000-000000000001', 'annulee')$$, 'annulation_impossible%', 'annulation impossible après facturation');
reset role;
select set_config('request.jwt.claims', '', true);

select is((select total from public.documents_vente where id = 'b2000000-0000-0000-0000-000000000001'), 1800::numeric, 'facture = total de la commande (frais de livraison inclus)');
select is((select sum(quantite_restante) from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000001'), 8::numeric, 'la facture sort le stock (FIFO)');
select is(prive.quantite_reservee('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001'), 4::numeric, 'la réservation de la commande facturée est consommée');
select is((select solde from public.clients where telephone = '22236000077'), 1800::numeric, 'cliente créée depuis la commande, impayé porté au solde');
select is((select document_id from public.commandes where id = 'b1000000-0000-0000-0000-000000000001'), 'b2000000-0000-0000-0000-000000000001'::uuid, 'document lié à la commande');

-- Livraison sans facture préalable : facture générée automatiquement
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.changer_statut_commande('b1000000-0000-0000-0000-000000000007', 'confirmee');
select public.changer_statut_commande('b1000000-0000-0000-0000-000000000007', 'en_preparation');
select public.changer_statut_commande('b1000000-0000-0000-0000-000000000007', 'prete');
select public.changer_statut_commande('b1000000-0000-0000-0000-000000000007', 'livree');
reset role;
select set_config('request.jwt.claims', '', true);
select isnt((select document_id from public.commandes where id = 'b1000000-0000-0000-0000-000000000007'), null, 'marquer livrée génère la facture et sort le stock');

-- ---------------------------------------------------------------------------
-- Cliente connectée : ses commandes uniquement
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"e0000000-0000-0000-0000-00000000000e","role":"authenticated"}', true);
set local role authenticated;
select public.passer_commande_en_ligne('boutique-a', jsonb_build_object(
  'id', 'b1000000-0000-0000-0000-000000000020', 'nom_client', 'Cliente Web', 'telephone', '36000009', 'mode_livraison', 'retrait',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1))));
select is((select count(*) from public.commandes), 1::bigint, 'la cliente connectée ne voit que sa commande');
select is((select count(*) from public.lignes_commande), 1::bigint, 'et ses lignes uniquement');
select is((select count(*) from public.clients), 0::bigint, 'jamais les données de la boutique');
reset role;
select set_config('request.jwt.claims', '', true);
select is((select compte_client_id from public.commandes where id = 'b1000000-0000-0000-0000-000000000020'), 'ae000000-0000-0000-0000-000000000001'::uuid, 'commande rattachée au compte de la cliente');

-- ---------------------------------------------------------------------------
-- Boutique suspendue : page indisponible, aucune commande
-- ---------------------------------------------------------------------------
update public.boutiques set statut = 'suspendu' where id = 'a2000000-0000-0000-0000-000000000001';
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;
select throws_like($$select public.passer_commande_en_ligne('boutique-a', jsonb_build_object(
  'id', 'b1000000-0000-0000-0000-000000000030', 'nom_client', 'Aïcha', 'telephone', '36000066', 'mode_livraison', 'retrait',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1))))$$,
  'boutique_indisponible%', 'boutique suspendue : commande impossible');
select is((public.resoudre_boutique('boutique-a.plateforme.com')) ->> 'disponible', 'false', 'résolution : boutique marquée indisponible (page de maintenance)');
select is((select count(*) from public.produits_publics), 0::bigint, 'catalogue masqué pour une boutique suspendue');
reset role;

select * from finish();
rollback;
