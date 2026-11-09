-- Isolation entre deux boutiques sur TOUTES les tables et vues portant boutique_id,
-- RPC inter-boutiques, Storage, domaines, thèmes et quotas.
begin;
create extension if not exists pgtap with schema extensions;
select plan(43);

-- ---------------------------------------------------------------------------
-- Compteur générique : liste des tables/vues (portant boutique_id) où l'appelant voit des lignes
-- de la boutique donnée. Exécuté avec les droits (et la RLS) du rôle courant.
-- ---------------------------------------------------------------------------
create function public.tmp_tables_visibles(p_boutique uuid, p_genre text default 'r')
returns text[]
language plpgsql
as $$
declare
  t text;
  n bigint;
  r text[] := '{}';
begin
  for t in
    select c.relname from pg_class c
    join pg_namespace ns on ns.oid = c.relnamespace and ns.nspname = 'public'
    join pg_attribute a on a.attrelid = c.oid and a.attname = 'boutique_id' and not a.attisdropped
    where c.relkind = p_genre and c.relname not like '%\_publi%' escape '\'
    order by c.relname
  loop
    begin
      execute format('select count(*) from public.%I where boutique_id = $1', t) into n using p_boutique;
      if n > 0 then
        r := r || t;
      end if;
    exception when insufficient_privilege then
      null;
    end;
  end loop;
  return r;
end;
$$;

-- ---------------------------------------------------------------------------
-- Jeu de données : deux boutiques complètes (A et B), chacune avec une propriétaire.
-- ---------------------------------------------------------------------------
insert into auth.users (id, email) values
  ('a0000000-0000-0000-0000-00000000000a', 'owner-a@test.local'),
  ('b0000000-0000-0000-0000-00000000000b', 'owner-b@test.local'),
  ('d0000000-0000-0000-0000-00000000000d', 'admin@test.local'),
  ('e0000000-0000-0000-0000-00000000000e', 'cliente-b@test.local');
insert into public.profils (id, nom_fr, telephone) values
  ('a0000000-0000-0000-0000-00000000000a', 'Owner A', '22236000001'),
  ('b0000000-0000-0000-0000-00000000000b', 'Owner B', '22236000002');
insert into public.profils (id, nom_fr, email, role_plateforme) values ('d0000000-0000-0000-0000-00000000000d', 'Admin', 'admin@test.local', 'super_admin');
insert into public.commercantes (id, utilisateur_id, nom_fr, telephone) values
  ('a1000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-00000000000a', 'Commerçante A', '22236000001'),
  ('b1000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-00000000000b', 'Commerçante B', '22236000002');
select public.creer_boutique_avec_defauts('a1000000-0000-0000-0000-000000000001', null, 'Boutique A', 'boutique-a', p_id => 'a2000000-0000-0000-0000-000000000001');
select public.creer_boutique_avec_defauts('b1000000-0000-0000-0000-000000000001', null, 'Boutique B', 'boutique-b', p_id => 'b2000000-0000-0000-0000-000000000001');
insert into public.plans (id, code, nom_ar, nom_fr, limites) values ('f0000000-0000-0000-0000-000000000001', 'test_illimite', 'اختبار', 'Test', '{}'::jsonb);
update public.abonnements set plan_id = 'f0000000-0000-0000-0000-000000000001';

-- Contenu complet de chaque boutique (A = a…, B = b…)
do $$
declare
  p text;
  b uuid;
  u uuid;
  v uuid;
  cl uuid;
  lot uuid;
  cm text;
