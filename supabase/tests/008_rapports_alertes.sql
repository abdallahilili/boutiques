-- Phase 2 : rapports (nets d'avoirs, marges masquées), alertes de stock, traitement des abonnements.
begin;
create extension if not exists pgtap with schema extensions;
select plan(28);

insert into auth.users (id, email) values
  ('a0000000-0000-0000-0000-00000000000a', 'owner@test.local'),
  ('c0000000-0000-0000-0000-00000000000c', 'vendeuse@test.local');
insert into public.profils (id, nom_fr, telephone) values
  ('a0000000-0000-0000-0000-00000000000a', 'Owner', '22236000001'),
  ('c0000000-0000-0000-0000-00000000000c', 'Vendeuse', '22236000003');
insert into public.commercantes (id, utilisateur_id, nom_fr, telephone)
values ('a1000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-00000000000a', 'Commerçante', '22236000001');
select public.creer_boutique_avec_defauts('a1000000-0000-0000-0000-000000000001', null, 'Boutique A', 'boutique-a',
                                          p_id => 'a2000000-0000-0000-0000-000000000001');
insert into public.plans (id, code, nom_ar, nom_fr, limites) values ('f0000000-0000-0000-0000-000000000001', 'test_illimite', 'اختبار', 'Test', '{}'::jsonb);
update public.abonnements set plan_id = 'f0000000-0000-0000-0000-000000000001';
insert into public.membres_boutique (boutique_id, utilisateur_id, role_id)
values ('a2000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-00000000000c', (select id from public.roles where boutique_id is null and cle = 'vendeuse'));

insert into public.produits (id, boutique_id, nom_ar, nom_fr) values
  ('a3000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'حقيبة', 'Sac'),
  ('a3000000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000001', 'وشاح', 'Foulard'),
  ('a3000000-0000-0000-0000-000000000003', 'a2000000-0000-0000-0000-000000000001', 'حذاء', 'Chaussure');
insert into public.variantes_produit (id, boutique_id, produit_id, prix_vente, stock_minimum) values
  ('a4000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 1000, 0),
  ('a4000000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 400, 5),
  ('a4000000-0000-0000-0000-000000000003', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000003', 800, 0);
select prive.ajouter_lot('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001', 20, 100, null, null, null, 'test', null, null);
-- Foulard : 3 en stock pour un seuil de 5 (stock bas) ; chaussure : lot qui expire dans 10 jours ; sac : sera en rupture après vente
select prive.ajouter_lot('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000002', 3, 50, null, null, null, 'test', null, null);
select prive.ajouter_lot('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000003', 4, 300, current_date + 10, null, null, 'test', null, null);
select set_config('t.especes', (select id::text from public.modes_paiement where boutique_id = 'a2000000-0000-0000-0000-000000000001' and nom_fr = 'Espèces'), true);

-- Vente de 2 sacs (2000, coût 200), avoir d'1 sac remboursé (−1000, coût −100), dépense de 100
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.enregistrer_vente(jsonb_build_object('id', 'a8000000-0000-0000-0000-000000000001', 'boutique_id', 'a2000000-0000-0000-0000-000000000001', 'type', 'ticket',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 2)),
  'paiements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 2000))));
select public.creer_avoir(jsonb_build_object('id', 'a5000000-0000-0000-0000-000000000001', 'facture_id', 'a8000000-0000-0000-0000-000000000001', 'retour_stock', true,
  'lignes', jsonb_build_array(jsonb_build_object('ligne_id', (select id from public.lignes_document_vente where document_id = 'a8000000-0000-0000-0000-000000000001'), 'quantite', 1)),
  'remboursements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 1000))));
reset role;
insert into public.depenses (boutique_id, montant, date_depense) values ('a2000000-0000-0000-0000-000000000001', 100, current_date);

set local role authenticated;
select is((public.rapport_synthese('a2000000-0000-0000-0000-000000000001', current_date, current_date) ->> 'chiffre_affaires')::numeric, 1000::numeric, 'chiffre d''affaires net de l''avoir');
select is((public.rapport_synthese('a2000000-0000-0000-0000-000000000001', current_date, current_date) ->> 'nb_ventes')::integer, 1, 'nombre de ventes (hors avoirs)');
select is((public.rapport_synthese('a2000000-0000-0000-0000-000000000001', current_date, current_date) ->> 'marge_brute')::numeric, 900::numeric, 'marge brute nette de l''avoir');
select is((public.rapport_synthese('a2000000-0000-0000-0000-000000000001', current_date, current_date) ->> 'depenses')::numeric, 100::numeric, 'dépenses de la période');
select is((public.rapport_synthese('a2000000-0000-0000-0000-000000000001', current_date, current_date) ->> 'resultat')::numeric, 800::numeric, 'résultat simplifié');
select is((public.rapport_synthese('a2000000-0000-0000-0000-000000000001', current_date, current_date) ->> 'encaisse')::numeric, 1000::numeric, 'encaissements nets des remboursements');
select is((public.rapport_synthese('a2000000-0000-0000-0000-000000000001', current_date, current_date) ->> 'valeur_stock')::numeric, (19 * 100 + 3 * 50 + 4 * 300)::numeric, 'valeur du stock aux coûts des lots');
select is((public.rapport_synthese('a2000000-0000-0000-0000-000000000001', current_date + 1, current_date + 1) ->> 'chiffre_affaires')::numeric, 0::numeric, 'période sans vente');

select is((public.rapport_ventes('a2000000-0000-0000-0000-000000000001', current_date, current_date, 'jour') -> 0 ->> 'ca')::numeric, 1000::numeric, 'ventes par jour');
select is((public.rapport_ventes('a2000000-0000-0000-0000-000000000001', current_date, current_date, 'produit') -> 0 ->> 'quantite')::numeric, 1::numeric, 'ventes par produit : quantité nette');
select is((public.rapport_ventes('a2000000-0000-0000-0000-000000000001', current_date, current_date, 'produit') -> 0 ->> 'marge')::numeric, 900::numeric, 'ventes par produit : marge');
select is((public.rapport_ventes('a2000000-0000-0000-0000-000000000001', current_date, current_date, 'mode_paiement') -> 0 ->> 'ca')::numeric, 1000::numeric, 'ventes par mode de paiement (remboursement déduit)');
select is((public.rapport_ventes('a2000000-0000-0000-0000-000000000001', current_date, current_date, 'canal') -> 0 ->> 'cle'), 'caisse', 'ventes par canal');
select is((public.rapport_ventes('a2000000-0000-0000-0000-000000000001', current_date, current_date, 'vendeuse') -> 0 ->> 'ca')::numeric, 1000::numeric, 'ventes par vendeuse');
select is((public.rapport_ventes('a2000000-0000-0000-0000-000000000001', current_date, current_date, 'categorie') -> 0 ->> 'ca')::numeric, 1000::numeric, 'ventes par catégorie');
select throws_like($$select public.rapport_ventes('a2000000-0000-0000-0000-000000000001', current_date, current_date, 'inconnu')$$, 'parametres_invalides%', 'axe inconnu refusé');
select is(jsonb_array_length(public.rapport_produits('a2000000-0000-0000-0000-000000000001', current_date, current_date, 'dormants')), 2, 'produits dormants : foulard et chaussure');
select is((public.rapport_produits('a2000000-0000-0000-0000-000000000001', current_date, current_date, 'meilleurs') -> 0 ->> 'quantite')::numeric, 1::numeric, 'meilleurs produits');
reset role;

-- La vendeuse n'a pas accès aux rapports
select set_config('request.jwt.claims', '{"sub":"c0000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
set local role authenticated;
select throws_ok($$select public.rapport_synthese('a2000000-0000-0000-0000-000000000001', current_date, current_date)$$, '42501', null, 'rapports réservés aux rôles financiers');
reset role;

-- Alertes de stock : foulard en stock bas, chaussure proche de l'expiration
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select is(jsonb_array_length(public.alertes_stock('a2000000-0000-0000-0000-000000000001') -> 'seuil_bas'), 1, 'alerte de stock bas');
select is(jsonb_array_length(public.alertes_stock('a2000000-0000-0000-0000-000000000001') -> 'expirations'), 1, 'alerte de lot proche de l''expiration');
reset role;
select set_config('request.jwt.claims', '', true);
select is((public.generer_alertes_stock() ->> 'nombre')::integer, 1, 'une notification de synthèse (propriétaire seulement)');
select is((public.generer_alertes_stock() ->> 'nombre')::integer, 0, 'pas de doublon le même jour');

-- Abonnements : J-3 → rappel ; expiré → grâce ; grâce dépassée → suspension
update public.abonnements set statut = 'actif', fin_le = current_date + 3 where boutique_id = 'a2000000-0000-0000-0000-000000000001';
select is((public.traiter_abonnements() ->> 'rappels')::integer, 1, 'rappel d''expiration à J-3');
update public.abonnements set fin_le = current_date - 1 where boutique_id = 'a2000000-0000-0000-0000-000000000001';
select is((public.traiter_abonnements() ->> 'grace')::integer, 1, 'expiration : passage en grâce');
select is((select statut from public.boutiques where id = 'a2000000-0000-0000-0000-000000000001'), 'grace'::public.statut_boutique, 'boutique en grâce (écriture encore possible)');
update public.abonnements set grace_jusqu_au = current_date - 1 where boutique_id = 'a2000000-0000-0000-0000-000000000001';
select is((public.traiter_abonnements() ->> 'suspendus')::integer, 1, 'fin de grâce : suspension');
select is((select statut from public.boutiques where id = 'a2000000-0000-0000-0000-000000000001'), 'suspendu'::public.statut_boutique, 'boutique suspendue (lecture seule)');

select * from finish();
rollback;
