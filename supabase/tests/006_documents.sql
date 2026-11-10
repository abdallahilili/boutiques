-- Phase 2 : devis, bons de livraison, conversions, avoirs, annulations.
begin;
create extension if not exists pgtap with schema extensions;
select plan(35);

-- ---------------------------------------------------------------------------
-- Jeu de données : boutique A (propriétaire + vendeuse), 1 variante à 1000, 50 en stock à 100
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
select prive.ajouter_lot('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001', 50, 100, null, null, null, 'test', null, null);
insert into public.clients (id, boutique_id, nom_fr, plafond_credit) values
  ('a9000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'Cliente fidèle', 20000);
select set_config('t.especes', (select id::text from public.modes_paiement where boutique_id = 'a2000000-0000-0000-0000-000000000001' and nom_fr = 'Espèces'), true);

create or replace function pg_temp.stock() returns numeric language sql security definer as $$
  select coalesce(sum(quantite_restante), 0) from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000001'
$$;
grant execute on function pg_temp.stock() to authenticated;

select set_config('request.jwt.claims', '{"sub":"c0000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
set local role authenticated;

-- Devis créé par la vendeuse (documents.creer) : brouillon, aucun impact sur le stock
select public.creer_devis(jsonb_build_object(
  'id', 'd1000000-0000-0000-0000-000000000001', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'client_id', 'a9000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 3))));
select is((select numero from public.documents_vente where id = 'd1000000-0000-0000-0000-000000000001'),
          'DEV-' || to_char(now() at time zone 'Africa/Nouakchott', 'YYYY') || '-0001', 'devis numéroté DEV-AAAA-0001');
select is((select statut from public.documents_vente where id = 'd1000000-0000-0000-0000-000000000001'), 'brouillon'::public.statut_document_vente, 'devis en brouillon');
select is((select total from public.documents_vente where id = 'd1000000-0000-0000-0000-000000000001'), 3000::numeric, 'total calculé par le serveur');
select is(pg_temp.stock(), 50::numeric, 'un devis ne touche pas au stock');
select is((public.creer_devis(jsonb_build_object(
  'id', 'd1000000-0000-0000-0000-000000000001', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 3))))) ->> 'rejoue',
  'true', 'création de devis idempotente');
select throws_ok($$select public.convertir_document(jsonb_build_object('id', 'b1000000-0000-0000-0000-000000000099',
  'source_id', 'd1000000-0000-0000-0000-000000000001', 'type_cible', 'bon_livraison'))$$, '42501', null, 'la vendeuse ne convertit pas (documents.gerer)');
select public.changer_statut_devis('d1000000-0000-0000-0000-000000000001', 'envoye');
select public.changer_statut_devis('d1000000-0000-0000-0000-000000000001', 'accepte');
select throws_like($$select public.changer_statut_devis('d1000000-0000-0000-0000-000000000001', 'envoye')$$, 'transition_invalide%', 'un devis accepté ne revient pas à envoyé');
reset role;

-- ---------------------------------------------------------------------------
-- Propriétaire : devis → BL → validation (stock) → facture
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.convertir_document(jsonb_build_object('id', 'b1000000-0000-0000-0000-000000000001',
  'source_id', 'd1000000-0000-0000-0000-000000000001', 'type_cible', 'bon_livraison'));
select is((select numero from public.documents_vente where id = 'b1000000-0000-0000-0000-000000000001'),
          'BL-' || to_char(now() at time zone 'Africa/Nouakchott', 'YYYY') || '-0001', 'BL numéroté BL-AAAA-0001');
select is((select total from public.documents_vente where id = 'b1000000-0000-0000-0000-000000000001'), 3000::numeric, 'lignes reprises du devis');
select is(pg_temp.stock(), 50::numeric, 'BL brouillon : pas de sortie de stock');
select throws_like($$select public.convertir_document(jsonb_build_object('id', 'b1000000-0000-0000-0000-000000000098',
  'source_id', 'd1000000-0000-0000-0000-000000000001', 'type_cible', 'facture'))$$, 'deja_converti%', 'un devis converti ne se convertit pas deux fois');
select throws_like($$select public.convertir_document(jsonb_build_object('id', 'f1000000-0000-0000-0000-000000000098',
  'source_id', 'b1000000-0000-0000-0000-000000000001', 'type_cible', 'facture'))$$, 'bl_non_valide%', 'un BL brouillon ne se facture pas');
select public.changer_statut_bon_livraison('b1000000-0000-0000-0000-000000000001', 'valide');
select is(pg_temp.stock(), 47::numeric, 'validation du BL : sortie de stock');
select is((select cout_unitaire from public.lignes_document_vente where document_id = 'b1000000-0000-0000-0000-000000000001'), 100::numeric, 'coût figé depuis le lot');
select public.changer_statut_bon_livraison('b1000000-0000-0000-0000-000000000001', 'livre');
select public.convertir_document(jsonb_build_object('id', 'f1000000-0000-0000-0000-000000000001',
  'source_id', 'b1000000-0000-0000-0000-000000000001', 'type_cible', 'facture'));
select is((select numero from public.documents_vente where id = 'f1000000-0000-0000-0000-000000000001'),
          'FAC-' || to_char(now() at time zone 'Africa/Nouakchott', 'YYYY') || '-0001', 'facture numérotée FAC-AAAA-0001');
select is(pg_temp.stock(), 47::numeric, 'facture issue d''un BL : pas de seconde sortie de stock');
select is((select statut from public.documents_vente where id = 'b1000000-0000-0000-0000-000000000001'), 'facture'::public.statut_document_vente, 'BL passé à « facturé »');
select is((select solde from public.clients where id = 'a9000000-0000-0000-0000-000000000001'), 3000::numeric, 'facture à crédit : solde cliente');
select is((select cout_unitaire from public.lignes_document_vente where document_id = 'f1000000-0000-0000-0000-000000000001'), 100::numeric, 'coût du BL repris sur la facture');

-- Paiement partiel puis avoir partiel avec retour en stock : imputé sur le reste à payer
select public.enregistrer_paiement(jsonb_build_object('id', 'e1000000-0000-0000-0000-000000000001', 'document_id', 'f1000000-0000-0000-0000-000000000001',
  'mode_paiement_id', current_setting('t.especes'), 'montant', 1000));
select throws_like($$select public.annuler_document('f1000000-0000-0000-0000-000000000001', 'erreur')$$, 'annulation_impossible%', 'facture encaissée : annulation refusée (avoir)');
select throws_like($$select public.creer_avoir(jsonb_build_object('id', 'a5000000-0000-0000-0000-000000000099', 'facture_id', 'f1000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('ligne_id', (select id from public.lignes_document_vente where document_id = 'f1000000-0000-0000-0000-000000000001'), 'quantite', 5))))$$,
  'quantite_avoir_excessive%', 'avoir limité aux quantités facturées');
select public.creer_avoir(jsonb_build_object('id', 'a5000000-0000-0000-0000-000000000001', 'facture_id', 'f1000000-0000-0000-0000-000000000001',
  'retour_stock', true, 'motif', 'retour',
  'lignes', jsonb_build_array(jsonb_build_object('ligne_id', (select id from public.lignes_document_vente where document_id = 'f1000000-0000-0000-0000-000000000001'), 'quantite', 1))));
select is((select numero from public.documents_vente where id = 'a5000000-0000-0000-0000-000000000001'),
          'AV-' || to_char(now() at time zone 'Africa/Nouakchott', 'YYYY') || '-0001', 'avoir numéroté AV-AAAA-0001');
select is(pg_temp.stock(), 48::numeric, 'avoir avec retour en stock');
select is((select solde from public.clients where id = 'a9000000-0000-0000-0000-000000000001'), 1000::numeric, 'solde : 3000 − paiement 1000 − avoir imputé 1000');
select is((select paye from public.documents_vente where id = 'f1000000-0000-0000-0000-000000000001'), 2000::numeric, 'avoir imputé sur la facture');

-- Ticket payé en totalité : avoir remboursé en espèces
select public.enregistrer_vente(jsonb_build_object('id', 'a8000000-0000-0000-0000-000000000001', 'boutique_id', 'a2000000-0000-0000-0000-000000000001', 'type', 'ticket',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 2)),
  'paiements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 2000))));
select throws_like($$select public.creer_avoir(jsonb_build_object('id', 'a5000000-0000-0000-0000-000000000098', 'facture_id', 'a8000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('ligne_id', (select id from public.lignes_document_vente where document_id = 'a8000000-0000-0000-0000-000000000001'), 'quantite', 2)),
  'remboursements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 2500))))$$,
  'remboursement_excessif%', 'remboursement limité au montant dû');
select is((public.creer_avoir(jsonb_build_object('id', 'a5000000-0000-0000-0000-000000000002', 'facture_id', 'a8000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('ligne_id', (select id from public.lignes_document_vente where document_id = 'a8000000-0000-0000-0000-000000000001'), 'quantite', 2)),
  'remboursements', jsonb_build_array(jsonb_build_object('mode_paiement_id', current_setting('t.especes'), 'montant', 2000))))) ->> 'rembourse',
  '2000', 'avoir remboursé en espèces');
select is((select solde from public.clients where id = 'a9000000-0000-0000-0000-000000000001'), 1000::numeric, 'remboursement espèces : solde cliente inchangé');

-- Annulation d'une facture non encaissée : stock et solde restitués
select public.creer_devis(jsonb_build_object('id', 'd1000000-0000-0000-0000-000000000002', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'client_id', 'a9000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 2))));
select public.convertir_document(jsonb_build_object('id', 'f1000000-0000-0000-0000-000000000002',
  'source_id', 'd1000000-0000-0000-0000-000000000002', 'type_cible', 'facture'));
select is(pg_temp.stock(), 44::numeric, 'devis → facture : sortie de stock à l''émission');
select public.annuler_document('f1000000-0000-0000-0000-000000000002', 'saisie erronée');
select is(pg_temp.stock(), 46::numeric, 'annulation : stock restitué');
select is((select solde from public.clients where id = 'a9000000-0000-0000-0000-000000000001'), 1000::numeric, 'annulation : solde cliente restitué');
reset role;

-- Regroupement de deux BL en une facture
set local role authenticated;
select public.creer_bon_livraison(jsonb_build_object('id', 'b1000000-0000-0000-0000-000000000011', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'client_id', 'a9000000-0000-0000-0000-000000000001', 'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1))));
select public.creer_bon_livraison(jsonb_build_object('id', 'b1000000-0000-0000-0000-000000000012', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'client_id', 'a9000000-0000-0000-0000-000000000001', 'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 2))));
select public.changer_statut_bon_livraison('b1000000-0000-0000-0000-000000000011', 'valide');
select public.changer_statut_bon_livraison('b1000000-0000-0000-0000-000000000012', 'valide');
select public.convertir_document(jsonb_build_object('id', 'f1000000-0000-0000-0000-000000000011', 'type_cible', 'facture',
  'source_ids', jsonb_build_array('b1000000-0000-0000-0000-000000000011', 'b1000000-0000-0000-0000-000000000012')));
select is((select total from public.documents_vente where id = 'f1000000-0000-0000-0000-000000000011'), 3000::numeric, 'deux BL regroupés en une facture');
select is((select count(*)::integer from public.documents_liens where document_id = 'f1000000-0000-0000-0000-000000000011'), 2, 'liens vers les deux BL');
select is((select count(*)::integer from public.documents_vente where id in ('b1000000-0000-0000-0000-000000000011', 'b1000000-0000-0000-0000-000000000012') and statut = 'facture'), 2, 'les deux BL sont facturés');
reset role;

-- Expiration quotidienne (service)
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
select public.creer_devis(jsonb_build_object('id', 'd1000000-0000-0000-0000-000000000003', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'date_validite', (current_date - 1)::text, 'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1))));
select set_config('request.jwt.claims', '', true);
select public.expirer_devis_perimes();
select is((select statut from public.documents_vente where id = 'd1000000-0000-0000-0000-000000000003'), 'expire'::public.statut_document_vente, 'devis périmé : expiré par la tâche quotidienne');

select * from finish();
rollback;