begin
  for p in select unnest(array['a', 'b']) loop
    b := (p || '2000000-0000-0000-0000-000000000001')::uuid;
    u := (p || '0000000-0000-0000-0000-00000000000' || p)::uuid;
    v := (p || '4000000-0000-0000-0000-000000000001')::uuid;
    cl := (p || '9000000-0000-0000-0000-000000000001')::uuid;
    insert into public.modeles (boutique_id, nom_fr) values (b, 'Dentelle');
    insert into public.tailles (boutique_id, nom_fr) values (b, 'M');
    insert into public.marques (boutique_id, nom_fr) values (b, 'Marque');
    insert into public.clients (id, boutique_id, nom_fr, telephone) values (cl, b, 'Cliente ' || p, '2223600010' || (case p when 'a' then 1 else 2 end));
    insert into public.fournisseurs (boutique_id, nom_fr) values (b, 'Fournisseur');
    insert into public.zones_livraison (boutique_id, nom_fr, frais) values (b, 'Zone', 100);
    insert into public.depenses (boutique_id, montant, motif, utilisateur_id) values (b, 500, 'Loyer', u);
    insert into public.produits (id, boutique_id, nom_fr) values ((p || '3000000-0000-0000-0000-000000000001')::uuid, b, 'Produit ' || p);
    insert into public.variantes_produit (id, boutique_id, produit_id, prix_vente) values (v, b, (p || '3000000-0000-0000-0000-000000000001')::uuid, 1000);
    insert into public.images_produit (boutique_id, produit_id, url, principale) values (b, (p || '3000000-0000-0000-0000-000000000001')::uuid, 'x.jpg', true);
    insert into public.receptions_stock (id, boutique_id, total, utilisateur_id) values ((p || '5000000-0000-0000-0000-000000000001')::uuid, b, 1000, u);
    insert into public.lignes_reception_stock (id, boutique_id, reception_id, variante_id, quantite, cout_unitaire)
      values ((p || '7000000-0000-0000-0000-000000000001')::uuid, b, (p || '5000000-0000-0000-0000-000000000001')::uuid, v, 10, 100);
    perform prive.ajouter_lot(b, v, 10, 100, null, (p || '7000000-0000-0000-0000-000000000001')::uuid, null, 'test', null, u);
    insert into public.ajustements_stock (id, boutique_id, type, motif_id, utilisateur_id)
      values ((p || '6000000-0000-0000-0000-000000000001')::uuid, b, 'sortie_manuelle', (select id from public.motifs_mouvement where boutique_id = b and code = 'casse'), u);
    insert into public.lignes_ajustement_stock (boutique_id, ajustement_id, variante_id, quantite_systeme, ecart)
      values (b, (p || '6000000-0000-0000-0000-000000000001')::uuid, v, 10, -1);
    insert into public.appareils (id, utilisateur_id, boutique_id, plateforme) values ((p || 'a000000-0000-0000-0000-000000000001')::uuid, u, b, 'android');
    insert into public.sessions_caisse (id, boutique_id, utilisateur_id, fond_initial) values ((p || 'c000000-0000-0000-0000-000000000001')::uuid, b, u, 100);
    insert into public.plages_numeros (boutique_id, type_document, annee, appareil_id, debut, fin)
      values (b, 'ticket', 2026, (p || 'a000000-0000-0000-0000-000000000001')::uuid, 1, 5);
    cm := (select m.id::text from public.modes_paiement m where m.boutique_id = b and m.nom_fr = 'Espèces');
    perform prive.emettre_document(b, u, (p || '8000000-0000-0000-0000-000000000001')::uuid, 'facture', cl, 'caisse', null, null, 0, null,
      jsonb_build_array(jsonb_build_object('variante_id', v, 'libelle_fr', 'Produit', 'quantite', 1, 'prix_unitaire', 1000, 'remise', 0)),
      jsonb_build_array(jsonb_build_object('mode_paiement_id', cm, 'montant', 600)));
    insert into public.sections_site (boutique_id, type, titre_fr) values (b, 'a_propos', 'À propos');
    insert into public.pages_site (boutique_id, slug, titre_fr) values (b, 'livraison', 'Livraison');
    insert into public.bannieres_site (boutique_id, image_url) values (b, 'banniere.jpg');
    insert into public.comptes_clientes_site (boutique_id, utilisateur_id, nom, telephone)
      select b, e, 'Cliente', '2223600099' from (select case p when 'b' then 'e0000000-0000-0000-0000-00000000000e'::uuid end as e) s where e is not null;
    insert into public.journal_audit (boutique_id, utilisateur_id, action, entite) values (b, u, 'test', 'test');
    insert into public.notifications (boutique_id, utilisateur_id, titre_fr) values (b, u, 'Titre');
  end loop;
