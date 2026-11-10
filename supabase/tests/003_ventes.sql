-- Ventes POS : paiements multiples, FIFO, coût figé, numérotation sans doublon ni trou,
-- idempotence, crédit client, permissions de prix, plages hors ligne, session de caisse.
begin;
create extension if not exists pgtap with schema extensions;
select plan(40);

-- ---------------------------------------------------------------------------
-- Jeu de données : boutique A (propriétaire + vendeuse), 1 produit, stock de 115 (10 @100, 5 @150, 100 @200)
-- ---------------------------------------------------------------------------
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
update public.abonnements set plan_id = 'f0000000-0000-0000-0000-000000000001' where boutique_id = 'a2000000-0000-0000-0000-000000000001';
insert into public.membres_boutique (boutique_id, utilisateur_id, role_id)
values ('a2000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-00000000000c', (select id from public.roles where boutique_id is null and cle = 'vendeuse'));

insert into public.produits (id, boutique_id, nom_ar, nom_fr) values ('a3000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'حقيبة', 'Sac');
insert into public.variantes_produit (id, boutique_id, produit_id, prix_vente) values
  ('a4000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 1000);
select prive.ajouter_lot('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001', 10, 100, null, null, null, 'test', null, null);
select prive.ajouter_lot('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001', 5, 150, null, null, null, 'test', null, null);
select prive.ajouter_lot('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001', 100, 200, null, null, null, 'test', null, null);

insert into public.clients (id, boutique_id, nom_fr, plafond_credit) values
  ('a9000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'Cliente fidèle', 3000);
insert into public.appareils (id, utilisateur_id, plateforme) values ('aa000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-00000000000a', 'android');

select set_config('t.especes', (select id::text from public.modes_paiement where boutique_id = 'a2000000-0000-0000-0000-000000000001' and nom_fr = 'Espèces'), true);
select set_config('t.bankily', (select id::text from public.modes_paiement where boutique_id = 'a2000000-0000-0000-0000-000000000001' and nom_fr = 'Bankily'), true);

-- ---------------------------------------------------------------------------
-- Vente avec deux modes de paiement : lot FIFO, coût figé, facture numérotée
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-000000000001', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 12)),
  'paiements', jsonb_build_array(
    jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 6000),
    jsonb_build_object('mode_paiement_id', current_setting('t.bankily'), 'montant', 6000, 'reference', 'TX-1'))));
