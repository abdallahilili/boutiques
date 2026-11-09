-- =============================================================================
-- Storage : buckets et politiques par boutique_id (premier dossier du chemin).
--   product-images  public en lecture   {boutique_id}/{produit_id}/{fichier}
--   shop-assets     public en lecture   {boutique_id}/...
--   payment-proofs  privé               {boutique_id}/commandes/{commande_id}/{fichier} | {boutique_id}/abonnement/...
-- Limite : 5 Mo par fichier, images uniquement (+ PDF pour les preuves). Aucun bucket « documents » :
-- les documents de vente ne sont jamais enregistrés en PDF.
-- =============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values
  ('product-images', 'product-images', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('shop-assets', 'shop-assets', true, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml', 'image/x-icon']),
  ('payment-proofs', 'payment-proofs', false, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Boutique (premier dossier du chemin) où l'appelante détient la permission, boutique active.
create or replace function prive.dossier_ecriture_autorise(p_dossier text, p_permission text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from unnest(prive.boutiques_avec_permission(p_permission)) as b
    where b::text = p_dossier and public.boutique_est_active(b)
  );
$$;

-- Une visiteuse peut déposer une preuve uniquement pour une boutique active (dossier commandes/{id}).
create or replace function prive.dossier_justificatif_commande_valide(p_chemin text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select array_length(storage.foldername(p_chemin), 1) = 3
     and (storage.foldername(p_chemin))[2] = 'commandes'
     and exists (
       select 1 from public.boutiques b
       where b.id::text = (storage.foldername(p_chemin))[1] and b.statut in ('essai', 'actif', 'grace')
     );
$$;

-- Lecture publique des images de catalogue.
create policy lecture_images_publiques on storage.objects for select to anon, authenticated
  using (bucket_id in ('product-images', 'shop-assets'));

-- Images produits : « produits.ecrire » ; ressources du site : « site.gerer ».
create policy ecriture_product_images on storage.objects for all to authenticated
  using (bucket_id = 'product-images' and prive.dossier_ecriture_autorise((storage.foldername(name))[1], 'produits.ecrire'))
  with check (bucket_id = 'product-images' and prive.dossier_ecriture_autorise((storage.foldername(name))[1], 'produits.ecrire'));

create policy ecriture_shop_assets on storage.objects for all to authenticated
  using (bucket_id = 'shop-assets' and prive.dossier_ecriture_autorise((storage.foldername(name))[1], 'site.gerer'))
  with check (bucket_id = 'shop-assets' and prive.dossier_ecriture_autorise((storage.foldername(name))[1], 'site.gerer'));

create policy ecriture_images_editeur on storage.objects for all to authenticated
  using (bucket_id in ('product-images', 'shop-assets') and prive.est_admin_plateforme())
  with check (bucket_id in ('product-images', 'shop-assets') and prive.est_admin_plateforme());

-- Preuves de paiement : dépôt anonyme limité aux commandes, lecture par la boutique concernée et l'éditeur.
create policy depot_preuve_commande on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'payment-proofs' and prive.dossier_justificatif_commande_valide(name));

create policy lecture_preuves_boutique on storage.objects for select to authenticated
  using (
    bucket_id = 'payment-proofs'
    and (
      prive.est_admin_plateforme()
      or (storage.foldername(name))[1] in (select b::text from unnest(prive.boutiques_avec_permission('commandes.lire')) as b)
    )
  );

create policy ecriture_preuves_editeur on storage.objects for all to authenticated
  using (bucket_id = 'payment-proofs' and prive.est_admin_plateforme())
  with check (bucket_id = 'payment-proofs' and prive.est_admin_plateforme());
