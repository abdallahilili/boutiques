-- Stock : lots, FIFO/FEFO, stock jamais négatif, mouvements en ajout seul, inventaire,
-- réservations, stock négatif optionnel (lot découvert), masquage des coûts.
begin;
create extension if not exists pgtap with schema extensions;
select plan(36);

-- ---------------------------------------------------------------------------
-- Jeu de données : boutique A (propriétaire, vendeuse, magasinière), 2 produits à 1 variante.
-- ---------------------------------------------------------------------------
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
insert into public.plans (id, code, nom_ar, nom_fr, limites)
values ('f0000000-0000-0000-0000-000000000001', 'test_illimite', 'اختبار', 'Test', '{}'::jsonb);
update public.abonnements set plan_id = 'f0000000-0000-0000-0000-000000000001'
where boutique_id = 'a2000000-0000-0000-0000-000000000001';
insert into public.membres_boutique (boutique_id, utilisateur_id, role_id) values
  ('a2000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-00000000000c',
   (select id from public.roles where boutique_id is null and cle = 'vendeuse')),
  ('a2000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-00000000000d',
   (select id from public.roles where boutique_id is null and cle = 'magasiniere'));

insert into public.produits (id, boutique_id, nom_fr) values
  ('a3000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'Sac noir'),
  ('a3000000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000001', 'Rouge à lèvres');
insert into public.variantes_produit (id, boutique_id, produit_id, prix_vente) values
  ('a4000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 1000),
  ('a4000000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000002', 2000);

select is((select code_barres ~ '^29[0-9]{11}$' from public.variantes_produit where id = 'a4000000-0000-0000-0000-000000000001'), true,
          'code-barres EAN-13 interne généré automatiquement');

-- ---------------------------------------------------------------------------
-- Réceptions par la propriétaire : un lot par ligne, numérotation LOT-AAAA-NNNN
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.recevoir_stock('{"id":"a5000000-0000-0000-0000-000000000001","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "reference":"BON-1","lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000001","quantite":10,"cout_unitaire":100}]}'::jsonb);
select public.recevoir_stock('{"id":"a5000000-0000-0000-0000-000000000002","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000001","quantite":5,"cout_unitaire":150}]}'::jsonb);
select is((public.recevoir_stock('{"id":"a5000000-0000-0000-0000-000000000002","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000001","quantite":5,"cout_unitaire":150}]}'::jsonb)) ->> 'rejoue', 'true',
  'réception idempotente : le rejeu ne crée rien');
reset role;
select set_config('request.jwt.claims', '', true);

select is((select count(*) from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000001'), 2::bigint, 'un lot par réception');
select is((select string_agg(numero_lot, ',' order by numero_lot) from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000001'),
          'LOT-' || to_char(now() at time zone 'Africa/Nouakchott', 'YYYY') || '-0001,LOT-' || to_char(now() at time zone 'Africa/Nouakchott', 'YYYY') || '-0002',
          'numéros de lot séquentiels sans doublon');
select is((select total from public.receptions_stock where id = 'a5000000-0000-0000-0000-000000000002'), 750::numeric, 'total de la réception calculé par le serveur');

-- ---------------------------------------------------------------------------
-- Sorties manuelles : motif obligatoire, consommation FIFO, jamais négatif
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select throws_like($$select public.ajuster_stock('{"id":"a6000000-0000-0000-0000-000000000001","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "type":"sortie_manuelle","lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000001","quantite":1}]}'::jsonb)$$,
  'motif_obligatoire%', 'une sortie manuelle exige un motif');
select lives_ok($$select public.ajuster_stock(('{"id":"a6000000-0000-0000-0000-000000000002","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "type":"sortie_manuelle","motif_id":"' || (select id from public.motifs_mouvement where code = 'casse') || '",
  "lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000001","quantite":12}]}')::jsonb)$$, 'sortie manuelle de 12 unités (casse)');
reset role;
select set_config('request.jwt.claims', '', true);

select is((select string_agg(quantite_restante::text, ',' order by numero_lot) from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000001'),
          '0.000,3.000', 'FIFO : le lot le plus ancien est vidé en premier');
select is((select count(*) from public.mouvements_stock where source_id = 'a6000000-0000-0000-0000-000000000002' and type = 'sortie_manuelle'),
          2::bigint, 'un mouvement par lot consommé');
select is((select sum(quantite_restante) from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000001'),
          (select sum(quantite) from public.mouvements_stock where variante_id = 'a4000000-0000-0000-0000-000000000001' and type not in ('reservation', 'liberation')),
          'le stock est toujours égal à la somme des mouvements');

select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select throws_like($$select public.ajuster_stock(('{"id":"a6000000-0000-0000-0000-000000000003","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "type":"sortie_manuelle","motif_id":"' || (select id from public.motifs_mouvement where code = 'perte') || '",
  "lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000001","quantite":4}]}')::jsonb)$$,
  'stock_insuffisant%', 'le stock ne peut pas devenir négatif');
reset role;
select set_config('request.jwt.claims', '', true);
select is((select sum(quantite_restante) from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000001'), 3::numeric,
          'stock inchangé après un refus');
select throws_ok($$update public.lots_stock set quantite_restante = -1 where variante_id = 'a4000000-0000-0000-0000-000000000001'$$, '23514', null,
                 'contrainte : quantité restante jamais négative');
select throws_like($$update public.mouvements_stock set quantite = 99$$, 'table_en_ajout_seul%', 'mouvements_stock est en ajout seul');
select throws_like($$delete from public.mouvements_stock$$, 'table_en_ajout_seul%', 'mouvements_stock : suppression interdite');

-- ---------------------------------------------------------------------------
-- FEFO : les lots à péremption proche sortent avant les plus anciens sans date
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.recevoir_stock('{"id":"a5000000-0000-0000-0000-000000000003","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000002","quantite":5,"cout_unitaire":10}]}'::jsonb);
select public.recevoir_stock('{"id":"a5000000-0000-0000-0000-000000000004","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000002","quantite":5,"cout_unitaire":20,"date_expiration":"2030-01-01"}]}'::jsonb);
select public.recevoir_stock('{"id":"a5000000-0000-0000-0000-000000000005","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000002","quantite":5,"cout_unitaire":30,"date_expiration":"2029-01-01"}]}'::jsonb);
select public.ajuster_stock(('{"id":"a6000000-0000-0000-0000-000000000004","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "type":"sortie_manuelle","motif_id":"' || (select id from public.motifs_mouvement where code = 'cadeau') || '",
  "lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000002","quantite":7}]}')::jsonb);
reset role;
select set_config('request.jwt.claims', '', true);
select is((select string_agg(cout_unitaire::int::text || ':' || quantite_restante::int::text, ' ' order by cout_unitaire)
           from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000002'),
          '10:5 20:3 30:0', 'FEFO : expiration 2029 puis 2030 avant le lot sans date');

-- ---------------------------------------------------------------------------
-- Inventaire : écarts calculés, ajustements ± avec le motif « inventaire »
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.ajuster_stock('{"id":"a6000000-0000-0000-0000-000000000005","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "type":"inventaire","lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000001","quantite_comptee":10}]}'::jsonb);
reset role;
select set_config('request.jwt.claims', '', true);
select is((select ecart from public.lignes_ajustement_stock where ajustement_id = 'a6000000-0000-0000-0000-000000000005'), 7::numeric, 'écart d''inventaire positif');
select is((select sum(quantite_restante) from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000001'), 10::numeric, 'surplus ajouté en stock');
select is((select motif_id from public.ajustements_stock where id = 'a6000000-0000-0000-0000-000000000005'),
          (select id from public.motifs_mouvement where code = 'inventaire'), 'motif inventaire appliqué');
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.ajuster_stock('{"id":"a6000000-0000-0000-0000-000000000006","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "type":"inventaire","lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000001","quantite_comptee":8}]}'::jsonb);
select is((select en_stock from public.stock_variante where variante_id = 'a4000000-0000-0000-0000-000000000001'), 8::numeric,
          'stock_variante : en stock après inventaire négatif');
reset role;
select set_config('request.jwt.claims', '', true);
select cmp_ok((select count(*) from public.journal_audit where entite = 'ajustements_stock'), '>=', 2::bigint, 'les ajustements sont journalisés');

-- ---------------------------------------------------------------------------
-- Réservation : le stock réservé n'est plus disponible
-- ---------------------------------------------------------------------------
insert into public.mouvements_stock (boutique_id, variante_id, type, quantite, source_type, source_id)
values ('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001', 'reservation', 6, 'commande', gen_random_uuid());
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select is((select reserve from public.stock_variante where variante_id = 'a4000000-0000-0000-0000-000000000001'), 6::numeric, 'quantité réservée');
select is((select disponible from public.stock_variante where variante_id = 'a4000000-0000-0000-0000-000000000001'), 2::numeric, 'disponible = en stock − réservé');
select throws_like($$select public.ajuster_stock(('{"id":"a6000000-0000-0000-0000-000000000007","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "type":"sortie_manuelle","motif_id":"' || (select id from public.motifs_mouvement where code = 'perte') || '",
  "lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000001","quantite":3}]}')::jsonb)$$,
  'stock_insuffisant%', 'le stock réservé ne peut pas être sorti');
reset role;
select set_config('request.jwt.claims', '', true);

-- ---------------------------------------------------------------------------
-- Stock négatif autorisé : lot découvert, absorbé par la réception suivante
-- ---------------------------------------------------------------------------
update public.boutiques set parametres = parametres || '{"stock_negatif_autorise": true}'::jsonb where id = 'a2000000-0000-0000-0000-000000000001';
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.ajuster_stock(('{"id":"a6000000-0000-0000-0000-000000000008","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "type":"sortie_manuelle","motif_id":"' || (select id from public.motifs_mouvement where code = 'perte') || '",
  "lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000001","quantite":11}]}')::jsonb);
reset role;
select set_config('request.jwt.claims', '', true);
select is((select sum(quantite_restante) from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000001'), -3::numeric,
          'stock négatif autorisé : découvert de 3');
select is((select count(*) from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000001' and decouvert), 1::bigint, 'un seul lot découvert');
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select public.recevoir_stock('{"id":"a5000000-0000-0000-0000-000000000006","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000001","quantite":10,"cout_unitaire":100}]}'::jsonb);
reset role;
select set_config('request.jwt.claims', '', true);
select is((select sum(quantite_restante) from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000001'), 7::numeric,
          'la réception absorbe le découvert (10 − 3)');
select is((select quantite_restante from public.lots_stock where variante_id = 'a4000000-0000-0000-0000-000000000001' and decouvert), 0::numeric,
          'lot découvert soldé');

-- ---------------------------------------------------------------------------
-- Rôles : coûts masqués pour la vendeuse, magasinière sans vente, écriture directe impossible
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"c0000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
set local role authenticated;
select is((select count(*) from public.lots_stock), 0::bigint, 'la vendeuse ne lit pas la table des lots (coûts)');
select is((select count(*) from public.lots_stock_vue where cout_unitaire is not null), 0::bigint, 'la vendeuse voit les lots sans coût');
select cmp_ok((select count(*) from public.lots_stock_vue), '>', 0::bigint, 'la vendeuse voit les lots (quantités)');
select throws_ok($$insert into public.mouvements_stock (boutique_id, variante_id, type, quantite)
  values ('a2000000-0000-0000-0000-000000000001', 'a4000000-0000-0000-0000-000000000001', 'entree', 100)$$, '42501', null,
  'aucune écriture directe dans le stock');
reset role;
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select cmp_ok((select count(*) from public.lots_stock_vue where cout_unitaire is not null), '>', 0::bigint, 'la propriétaire voit les coûts');
reset role;
select set_config('request.jwt.claims', '', true);

-- ---------------------------------------------------------------------------
-- Boutique suspendue : plus d'écriture de stock
-- ---------------------------------------------------------------------------
update public.boutiques set statut = 'suspendu' where id = 'a2000000-0000-0000-0000-000000000001';
select set_config('request.jwt.claims', '{"sub":"d0000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
set local role authenticated;
select throws_like($$select public.recevoir_stock('{"id":"a5000000-0000-0000-0000-000000000007","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000001","quantite":1,"cout_unitaire":1}]}'::jsonb)$$,
  'boutique_inactive%', 'boutique suspendue : lecture seule');
reset role;
select set_config('request.jwt.claims', '', true);
update public.boutiques set statut = 'actif' where id = 'a2000000-0000-0000-0000-000000000001';
select set_config('request.jwt.claims', '{"sub":"d0000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
set local role authenticated;
select lives_ok($$select public.recevoir_stock('{"id":"a5000000-0000-0000-0000-000000000008","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000001","quantite":1,"cout_unitaire":1}]}'::jsonb)$$, 'la magasinière peut enregistrer une entrée');
select throws_ok($$select public.enregistrer_vente('{"id":"a8000000-0000-0000-0000-000000000001","boutique_id":"a2000000-0000-0000-0000-000000000001",
  "lignes":[{"variante_id":"a4000000-0000-0000-0000-000000000001","quantite":1}]}'::jsonb)$$, '42501', null, 'la magasinière ne vend pas');
reset role;
select set_config('request.jwt.claims', '', true);

select * from finish();
rollback;