select is((public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-000000000001', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 12))))) ->> 'rejoue',
  'true', 'rejeu idempotent : le document existant est renvoyé');
reset role;
select set_config('request.jwt.claims', '', true);

select is((select numero from public.documents_vente where id = 'a8000000-0000-0000-0000-000000000001'),
          'FAC-' || to_char(now() at time zone 'Africa/Nouakchott', 'YYYY') || '-0001', 'première facture : FAC-AAAA-0001');
select is((select statut from public.documents_vente where id = 'a8000000-0000-0000-0000-000000000001'), 'payee'::public.statut_document_vente, 'facture payée');
select is((select total from public.documents_vente where id = 'a8000000-0000-0000-0000-000000000001'), 12000::numeric, 'total calculé par le serveur');
select is((select count(*) from public.documents_vente), 1::bigint, 'le rejeu ne crée pas de second document');
select is((select count(*) from public.paiements where document_id = 'a8000000-0000-0000-0000-000000000001'), 2::bigint, 'deux paiements enregistrés');
select is((select string_agg(quantite_restante::text, ',' order by numero_lot) from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000001'),
          '0.000,3.000,100.000', 'le bon lot FIFO est décrémenté');
select is((select cout_unitaire from public.lignes_document_vente where document_id = 'a8000000-0000-0000-0000-000000000001'),
          round((10 * 100 + 2 * 150) / 12.0, 4), 'coût moyen pondéré des lots figé sur la ligne');
select is((select count(*) from public.mouvements_stock where source_id = 'a8000000-0000-0000-0000-000000000001' and type = 'sortie_vente'), 2::bigint,
          'un mouvement de sortie par lot consommé');
select is((select sum(total) from public.lignes_document_vente where document_id = 'a8000000-0000-0000-0000-000000000001'),
          (select sous_total from public.documents_vente where id = 'a8000000-0000-0000-0000-000000000001'), 'somme des lignes = sous-total');
select is((select entete ->> 'nom_fr' from public.documents_vente where id = 'a8000000-0000-0000-0000-000000000001'), 'Boutique A', 'en-tête figé à l''émission');
update public.boutiques set nom_fr = 'Renommée' where id = 'a2000000-0000-0000-0000-000000000001';
select is((select entete ->> 'nom_fr' from public.documents_vente where id = 'a8000000-0000-0000-0000-000000000001'), 'Boutique A', 'renommer la boutique ne change pas les anciens documents');

-- ---------------------------------------------------------------------------
-- Numérotation sans trou : un échec ne consomme pas de numéro
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select throws_like($$select public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-000000000002', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 500)),
  'paiements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 500000))))$$,
  'stock_insuffisant%', 'vente refusée : stock insuffisant');
select public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-000000000003', 'boutique_id', 'a2000000-0000-0000-0000-000000000001', 'type', 'ticket',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1)),
  'paiements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 1000))));
select public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-000000000004', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1)),
  'paiements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 1000))));
reset role;
select set_config('request.jwt.claims', '', true);
select is((select numero from public.documents_vente where id = 'a8000000-0000-0000-0000-000000000004'),
          'FAC-' || to_char(now() at time zone 'Africa/Nouakchott', 'YYYY') || '-0002', 'numéro suivant sans trou après un échec');
select is((select numero from public.documents_vente where id = 'a8000000-0000-0000-0000-000000000003'),
          'TIC-' || to_char(now() at time zone 'Africa/Nouakchott', 'YYYY') || '-0001', 'séquence distincte par type de document');
select is((select count(distinct numero) from public.documents_vente), (select count(*) from public.documents_vente), 'aucun doublon de numéro');

-- ---------------------------------------------------------------------------
-- Crédit client : paiement partiel, plafond, règlement du solde
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select throws_like($$select public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-000000000005', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1)),
  'paiements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 400))))$$,
  'client_requis%', 'le crédit exige une cliente identifiée');
select throws_like($$select public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-000000000006', 'boutique_id', 'a2000000-0000-0000-0000-000000000001', 'type', 'ticket',
  'client_id', 'a9000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1)),
  'paiements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 400))))$$,
  'paiement_incomplet%', 'un ticket doit être payé en totalité');
select throws_like($$select public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-000000000007', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1)),
  'paiements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 5000))))$$,
  'paiement_excessif%', 'paiement supérieur au total refusé');
select public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-000000000008', 'boutique_id', 'a2000000-0000-0000-0000-000000000001', 'client_id', 'a9000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 2)),
  'paiements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 500))));
reset role;
select set_config('request.jwt.claims', '', true);
select is((select statut from public.documents_vente where id = 'a8000000-0000-0000-0000-000000000008'), 'partiellement_payee'::public.statut_document_vente, 'paiement partiel');
select is((select solde from public.clients where id = 'a9000000-0000-0000-0000-000000000001'), 1500::numeric, 'le reste est porté au solde de la cliente');

select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select throws_like($$select public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-000000000009', 'boutique_id', 'a2000000-0000-0000-0000-000000000001', 'client_id', 'a9000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 2))))$$,
  'plafond_credit_depasse%', 'plafond de crédit respecté');
select public.enregistrer_paiement(jsonb_build_object(
  'id', 'ab000000-0000-0000-0000-000000000001', 'document_id', 'a8000000-0000-0000-0000-000000000008',
  'mode_paiement_id', current_setting('t.bankily'), 'montant', 1500));
reset role;
select set_config('request.jwt.claims', '', true);
select is((select statut from public.documents_vente where id = 'a8000000-0000-0000-0000-000000000008'), 'payee'::public.statut_document_vente, 'règlement du solde : facture payée');
select is((select solde from public.clients where id = 'a9000000-0000-0000-0000-000000000001'), 0::numeric, 'solde cliente remis à zéro');

-- ---------------------------------------------------------------------------
-- Permissions de la vendeuse : remise oui, prix modifié non
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"c0000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
set local role authenticated;
select throws_ok($$select public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-00000000000a', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1, 'prix_unitaire', 10)),
  'paiements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 10))))$$,
  '42501', null, 'la vendeuse ne peut pas modifier un prix');
select public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-00000000000b', 'boutique_id', 'a2000000-0000-0000-0000-000000000001', 'remise', 100,
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1)),
  'paiements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 900))));
select throws_ok($$insert into public.documents_vente (id, boutique_id, type, numero, statut, sous_total, total, entete)
  values (gen_random_uuid(), 'a2000000-0000-0000-0000-000000000001', 'facture', 'FAC-X-1', 'emise', 1, 1, '{}')$$, '42501', null,
  'aucune écriture directe dans les documents');
