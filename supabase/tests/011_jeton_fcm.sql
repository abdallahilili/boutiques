-- Phase 2 : enregistrement du jeton FCM (unicité, réattribution, isolation).
begin;
create extension if not exists pgtap with schema extensions;
select plan(6);

insert into auth.users (id, email) values
  ('a0000000-0000-0000-0000-00000000000a', 'a@test.local'),
  ('b0000000-0000-0000-0000-00000000000b', 'b@test.local');
insert into public.profils (id, nom_fr, telephone) values
  ('a0000000-0000-0000-0000-00000000000a', 'A', '22236000001'),
  ('b0000000-0000-0000-0000-00000000000b', 'B', '22236000002');
insert into public.appareils (id, utilisateur_id, plateforme) values
  ('aa000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-00000000000a', 'android'),
  ('bb000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-00000000000b', 'android');

select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.enregistrer_jeton_fcm('aa000000-0000-0000-0000-000000000001', 'jeton-de-test-0123456789-abcdef');
select is((select jeton_fcm from public.appareils where id = 'aa000000-0000-0000-0000-000000000001'), 'jeton-de-test-0123456789-abcdef', 'jeton enregistré');
select throws_ok($$select public.enregistrer_jeton_fcm('bb000000-0000-0000-0000-000000000001', 'jeton-de-test-0123456789-abcdef')$$, '42501', null, 'on ne touche pas l''appareil d''une autre utilisatrice');
select throws_like($$select public.enregistrer_jeton_fcm('aa000000-0000-0000-0000-000000000001', 'court')$$, 'parametres_invalides%', 'jeton trop court refusé');
reset role;

-- B se connecte sur le même téléphone : le jeton passe de l'appareil de A à celui de B
select set_config('request.jwt.claims', '{"sub":"b0000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
set local role authenticated;
select public.enregistrer_jeton_fcm('bb000000-0000-0000-0000-000000000001', 'jeton-de-test-0123456789-abcdef');
reset role;
select is((select jeton_fcm from public.appareils where id = 'bb000000-0000-0000-0000-000000000001'), 'jeton-de-test-0123456789-abcdef', 'jeton réattribué');
select is((select jeton_fcm from public.appareils where id = 'aa000000-0000-0000-0000-000000000001'), null, 'détaché de l''ancien appareil');

select set_config('request.jwt.claims', '', true);
set local role anon;
select throws_ok($$select public.enregistrer_jeton_fcm('aa000000-0000-0000-0000-000000000001', 'jeton-de-test-0123456789-abcdef')$$, '42501', null, 'anonyme refusé');
reset role;

select * from finish();
rollback;
