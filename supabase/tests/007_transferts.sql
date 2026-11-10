-- Phase 2 : transferts de stock entre deux boutiques (envoi, acceptation, refus, annulation, isolation).
begin;
create extension if not exists pgtap with schema extensions;
select plan(26);

insert into auth.users (id, email) values
  ('a0000000-0000-0000-0000-00000000000a', 'owner-a@test.local'),
  ('b0000000-0000-0000-0000-00000000000b', 'owner-b@test.local'),
  ('c0000000-0000-0000-0000-00000000000c', 'owner-c@test.local');
insert into public.profils (id, nom_fr, telephone) values
  ('a0000000-0000-0000-0000-00000000000a', 'Owner A', '22236000001'),
  ('b0000000-0000-0000-0000-00000000000b', 'Owner B', '22236000002'),
  ('c0000000-0000-0000-0000-00000000000c', 'Owner C', '22236000003');
insert into public.commercantes (id, utilisateur_id, nom_fr, telephone) values
  ('a1000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-00000000000a', 'Commerçante A', '22236000001'),
  ('b1000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-00000000000b', 'Commerçante B', '22236000002'),
  ('c1000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-00000000000c', 'Commerçante C', '22236000003');
select public.creer_boutique_avec_defauts('a1000000-0000-0000-0000-000000000001', null, 'Boutique A', 'boutique-a', p_id => 'a2000000-0000-0000-0000-000000000001');
select public.creer_boutique_avec_defauts('b1000000-0000-0000-0000-000000000001', null, 'Boutique B', 'boutique-b', p_id => 'b2000000-0000-0000-0000-000000000001');
select public.creer_boutique_avec_defauts('c1000000-0000-0000-0000-000000000001', null, 'Boutique C', 'boutique-c', p_id => 'c2000000-0000-0000-0000-000000000001');
insert into public.plans (id, code, nom_ar, nom_fr, limites) values ('f0000000-0000-0000-0000-000000000001', 'test_illimite', 'اختبار', 'Test', '{}'::jsonb);
update public.abonnements set plan_id = 'f0000000-0000-0000-0000-000000000001';

insert into public.produits (id, boutique_id, nom_ar, nom_fr) values
  ('a3000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'حقيبة', 'Sac'),
  ('b3000000-0000-0000-0000-000000000001', 'b2000000-0000-0000-0000-000000000001', 'حقيبة ب', 'Sac B');
insert into public.variantes_produit (id, boutique_id, produit_id, prix_vente) values
  ('a4000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 1000),
  ('b4000000-0000-0000-0000-000000000001', 'b2000000-0000-0000-0000-000000000001', 'b3000000-0000-0000-0000-000000000001', 900);
select prive.ajouter_lot('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001', 10, 100, null, null, null, 'test', null, null);
select set_config('t.code_b', (select code_boutique from public.boutiques where id = 'b2000000-0000-0000-0000-000000000001'), true);

create or replace function pg_temp.stock_a() returns numeric language sql security definer as $$
  select coalesce(sum(quantite_restante), 0) from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000001' $$;
create or replace function pg_temp.stock_b() returns numeric language sql security definer as $$
  select coalesce(sum(quantite_restante), 0) from public.lots_stock where boutique_id = 'b2000000-0000-0000-0000-000000000001' $$;
grant execute on function pg_temp.stock_a(), pg_temp.stock_b() to authenticated;

-- Envoi par A
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.envoyer_transfert(jsonb_build_object('id', 'e1000000-0000-0000-0000-000000000001', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'destinataire', jsonb_build_object('code_boutique', current_setting('t.code_b')),
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 4, 'prix_unitaire', 300))));
select is(pg_temp.stock_a(), 6::numeric, 'envoi : sortie de stock immédiate chez l''émettrice');
select is((select statut from public.transferts where id = 'e1000000-0000-0000-0000-000000000001'), 'en_attente'::public.statut_transfert, 'transfert en attente');
select is((select numero from public.transferts where id = 'e1000000-0000-0000-0000-000000000001'),
          'TRF-' || to_char(now() at time zone 'Africa/Nouakchott', 'YYYY') || '-0001', 'transfert numéroté TRF-AAAA-0001');
select is((public.envoyer_transfert(jsonb_build_object('id', 'e1000000-0000-0000-0000-000000000001', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'destinataire', jsonb_build_object('code_boutique', current_setting('t.code_b')),
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 4))))) ->> 'rejoue', 'true', 'envoi idempotent');
select is(pg_temp.stock_a(), 6::numeric, 'le rejeu ne ressort pas de stock');
select throws_like($$select public.envoyer_transfert(jsonb_build_object('id', 'e1000000-0000-0000-0000-000000000009', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'destinataire', jsonb_build_object('code_boutique', 'ZZZZZZ'),
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1))))$$, 'destinataire_introuvable%', 'destinataire inconnue');
select throws_like($$select public.envoyer_transfert(jsonb_build_object('id', 'e1000000-0000-0000-0000-000000000008', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'destinataire', jsonb_build_object('code_boutique', current_setting('t.code_b')),
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 50))))$$, 'stock_insuffisant%', 'stock insuffisant refusé');
select is((select count(*)::integer from public.transferts), 1, 'l''émettrice voit son transfert');
select throws_ok($$select public.repondre_transfert(jsonb_build_object('transfert_id', 'e1000000-0000-0000-0000-000000000001', 'decision', 'accepter'))$$, '42501', null, 'l''émettrice ne répond pas à sa propre demande');
reset role;