reset role;
select set_config('request.jwt.claims', '', true);
select is((select total from public.documents_vente where id = 'a8000000-0000-0000-0000-00000000000b'), 900::numeric, 'remise globale appliquée au total');
select is((select utilisateur_id from public.documents_vente where id = 'a8000000-0000-0000-0000-00000000000b'), 'c0000000-0000-0000-0000-00000000000c'::uuid, 'vendeuse enregistrée sur le document');

-- ---------------------------------------------------------------------------
-- Plages de numéros réservées pour un appareil (ventes hors ligne)
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select is((public.reserver_plage_numeros('a2000000-0000-0000-0000-000000000001', 'facture', 'aa000000-0000-0000-0000-000000000001', 30)) ->> 'prefixe', 'FAC', 'plage de 30 numéros réservée');
select lives_ok($$select public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-00000000000c', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'appareil_id', 'aa000000-0000-0000-0000-000000000001',
  'numero', 'FAC-' || to_char(now() at time zone 'Africa/Nouakchott', 'YYYY') || '-0005',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1)),
  'paiements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 1000))))$$,
  'vente hors ligne avec un numéro de la plage réservée');
select throws_like($$select public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-00000000000d', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'appareil_id', 'aa000000-0000-0000-0000-000000000001',
  'numero', 'FAC-' || to_char(now() at time zone 'Africa/Nouakchott', 'YYYY') || '-0001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1)),
  'paiements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 1000))))$$,
  'numero_invalide%', 'un numéro hors plage est refusé');
select throws_like($$select public.reserver_plage_numeros('a2000000-0000-0000-0000-000000000001', 'facture', 'aa000000-0000-0000-0000-000000000001', 10)$$,
  'plage_non_epuisee%', 'pas de nouvelle plage tant que la réserve est importante');
select public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-00000000000e', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1)),
  'paiements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 1000))));
reset role;
select set_config('request.jwt.claims', '', true);
select is((select numero from public.documents_vente where id = 'a8000000-0000-0000-0000-00000000000e'),
          'FAC-' || to_char(now() at time zone 'Africa/Nouakchott', 'YYYY') || '-0035', 'la numérotation en ligne reprend après la plage réservée');

-- ---------------------------------------------------------------------------
-- Session de caisse : fond de caisse, espèces encaissées, écart
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.ouvrir_session_caisse('a2000000-0000-0000-0000-000000000001', 'ac000000-0000-0000-0000-000000000001', 5000);
select throws_like($$select public.ouvrir_session_caisse('a2000000-0000-0000-0000-000000000001', 'ac000000-0000-0000-0000-000000000002', 0)$$,
  'session_deja_ouverte%', 'une seule session ouverte par utilisatrice');
select public.enregistrer_vente(jsonb_build_object(
  'id', 'a8000000-0000-0000-0000-00000000000f', 'boutique_id', 'a2000000-0000-0000-0000-000000000001', 'session_caisse_id', 'ac000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 2)),
  'paiements', jsonb_build_array(
    jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 1500),
    jsonb_build_object('mode_paiement_id', current_setting('t.bankily'), 'montant', 500))));
select is((public.fermer_session_caisse('ac000000-0000-0000-0000-000000000001', 6400)) ->> 'ecart', '-100.00', 'écart = compté − attendu (5000 + 1500 espèces)');
reset role;
select set_config('request.jwt.claims', '', true);
select is((select attendu from public.sessions_caisse where id = 'ac000000-0000-0000-0000-000000000001'), 6500::numeric, 'montant attendu en caisse');

-- ---------------------------------------------------------------------------
-- Tableau de bord : chiffres financiers réservés aux rôles autorisés
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select cmp_ok((public.tableau_de_bord('a2000000-0000-0000-0000-000000000001') ->> 'ca_jour')::numeric, '>', 0::numeric, 'la propriétaire voit le chiffre d''affaires du jour');
select cmp_ok((public.tableau_de_bord('a2000000-0000-0000-0000-000000000001') ->> 'nb_ventes_jour')::int, '>=', 5, 'nombre de ventes du jour');
reset role;
select set_config('request.jwt.claims', '{"sub":"c0000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
set local role authenticated;
select is((public.tableau_de_bord('a2000000-0000-0000-0000-000000000001') -> 'ca_jour')::text, 'null', 'la vendeuse ne voit pas le chiffre d''affaires');
select is((public.tableau_de_bord('a2000000-0000-0000-0000-000000000001') -> 'impayes')::text, 'null', 'ni les impayés');
reset role;
select set_config('request.jwt.claims', '', true);

select * from finish();
rollback;
