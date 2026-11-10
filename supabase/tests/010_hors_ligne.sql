-- Phase 2 : hors ligne complet (dépenses et clientes idempotentes, écarts de stock).
begin;
create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users (id, email) values
  ('a0000000-0000-0000-0000-00000000000a', 'owner@test.local'),
  ('c0000000-0000-0000-0000-00000000000c', 'vendeuse@test.local'),
  ('e0000000-0000-0000-0000-00000000000e', 'autre@test.local');
insert into public.profils (id, nom_fr, telephone) values
  ('a0000000-0000-0000-0000-00000000000a', 'Owner', '22236000001'),
  ('c0000000-0000-0000-0000-00000000000c', 'Vendeuse', '22236000003'),
  ('e0000000-0000-0000-0000-00000000000e', 'Autre', '22236000009');
insert into public.commercantes (id, utilisateur_id, nom_fr, telephone) values
  ('a1000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-00000000000a', 'Commerçante', '22236000001'),
  ('e1000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-00000000000e', 'Autre', '22236000009');
select public.creer_boutique_avec_defauts('a1000000-0000-0000-0000-000000000001', null, 'Boutique A', 'boutique-a', p_id => 'a2000000-0000-0000-0000-000000000001');
select public.creer_boutique_avec_defauts('e1000000-0000-0000-0000-000000000001', null, 'Boutique E', 'boutique-e', p_id => 'e2000000-0000-0000-0000-000000000001');
insert into public.plans (id, code, nom_ar, nom_fr, limites) values ('f0000000-0000-0000-0000-000000000001', 'test_illimite', 'اختبار', 'Test', '{}'::jsonb);
update public.abonnements set plan_id = 'f0000000-0000-0000-0000-000000000001';
insert into public.membres_boutique (boutique_id, utilisateur_id, role_id)
values ('a2000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-00000000000c', (select id from public.roles where boutique_id is null and cle = 'vendeuse'));

select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;

-- Dépense idempotente
select public.enregistrer_depense(jsonb_build_object('id', 'd1000000-0000-0000-0000-000000000001', 'boutique_id', 'a2000000-0000-0000-0000-000000000001', 'montant', 250, 'motif', 'Transport'));
select is((public.enregistrer_depense(jsonb_build_object('id', 'd1000000-0000-0000-0000-000000000001', 'boutique_id', 'a2000000-0000-0000-0000-000000000001', 'montant', 250))) ->> 'rejoue', 'true', 'dépense : rejeu idempotent');
select is((select count(*)::integer from public.depenses), 1, 'une seule dépense enregistrée');
select throws_like($$select public.enregistrer_depense(jsonb_build_object('id', 'd1000000-0000-0000-0000-000000000002', 'boutique_id', 'a2000000-0000-0000-0000-000000000001', 'montant', 0))$$, 'parametres_invalides%', 'montant positif exigé');
select throws_ok($$select public.enregistrer_depense(jsonb_build_object('id', 'd1000000-0000-0000-0000-000000000001', 'boutique_id', 'e2000000-0000-0000-0000-000000000001', 'montant', 250))$$, '42501', null, 'identifiant d''une autre boutique refusé');

-- Cliente : création puis mise à jour (le solde n'est jamais écrasé)
select public.enregistrer_client(jsonb_build_object('id', 'a9000000-0000-0000-0000-000000000001', 'boutique_id', 'a2000000-0000-0000-0000-000000000001', 'nom_fr', 'Cliente hors ligne', 'telephone', '36000044'));
select is((select nom_fr from public.clients where id = 'a9000000-0000-0000-0000-000000000001'), 'Cliente hors ligne', 'cliente créée avec l''identifiant de l''appareil');
update public.clients set solde = 500 where id = 'a9000000-0000-0000-0000-000000000001' and false;
select is((public.enregistrer_client(jsonb_build_object('id', 'a9000000-0000-0000-0000-000000000001', 'boutique_id', 'a2000000-0000-0000-0000-000000000001', 'nom_fr', 'Cliente renommée'))) ->> 'cree', 'false', 'rejeu : mise à jour, pas de doublon');
select is((select nom_fr from public.clients where id = 'a9000000-0000-0000-0000-000000000001'), 'Cliente renommée', 'cliente mise à jour');
reset role;

-- La vendeuse n'a pas depenses.gerer
select set_config('request.jwt.claims', '{"sub":"c0000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
set local role authenticated;
select throws_ok($$select public.enregistrer_depense(jsonb_build_object('id', 'd1000000-0000-0000-0000-000000000003', 'boutique_id', 'a2000000-0000-0000-0000-000000000001', 'montant', 10))$$, '42501', null, 'dépense : permission depenses.gerer requise');
reset role;

-- Écart de stock : vente hors ligne synchronisée sans stock (stock négatif autorisé)
update public.boutiques set parametres = parametres || '{"stock_negatif_autorise": true}'::jsonb where id = 'a2000000-0000-0000-0000-000000000001';
insert into public.produits (id, boutique_id, nom_fr) values ('a3000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'Sac');
insert into public.variantes_produit (id, boutique_id, produit_id, prix_vente) values ('a4000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 1000);
select prive.ajouter_lot('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001', 1, 100, null, null, null, 'test', null, null);
select set_config('t.especes', (select id::text from public.modes_paiement where boutique_id = 'a2000000-0000-0000-0000-000000000001' and nom_fr = 'Espèces'), true);
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.enregistrer_vente(jsonb_build_object('id', 'a8000000-0000-0000-0000-000000000001', 'boutique_id', 'a2000000-0000-0000-0000-000000000001', 'type', 'ticket',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 3)),
  'paiements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 3000))));
select is(jsonb_array_length(public.ecarts_stock('a2000000-0000-0000-0000-000000000001')), 1, 'écart de stock listé');
select is((public.ecarts_stock('a2000000-0000-0000-0000-000000000001') -> 0 ->> 'quantite')::numeric, -2::numeric, 'quantité manquante : −2');
reset role;
select is((select count(*)::integer from public.notifications where type = 'ecart_stock' and utilisateur_id = 'a0000000-0000-0000-0000-00000000000a'), 1, 'notification d''écart à la propriétaire');
set local role authenticated;
select is((public.valider_ecart_stock('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001') ->> 'valide'), 'true', 'écart validé');
select is(jsonb_array_length(public.ecarts_stock('a2000000-0000-0000-0000-000000000001')), 0, 'plus d''écart après validation');
reset role;

select * from finish();
rollback;
