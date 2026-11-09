-- Phase 0 : isolement RLS des tables plateforme, rôles, quotas, journal d'audit,
-- verrouillage des tentatives de connexion.
begin;
create extension if not exists pgtap with schema extensions;
select plan(47);

-- ---------------------------------------------------------------------------
-- Jeu de données : 2 boutiques (A, B), une propriétaire chacune, une vendeuse en A,
-- un super_admin et un agent support.
-- ---------------------------------------------------------------------------
insert into auth.users (id, email) values
  ('a0000000-0000-0000-0000-00000000000a', 'owner-a@test.local'),
  ('b0000000-0000-0000-0000-00000000000b', 'owner-b@test.local'),
  ('c0000000-0000-0000-0000-00000000000c', 'vendeuse-a@test.local'),
  ('d0000000-0000-0000-0000-00000000000d', 'admin@test.local'),
  ('e0000000-0000-0000-0000-00000000000e', 'support@test.local');

insert into public.profils (id, nom_fr, telephone, role_plateforme) values
  ('a0000000-0000-0000-0000-00000000000a', 'Owner A', '22236000001', 'aucun'),
  ('b0000000-0000-0000-0000-00000000000b', 'Owner B', '22236000002', 'aucun'),
  ('c0000000-0000-0000-0000-00000000000c', 'Vendeuse A', '22236000003', 'aucun');
insert into public.profils (id, nom_fr, email, role_plateforme) values
  ('d0000000-0000-0000-0000-00000000000d', 'Admin', 'admin@test.local', 'super_admin'),
  ('e0000000-0000-0000-0000-00000000000e', 'Support', 'support@test.local', 'support');

insert into public.commercantes (id, utilisateur_id, nom_fr, telephone) values
  ('a1000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-00000000000a', 'Commerçante A', '22236000001'),
  ('b1000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-00000000000b', 'Commerçante B', '22236000002');

select public.creer_boutique_avec_defauts('a1000000-0000-0000-0000-000000000001', null, 'Boutique A', 'boutique-a', p_id => 'a2000000-0000-0000-0000-000000000001');
select public.creer_boutique_avec_defauts('b1000000-0000-0000-0000-000000000001', null, 'Boutique B', 'boutique-b', p_id => 'b2000000-0000-0000-0000-000000000001');

-- Plan de test à 3 utilisateurs pour la boutique A.
insert into public.plans (id, code, nom_ar, nom_fr, limites)
values ('f0000000-0000-0000-0000-000000000001', 'test_deux', 'اختبار', 'Test', '{"utilisateurs": 3}'::jsonb);
update public.abonnements set plan_id = 'f0000000-0000-0000-0000-000000000001'
where boutique_id = 'a2000000-0000-0000-0000-000000000001';

insert into public.membres_boutique (boutique_id, utilisateur_id, role_id)
values ('a2000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-00000000000c',
        (select id from public.roles where boutique_id is null and cle = 'vendeuse'));

-- ---------------------------------------------------------------------------
-- Structure : RLS partout, aucune table sans politique
-- ---------------------------------------------------------------------------
select is_empty(
  $$select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity$$,
  'RLS activée sur toutes les tables du schéma public');

select is_empty(
  $$select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r'
      and not exists (select 1 from pg_policies p where p.schemaname = 'public' and p.tablename = c.relname)$$,
  'aucune table du schéma public sans politique');

select is((select count(*) from public.roles where boutique_id is null), 4::bigint, '4 rôles système');
select is((select count(*) from public.permissions_role pr join public.roles r on r.id = pr.role_id where r.cle = 'proprietaire'),
          (select count(*) from public.permissions), 'la propriétaire détient toutes les permissions');
select is((select autorise from public.permissions_role pr join public.roles r on r.id = pr.role_id
           where r.cle = 'vendeuse' and pr.cle_permission = 'couts.voir'), null,
          'la vendeuse n''a pas la permission de voir les coûts');
select is((select count(*) from public.permissions_role pr join public.roles r on r.id = pr.role_id
           where r.cle = 'magasiniere' and pr.cle_permission in ('pos.vendre', 'rapports.financiers')), 0::bigint,
          'la magasinière ne vend pas et n''a pas les rapports financiers');

-- ---------------------------------------------------------------------------
-- Propriétaire A : voit sa boutique, jamais celle de B
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;

