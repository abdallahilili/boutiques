-- Phase 2 : notifications métier (nouvelle commande, statut, impayés échus).
begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

insert into auth.users (id, email) values
  ('a0000000-0000-0000-0000-00000000000a', 'owner@test.local'),
  ('c0000000-0000-0000-0000-00000000000c', 'vendeuse@test.local'),
  ('d0000000-0000-0000-0000-00000000000d', 'magasiniere@test.local');
insert into public.profils (id, nom_fr, telephone) values
  ('a0000000-0000-0000-0000-00000000000a', 'Owner', '22236000001'),
  ('c0000000-0000-0000-0000-00000000000c', 'Vendeuse', '22236000003'),
  ('d0000000-0000-0000-0000-00000000000d', 'Magasinière', '22236000004');
insert into public.commercantes (id, utilisateur_id, nom_fr, telephone)
values ('a1000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-00000000000a', 'Commerçante', '22236000001');
select public.creer_boutique_avec_defauts('a1000000-0000-0000-0000-000000000001', null, 'Boutique A', 'boutique-a',
                                          p_id => 'a2000000-0000-0000-0000-000000000001');
insert into public.plans (id, code, nom_ar, nom_fr, limites) values ('f0000000-0000-0000-0000-000000000001', 'test_illimite', 'اختبار', 'Test', '{}'::jsonb);
update public.abonnements set plan_id = 'f0000000-0000-0000-0000-000000000001';
insert into public.membres_boutique (boutique_id, utilisateur_id, role_id) values
  ('a2000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-00000000000c', (select id from public.roles where boutique_id is null and cle = 'vendeuse')),
  ('a2000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-00000000000d', (select id from public.roles where boutique_id is null and cle = 'magasiniere'));
select set_config('t.especes', (select id::text from public.modes_paiement where boutique_id = 'a2000000-0000-0000-0000-000000000001' and nom_fr = 'Espèces'), true);

insert into public.commandes (id, boutique_id, numero, nom_client, telephone, sous_total, total)
values ('c5000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'CMD-2026-0001', 'Cliente', '22236111111', 500, 500);
select is((select count(*)::integer from public.notifications where type = 'commande'), 3, 'nouvelle commande : propriétaire, vendeuse et magasinière (commandes.lire)');
select is((select count(*)::integer from public.notifications where type = 'commande' and utilisateur_id = 'a0000000-0000-0000-0000-00000000000a'), 1, 'la propriétaire est notifiée');
update public.commandes set statut = 'confirmee' where id = 'c5000000-0000-0000-0000-000000000001';
select is((select count(*)::integer from public.notifications where type = 'commande_statut'), 1, 'changement de statut : propriétaire seulement (rapports.financiers)');
update public.commandes set notes = 'x' where id = 'c5000000-0000-0000-0000-000000000001';
select is((select count(*)::integer from public.notifications where type = 'commande_statut'), 1, 'un autre champ ne notifie pas');

-- Impayés échus : facture à crédit avec échéance passée
insert into public.clients (id, boutique_id, nom_fr, plafond_credit) values ('a9000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'Cliente', 100000);
insert into public.produits (id, boutique_id, nom_fr) values ('a3000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'Sac');
insert into public.variantes_produit (id, boutique_id, produit_id, prix_vente) values
  ('a4000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 1000);
select prive.ajouter_lot('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001', 10, 100, null, null, null, 'test', null, null);
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.enregistrer_vente(jsonb_build_object('id', 'a8000000-0000-0000-0000-000000000001', 'boutique_id', 'a2000000-0000-0000-0000-000000000001',
  'type', 'facture', 'client_id', 'a9000000-0000-0000-0000-000000000001',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'a4000000-0000-0000-0000-000000000001', 'quantite', 1))));
reset role;
select set_config('request.jwt.claims', '', true);
select is((public.generer_alertes_impayes() ->> 'nombre')::integer, 0, 'facture sans échéance : pas d''alerte');
update public.documents_vente set date_echeance = current_date - 5 where id = 'a8000000-0000-0000-0000-000000000001';
select is((public.generer_alertes_impayes() ->> 'nombre')::integer, 1, 'facture échue : une alerte pour la propriétaire');
select is((public.generer_alertes_impayes() ->> 'nombre')::integer, 0, 'pas de doublon le même jour');

select * from finish();
rollback;