-- C n'est pas concernée ; B voit le transfert
select set_config('request.jwt.claims', '{"sub":"c0000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
set local role authenticated;
select is((select count(*)::integer from public.transferts), 0, 'une tierce boutique ne voit pas le transfert');
select throws_ok($$select public.repondre_transfert(jsonb_build_object('transfert_id', 'e1000000-0000-0000-0000-000000000001', 'decision', 'refuser'))$$, '42501', null, 'une tierce boutique ne répond pas');
reset role;

select set_config('request.jwt.claims', '{"sub":"b0000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
set local role authenticated;
select is((select count(*)::integer from public.transferts), 1, 'la destinataire voit le transfert');
select is((select count(*)::integer from public.notifications where utilisateur_id = 'b0000000-0000-0000-0000-00000000000b' and type = 'transfert'), 1, 'notification à la destinataire');
select throws_like($$select public.repondre_transfert(jsonb_build_object('transfert_id', 'e1000000-0000-0000-0000-000000000001', 'decision', 'accepter', 'correspondances', '[]'::jsonb))$$,
  'correspondance_requise%', 'chaque ligne doit être mise en correspondance');
-- Acceptation : une ligne vers un produit existant de B, prix de vente propre
select public.repondre_transfert(jsonb_build_object('transfert_id', 'e1000000-0000-0000-0000-000000000001', 'decision', 'accepter',
  'correspondances', jsonb_build_array(jsonb_build_object('ligne_id', (select id from public.lignes_transfert limit 1),
                                                          'variante_id', 'b4000000-0000-0000-0000-000000000001', 'prix_vente', 1100))));
select is(pg_temp.stock_b(), 4::numeric, 'acceptation : stock reçu chez la destinataire');
select is((select prix_vente from public.variantes_produit where id = 'b4000000-0000-0000-0000-000000000001'), 1100::numeric, 'prix de vente propre de la destinataire');
select is((select cout_unitaire from public.lots_stock where boutique_id = 'b2000000-0000-0000-0000-000000000001' and variante_id = 'b4000000-0000-0000-0000-000000000001'), 300::numeric, 'le coût d''achat de B est le prix de transfert');
select is((select solde from public.fournisseurs where boutique_liee_id = 'a2000000-0000-0000-0000-000000000001'), 1200::numeric, 'dette envers l''émettrice (fournisseur)');
select is((public.repondre_transfert(jsonb_build_object('transfert_id', 'e1000000-0000-0000-0000-000000000001', 'decision', 'accepter'))) ->> 'rejoue', 'true', 'réponse idempotente');
select throws_like($$select public.repondre_transfert(jsonb_build_object('transfert_id', 'e1000000-0000-0000-0000-000000000001', 'decision', 'refuser'))$$,
  'transfert_deja_traite%', 'un transfert traité ne change plus de décision');
reset role;

select is((select solde from public.clients where boutique_liee_id = 'b2000000-0000-0000-0000-000000000001'), 1200::numeric, 'créance de l''émettrice sur la destinataire (cliente)');

-- Annulation tant que non traité : le stock revient à l'émettrice
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.envoyer_transfert(jsonb_build_object('id', 'e1000000-0000-0000-0000-000000000002', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'destinataire', jsonb_build_object('code_boutique', current_setting('t.code_b')),
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 2))));
select public.annuler_transfert('e1000000-0000-0000-0000-000000000002');
select is(pg_temp.stock_a(), 6::numeric, 'annulation : le stock revient à l''émettrice');
reset role;

-- Lecture applicative : liste et détail avec le nom de l'autre boutique, sans coût
select set_config('request.jwt.claims', '{"sub":"b0000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
set local role authenticated;
select is((public.liste_transferts('b2000000-0000-0000-0000-000000000001') -> 0 ->> 'sens'), 'recu', 'liste côté destinataire : transfert reçu');
select is((public.liste_transferts('b2000000-0000-0000-0000-000000000001') -> 0 -> 'autre_boutique' ->> 'nom_fr'), 'Boutique A', 'nom de l''émettrice visible');
select is((public.detail_transfert('b2000000-0000-0000-0000-000000000001', 'e1000000-0000-0000-0000-000000000001') -> 'lignes' -> 0 ->> 'prix_unitaire')::numeric, 300::numeric, 'détail : prix de transfert (pas de coût)');
select throws_like($$select public.detail_transfert('c2000000-0000-0000-0000-000000000001', 'e1000000-0000-0000-0000-000000000001')$$, 'acces_refuse%', 'une autre boutique ne lit pas le détail');
reset role;

select * from finish();
rollback;