select is((select count(*) from public.boutiques), 1::bigint, 'A ne voit que sa boutique');
select is((select count(*) from public.boutiques where id = 'b2000000-0000-0000-0000-000000000001'), 0::bigint, 'A ne voit pas la boutique B');
select is((select count(*) from public.abonnements), 1::bigint, 'A voit son abonnement uniquement');
select is((select count(*) from public.membres_boutique), 2::bigint, 'A voit les membres de sa boutique uniquement');
select is((select count(*) from public.profils where id = 'b0000000-0000-0000-0000-00000000000b'), 0::bigint, 'A ne voit pas le profil de B');
select is((select count(*) from public.profils where id = 'c0000000-0000-0000-0000-00000000000c'), 1::bigint, 'A voit le profil de sa vendeuse');
select is((select count(*) from public.commercantes), 0::bigint, 'les commerçantes (notes internes) sont réservées à l''éditeur');

select lives_ok($$update public.boutiques set nom_fr = 'Boutique A renommée' where id = (select id from public.boutiques limit 1)$$,
                'A peut renommer sa boutique');
select throws_ok($$update public.boutiques set slug = 'autre' where slug = 'boutique-a'$$, '42501', null,
                 'A ne peut pas modifier son sous-domaine (slug)');
select throws_ok($$update public.boutiques set statut = 'actif' where slug = 'boutique-a'$$, '42501', null,
                 'A ne peut pas changer le statut de sa boutique');
select lives_ok($$update public.boutiques set nom_fr = 'Piratée' where slug = 'boutique-b'$$, 'mise à jour de la boutique B : aucune ligne visible, aucune erreur');
select throws_ok($$update public.membres_boutique set statut = 'desactive'
                   where utilisateur_id = 'a0000000-0000-0000-0000-00000000000a'$$, '42501', null,
                 'la propriétaire ne peut pas être désactivée');
select throws_ok($$insert into public.membres_boutique (boutique_id, utilisateur_id, role_id)
                   values ((select id from public.boutiques limit 1), 'b0000000-0000-0000-0000-00000000000b',
                           (select id from public.roles where boutique_id is null and cle = 'vendeuse'))$$,
                 '42501', null, 'l''insertion directe de membres est réservée à l''éditeur');
select throws_ok($$update public.profils set role_plateforme = 'super_admin'
                   where id = 'a0000000-0000-0000-0000-00000000000a'$$, '42501', null,
                 'élévation de privilège plateforme impossible');
select lives_ok($$update public.profils set langue = 'fr' where id = 'a0000000-0000-0000-0000-00000000000a'$$,
                'A peut changer sa langue');
select throws_ok($$delete from public.journal_audit$$, '42501', null, 'A ne peut pas supprimer le journal d''audit');
select cmp_ok((select count(*) from public.journal_audit), '>=', 1::bigint, 'A voit le journal d''audit de sa boutique');
select is((select count(*) from public.journal_audit where boutique_id = 'b2000000-0000-0000-0000-000000000001'), 0::bigint,
          'A ne voit pas le journal d''audit de B');
select throws_like($$select public.enregistrer_paiement_abonnement(
                       (select id from public.abonnements limit 1), 100, 'especes')$$,
                   'acces_refuse%', 'A ne peut pas enregistrer un paiement d''abonnement');
select throws_ok($$select public.creer_boutique_avec_defauts('a1000000-0000-0000-0000-000000000001', null, 'X', 'x-boutique')$$,
                 '42501', null, 'creer_boutique_avec_defauts réservée au service_role');
reset role;
select set_config('request.jwt.claims', '', true);

-- ---------------------------------------------------------------------------
-- Vendeuse A : pas d'accès à l'abonnement, ne gère pas les membres
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"c0000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
set local role authenticated;
select is((select count(*) from public.abonnements), 0::bigint, 'la vendeuse ne voit pas l''abonnement');
select is((select count(*) from public.journal_audit), 0::bigint, 'la vendeuse ne voit pas le journal d''audit');
reset role;
select set_config('request.jwt.claims', '', true);

-- ---------------------------------------------------------------------------
-- Quota d'utilisateurs du plan
-- ---------------------------------------------------------------------------
insert into auth.users (id, email) values
  ('c1000000-0000-0000-0000-00000000000c', 'extra@test.local'),
  ('c2000000-0000-0000-0000-00000000000c', 'extra2@test.local');
insert into public.profils (id, nom_fr, telephone) values
  ('c1000000-0000-0000-0000-00000000000c', 'Extra', '22236000004'),
  ('c2000000-0000-0000-0000-00000000000c', 'Extra 2', '22236000005');