end;
$$;
insert into public.produits (id, boutique_id, nom_fr) values ('b3000000-0000-0000-0000-000000000002', 'b2000000-0000-0000-0000-000000000001', 'Produit B sans variante');
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;
select public.passer_commande_en_ligne('boutique-b', jsonb_build_object(
  'id', 'bb000000-0000-0000-0000-000000000001', 'nom_client', 'Fatima', 'telephone', '36000077', 'mode_livraison', 'retrait',
  'lignes', jsonb_build_array(jsonb_build_object('variante_id', 'b4000000-0000-0000-0000-000000000001', 'quantite', 1))));
reset role;
select set_config('request.jwt.claims', '', true);

select cmp_ok(coalesce(array_length(public.tmp_tables_visibles('b2000000-0000-0000-0000-000000000001'), 1), 0), '>=', 40,
              'la boutique B contient des données dans au moins 40 tables (le test d''isolement est significatif)');
select set_config('request.jwt.claims', '{"sub":"b0000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
set local role authenticated;
select cmp_ok(coalesce(array_length(public.tmp_tables_visibles('b2000000-0000-0000-0000-000000000001', 'v'), 1), 0), '>=', 4,
              'la propriétaire de B voit ses données dans les vues de stock et de documents');
reset role;
select set_config('request.jwt.claims', '', true);

-- ---------------------------------------------------------------------------
-- Propriétaire A : aucune ligne de B visible dans AUCUNE table ni vue
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select is(public.tmp_tables_visibles('b2000000-0000-0000-0000-000000000001'), '{}'::text[], 'A ne voit les données de B dans aucune table');
select is(public.tmp_tables_visibles('b2000000-0000-0000-0000-000000000001', 'v'), '{}'::text[], 'A ne voit les données de B dans aucune vue');
select cmp_ok(array_length(public.tmp_tables_visibles('a2000000-0000-0000-0000-000000000001'), 1), '>=', 30, 'A voit ses propres données');
select is((select count(*) from public.commandes), 0::bigint, 'A ne voit pas la commande en ligne de B');

-- Écritures dans B refusées (RLS) ou sans effet
select throws_ok($$insert into public.categories (boutique_id, nom_fr) values ('b2000000-0000-0000-0000-000000000001', 'Pirate')$$, '42501', null, 'insertion refusée : categories');
select throws_ok($$insert into public.clients (boutique_id, nom_fr) values ('b2000000-0000-0000-0000-000000000001', 'Pirate')$$, '42501', null, 'insertion refusée : clients');
select throws_ok($$insert into public.produits (boutique_id, nom_fr) values ('b2000000-0000-0000-0000-000000000001', 'Pirate')$$, '42501', null, 'insertion refusée : produits');
select throws_ok($$insert into public.depenses (boutique_id, montant) values ('b2000000-0000-0000-0000-000000000001', 1)$$, '42501', null, 'insertion refusée : depenses');
select throws_ok($$insert into public.sections_site (boutique_id, type) values ('b2000000-0000-0000-0000-000000000001', 'contact')$$, '42501', null, 'insertion refusée : sections_site');
select throws_ok($$insert into public.appareils (utilisateur_id, boutique_id, plateforme) values ('a0000000-0000-0000-0000-00000000000a', 'b2000000-0000-0000-0000-000000000001', 'ios')$$, '42501', null, 'appareil rattaché à la boutique de B refusé');
select throws_ok($$insert into public.variantes_produit (boutique_id, produit_id, prix_vente)
  values ('a2000000-0000-0000-0000-000000000001', 'b3000000-0000-0000-0000-000000000002', 1)$$, '23503', null, 'clé composite : impossible de référencer le produit de B');
select lives_ok($$update public.categories set nom_fr = 'Piraté' where boutique_id = 'b2000000-0000-0000-0000-000000000001'$$, 'update inter-boutiques : aucune ligne atteinte');
select lives_ok($$delete from public.categories where boutique_id = 'b2000000-0000-0000-0000-000000000001'$$, 'delete inter-boutiques : aucune ligne atteinte');

-- RPC avec l'identifiant de la boutique de B
select throws_ok($$select public.recevoir_stock('{"id":"c5000000-0000-0000-0000-000000000001","boutique_id":"b2000000-0000-0000-0000-000000000001",
  "lignes":[{"variante_id":"b4000000-0000-0000-0000-000000000001","quantite":1,"cout_unitaire":1}]}'::jsonb)$$, '42501', null, 'recevoir_stock sur B refusé');
select throws_ok($$select public.enregistrer_vente('{"id":"c8000000-0000-0000-0000-000000000001","boutique_id":"b2000000-0000-0000-0000-000000000001",
  "lignes":[{"variante_id":"b4000000-0000-0000-0000-000000000001","quantite":1}]}'::jsonb)$$, '42501', null, 'enregistrer_vente sur B refusé');
select throws_ok($$select public.attribuer_numero_document('b2000000-0000-0000-0000-000000000001', 'facture')$$, '42501', null, 'attribuer_numero_document sur B refusé');
select throws_ok($$select public.ouvrir_session_caisse('b2000000-0000-0000-0000-000000000001', 'c9000000-0000-0000-0000-000000000001', 0)$$, '42501', null, 'ouvrir_session_caisse sur B refusé');
select throws_ok($$select public.fermer_session_caisse('bc000000-0000-0000-0000-000000000001', 0)$$, '42501', null, 'fermer la session de B refusé');
select throws_ok($$select public.changer_statut_commande('bb000000-0000-0000-0000-000000000001', 'confirmee')$$, '42501', null, 'changer_statut_commande sur B refusé');
select throws_ok($$select public.enregistrer_paiement('{"id":"c9000000-0000-0000-0000-000000000002","document_id":"b8000000-0000-0000-0000-000000000001",
  "mode_paiement_id":"b8000000-0000-0000-0000-000000000001","montant":1}'::jsonb)$$, '42501', null, 'enregistrer_paiement sur le document de B refusé');
select throws_ok($$select public.generer_document_commande('{"commande_id":"bb000000-0000-0000-0000-000000000001","id":"c8000000-0000-0000-0000-000000000009"}'::jsonb)$$,
  '42501', null, 'generer_document_commande sur B refusé');
select throws_ok($$select public.admin_statistiques()$$, '42501', null, 'statistiques globales réservées à l''éditeur');
select is(public.mes_permissions('b2000000-0000-0000-0000-000000000001'), '{}'::text[], 'aucune permission dans la boutique de B');
reset role;
select set_config('request.jwt.claims', '', true);
select is((select count(*) from public.categories where boutique_id = 'b2000000-0000-0000-0000-000000000001' and nom_fr = 'Piraté'), 0::bigint, 'les données de B sont intactes');

-- ---------------------------------------------------------------------------
-- Storage : dossiers par boutique_id
-- ---------------------------------------------------------------------------
insert into storage.objects (bucket_id, name) values
  ('payment-proofs', 'a2000000-0000-0000-0000-000000000001/commandes/x/preuve.jpg'),
  ('payment-proofs', 'b2000000-0000-0000-0000-000000000001/commandes/x/preuve.jpg');
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select is((select count(*) from storage.objects where bucket_id = 'payment-proofs'), 1::bigint, 'A ne lit que les preuves de paiement de sa boutique');
select lives_ok($$insert into storage.objects (bucket_id, name) values ('product-images', 'a2000000-0000-0000-0000-000000000001/p1/photo.jpg')$$, 'A écrit dans son dossier d''images');
select throws_ok($$insert into storage.objects (bucket_id, name) values ('product-images', 'b2000000-0000-0000-0000-000000000001/p1/photo.jpg')$$, '42501', null, 'A n''écrit pas dans le dossier d''images de B');
reset role;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
set local role anon;
select lives_ok($$insert into storage.objects (bucket_id, name) values ('payment-proofs', 'b2000000-0000-0000-0000-000000000001/commandes/c1/capture.png')$$, 'dépôt anonyme d''une preuve sur une commande');
select throws_ok($$insert into storage.objects (bucket_id, name) values ('payment-proofs', 'b2000000-0000-0000-0000-000000000001/autre/capture.png')$$, '42501', null, 'dépôt anonyme hors du dossier commandes refusé');
select throws_ok($$insert into storage.objects (bucket_id, name) values ('payment-proofs', '99999999-0000-0000-0000-000000000000/commandes/c1/capture.png')$$, '42501', null, 'dépôt pour une boutique inexistante refusé');
select is((select count(*) from storage.objects where bucket_id = 'payment-proofs'), 0::bigint, 'les preuves restent privées pour la visiteuse');
reset role;
select set_config('request.jwt.claims', '', true);

-- ---------------------------------------------------------------------------
-- Sous-domaine, domaine personnalisé, thèmes, quotas
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select throws_ok($$update public.domaines_boutique set sous_domaine = 'nouveau' where boutique_id = 'a2000000-0000-0000-0000-000000000001'$$, '42501', null,
                 'le sous-domaine n''est pas modifiable par la commerçante');
select throws_like($$update public.domaines_boutique set domaine_personnalise = 'maboutique.mr' where boutique_id = 'a2000000-0000-0000-0000-000000000001'$$,
                   'quota_depasse%', 'domaine personnalisé refusé si le plan ne l''inclut pas');
select throws_like($$update public.parametres_site set theme_id = (select id from public.themes_site where code = 'moderne') where boutique_id = 'a2000000-0000-0000-0000-000000000001'$$,
                   'quota_depasse%', 'thème réservé à un plan supérieur refusé');
reset role;
select set_config('request.jwt.claims', '', true);
update public.plans set limites = '{"domaine_personnalise": true, "produits": 1}'::jsonb, ordre = 2 where id = 'f0000000-0000-0000-0000-000000000001';
select set_config('request.jwt.claims', '{"sub":"a0000000-0000-0000-0000-00000000000a","role":"authenticated"}', true);
set local role authenticated;
select lives_ok($$update public.domaines_boutique set domaine_personnalise = 'maboutique.mr' where boutique_id = 'a2000000-0000-0000-0000-000000000001'$$, 'domaine personnalisé accepté avec le bon plan');
select lives_ok($$update public.parametres_site set theme_id = (select id from public.themes_site where code = 'moderne') where boutique_id = 'a2000000-0000-0000-0000-000000000001'$$, 'thème accepté avec le bon plan');
select throws_like($$insert into public.variantes_produit (boutique_id, produit_id, prix_vente, sku)
  values ('a2000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 5, 'SKU-2')$$, 'quota_depasse%', 'quota de produits du plan');
reset role;
select set_config('request.jwt.claims', '', true);
select is((select statut_dns from public.domaines_boutique where boutique_id = 'a2000000-0000-0000-0000-000000000001'), 'en_attente'::public.statut_domaine,
          'un nouveau domaine passe en attente de vérification DNS');

select set_config('request.jwt.claims', '{"sub":"d0000000-0000-0000-0000-00000000000d","role":"authenticated"}', true);
set local role authenticated;
select lives_ok($$update public.domaines_boutique set sous_domaine = 'nouveau-nom' where boutique_id = 'a2000000-0000-0000-0000-000000000001'$$, 'l''éditeur modifie le sous-domaine');
select is((public.admin_statistiques() -> 'boutiques' ->> 'essai')::int, 2, 'statistiques éditeur : 2 boutiques en essai');
select is((public.admin_quotas_boutique('a2000000-0000-0000-0000-000000000001') ->> 'utilisateurs')::int, 1, 'quotas consommés d''une boutique (éditeur)');
reset role;

select * from finish();
rollback;