select lives_ok($$insert into public.membres_boutique (boutique_id, utilisateur_id, role_id)
                  values ((select id from public.boutiques where slug = 'boutique-a'), 'c1000000-0000-0000-0000-00000000000c',
                          (select id from public.roles where boutique_id is null and cle = 'vendeuse'))$$,
                'le troisième utilisateur respecte le quota');
select throws_like($$insert into public.membres_boutique (boutique_id, utilisateur_id, role_id)
                     values ((select id from public.boutiques where slug = 'boutique-a'), 'c2000000-0000-0000-0000-00000000000c',
                             (select id from public.roles where boutique_id is null and cle = 'vendeuse'))$$,
                   'quota_depasse%', 'le quota d''utilisateurs du plan bloque la création');

-- ---------------------------------------------------------------------------
-- Boutique suspendue : lecture seule
-- ---------------------------------------------------------------------------
update public.boutiques set statut = 'suspendu' where id = 'a2000000-0000-0000-0000-000000000001';
select is(public.boutique_est_active('a2000000-0000-0000-0000-000000000001'), false, 'boutique suspendue : inactive');
select is(public.boutique_est_active('b2000000-0000-0000-0000-000000000001'), true, 'boutique en essai : active');
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select lives_ok($$update public.boutiques set nom_fr = 'Pendant suspension' where slug = 'boutique-a'$$, 'mise à jour sans erreur');
select is((select nom_fr from public.boutiques where slug = 'boutique-a'), 'Boutique A renommée',
          'boutique suspendue : écriture bloquée, lecture conservée');
reset role;
select set_config('request.jwt.claims', '', true);

-- ---------------------------------------------------------------------------
-- Éditeur : paiement d'abonnement, réactivation, droits support / super_admin
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"d0000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
set local role authenticated;
select is((select count(*) from public.boutiques), 2::bigint, 'le super_admin voit toutes les boutiques');
select lives_ok($$select public.enregistrer_paiement_abonnement(
                    (select id from public.abonnements where boutique_id = (select id from public.boutiques where slug = 'boutique-a')),
                    5000, 'mobile_money', 'REF-1')$$, 'le super_admin enregistre un paiement');
reset role;
select set_config('request.jwt.claims', '', true);
select is((select statut from public.boutiques where id = 'a2000000-0000-0000-0000-000000000001'), 'actif'::public.statut_boutique,
          'le paiement réactive la boutique suspendue');
select cmp_ok((select fin_le from public.abonnements where boutique_id = 'a2000000-0000-0000-0000-000000000001'), '>', current_date,
              'le paiement prolonge l''abonnement');

select set_config('request.jwt.claims', '{"sub":"e0000000-0000-0000-0000-00000000000e","role":"authenticated"}', true);
set local role authenticated;
select lives_ok($$delete from public.boutiques where slug = 'boutique-b'$$, 'support : suppression sans erreur');
reset role;
select set_config('request.jwt.claims', '', true);
select is((select count(*) from public.boutiques where slug = 'boutique-b'), 1::bigint, 'support : suppression d''une boutique refusée');

-- ---------------------------------------------------------------------------
-- Journal d'audit immuable
-- ---------------------------------------------------------------------------
select throws_like($$delete from public.journal_audit$$, 'table_en_ajout_seul%', 'le journal d''audit est en ajout seul');

-- ---------------------------------------------------------------------------
-- Limitation des tentatives de connexion
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
set local role service_role;
select is(public.verifier_verrou_connexion('m:22236000001'), null, 'aucun verrou au départ');
select public.enregistrer_echec_connexion('m:22236000001', 5, 900) from generate_series(1, 4);
select is(public.verifier_verrou_connexion('m:22236000001'), null, 'pas de verrou après 4 échecs');
select isnt(public.enregistrer_echec_connexion('m:22236000001', 5, 900), null, 'verrouillage au 5e échec');
select isnt(public.verifier_verrou_connexion('m:22236000001'), null, 'identifiant verrouillé');
select public.reinitialiser_tentatives_connexion('m:22236000001');
select is(public.verifier_verrou_connexion('m:22236000001'), null, 'réinitialisation après connexion réussie');
reset role;
select set_config('request.jwt.claims', '', true);
set local role authenticated;
select throws_ok($$select public.enregistrer_echec_connexion('x')$$, '42501', null, 'RPC de verrouillage inaccessible aux clients');
reset role;
select set_config('request.jwt.claims', '', true);

select * from finish();
rollback;
