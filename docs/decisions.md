# Décisions d'architecture et plan de réalisation

Source de vérité fonctionnelle : [cahier_des_charges.md](cahier_des_charges.md).
En cas de conflit entre le cahier et ce document, **ce document prime**.

## 1. Décisions imposées

| Sujet | Décision |
| --- | --- |
| Backend | Supabase uniquement (PostgreSQL, Auth, Storage, Edge Functions, Realtime). Aucun autre serveur. |
| Mobile | Flutter, **GetX** (état, navigation, injection). Pas de Riverpod. Cache hors ligne Drift/SQLite, file d'attente (outbox), UUID générés côté appareil, opérations idempotentes. |
| Web | React + Vite + TypeScript, TanStack Query, react-router, i18next, Tailwind. Pas de Next.js. Balises SEO via React Helmet (paquet maintenu `react-helmet-async`). |
| Langues | Arabe par défaut (RTL) dans les 3 apps, bascule en français. Fichiers de traduction `ar` et `fr`. |
| Base de données | Noms de tables, colonnes, statuts et fonctions SQL en français (snake_case sans accents). Chaque nom a `nom_ar` / `nom_fr` (idem `description_ar` / `description_fr`). Multi-tenant par `boutique_id` + RLS sur toutes les tables, aucune table sans politique. |
| Authentification mobile + boutique en ligne | Identifiant = numéro de téléphone, mot de passe = code à 4 chiffres. Edge Function `connexion_telephone_pin` : le code est converti côté serveur en secret d'authentification (HMAC-SHA256 avec un poivre serveur), 5 tentatives puis verrouillage temporaire. |
| Authentification admin | Email + mot de passe + 2FA TOTP (MFA Supabase Auth). |
| PDF | **Aucun PDF enregistré.** Documents (devis, BL, facture, avoir, ticket) stockés en base : en-tête figé (`jsonb`) + lignes + paiements. PDF généré à la demande côté appareil (`pdf` + `printing`) ou côté web (`@react-pdf/renderer`). Pas de bucket `documents`, pas de colonne `pdf_url`. |
| Fiscalité | **Aucune taxe, TVA ni fiscalité** : ni table, ni colonne, ni champ, ni écran. |
| Sous-domaine | Attribué à la création, non modifiable par la commerçante (lecture seule dans le mobile) ; modifiable uniquement depuis `app_admin` (garanti par trigger). Domaine personnalisé configurable. |
| Catalogue | Catégories ordonnables (colonne `ordre`), produits épinglables en tête (`epingle`, `ordre_epinglage`) et appliqué sur la boutique en ligne. |
| Stock | Jamais modifié directement : mouvements (`mouvements_stock`, append-only) et lots (`lots_stock`). Consommation FIFO (FEFO si date d'expiration), coût figé sur les lignes de vente. Stock négatif interdit par défaut. |
| Transferts | A envoie (vente chez A, sortie FIFO), B reçoit (achat chez B, lots au prix de cession). États : `brouillon`, `envoye`, `accepte`, `refuse`, `annule`. Refus/annulation = remise en stock + avoir. Uniquement via `envoyer_transfert` / `repondre_transfert` (SECURITY DEFINER). |
| Opérations sensibles | Fonctions SQL transactionnelles et idempotentes ; numéros sans trou, plages réservées par appareil pour le hors ligne. |
| Secrets | `service_role` jamais côté client ; secrets uniquement dans les variables des Edge Functions ; `.env.example` fournis. |
| Devise | MRU par défaut. FCM : table `appareils` + Edge Function `send-notification` (stub) ; Firebase configuré plus tard. |

## 2. Décisions d'implémentation (précisions et écarts assumés)

- **RLS par appartenance, pas par claims JWT.** Le cahier évoque des claims `boutique_id`/`role` dans le JWT. Une commerçante peut posséder plusieurs boutiques et une révocation doit être immédiate : les politiques s'appuient donc sur `prive.mes_boutiques()` et `prive.a_permission()` (lecture de `membres_boutique`), évalués une fois par requête.
- **Helpers dans le schéma `prive`** (non exposé par PostgREST). Seules les fonctions métier voulues par le cahier (`boutique_est_active`, RPC) vivent dans `public`.
- **Écritures sensibles uniquement par RPC.** `lots_stock`, `mouvements_stock`, `documents_vente`, `lignes_document_vente`, `paiements`, `commandes`… n'ont aucune politique d'écriture pour les clients : seules les fonctions `SECURITY DEFINER` écrivent. L'immuabilité d'une facture émise en découle.
- **Clés étrangères composites `(boutique_id, id)`** entre tables métier : impossible de référencer la donnée d'une autre boutique, même avec un `boutique_id` forgé.
- **Authentification : identité Auth synthétique.** Le numéro de téléphone normalisé est converti en email technique `<chiffres>@tel.invalid` (pas de dépendance à un fournisseur SMS). Les clientes de la boutique en ligne ont une identité Auth **distincte par boutique** (`c.<boutique>.<chiffres>@tel.invalid`) : un code à 4 chiffres ne peut donc pas être partagé ni verrouillé entre rôles.
- **Période de grâce = écriture autorisée** (bandeau d'alerte, §10.2). Seul `suspendu`/`ferme` bloque l'écriture (lecture seule conservée). `boutique_est_active()` renvoie vrai pour `essai`, `actif`, `grace`.
- **Réservation de stock à la création de la commande en ligne** (critère d'acceptation du §11.4) ; libérée à l'annulation, consommée à la livraison / génération du document.
- **Stock négatif optionnel** (`boutiques.parametres.stock_negatif_autorise`) : le manque est porté par un lot « découvert » (quantité négative) absorbé par les réceptions suivantes ; l'invariant « stock = somme des lots » est conservé.
- **Types générés sans Docker** : `scripts/gen_types.mjs` applique les migrations dans PGlite puis introspecte le catalogue pour produire `database.ts` (web) et `database_types.dart` (mobile).
- **Tests SQL** : fichiers pgTAP dans `supabase/tests/` (`supabase test db`). Sans Docker, `make test-db-local` rejoue les mêmes fichiers dans PGlite avec un shim pgTAP (`scripts/pglite/`).
- **Nom du paquet SEO** : `react-helmet-async` (fork maintenu de React Helmet, compatible React 18/19).

## 3. Plan par phase

### Phase 0 — Socle
1. Monorepo, Makefile, README, `.gitignore`, `.gitattributes`, scripts.
2. `supabase/config.toml`, migrations de base (profils, commercantes, boutiques, membres_boutique, roles, permissions_role, plans, abonnements, paiements_abonnement, journal_audit, appareils, notifications), RLS, `boutique_est_active`.
3. Edge Functions `connexion_telephone_pin`, `admin-create-merchant`, `invite-member` + `_shared`.
4. Génération des types (TS + Dart).
5. Squelettes des 3 apps : i18n ar/fr + RTL, thème, routing, authentification.
6. Tests pgTAP (isolement RLS de base), tests Vitest / Flutter de l'authentification.

### Phase 1 — MVP
1. Migrations : référentiels, produits, stock, ventes/documents, commandes, site, fonctions métier, Storage.
2. `app_admin` : tableau de bord, commerçantes, boutiques, plans, abonnements, paiements, sites/sous-domaines, utilisateurs internes, audit, notifications.
3. `app_commercante` : onboarding, référentiels, produits/variantes, stock, POS (scan, paiements multiples, ventes suspendues, session de caisse), facture PDF à la demande + WhatsApp, clients, commandes temps réel.
4. `app_boutique` : résolution par domaine, accueil, catalogue, fiche produit, panier, checkout, suivi, compte cliente, thèmes (variables CSS), SEO, PWA.
5. Tests : pgTAP (RLS toutes tables, FIFO, stock ≥ 0, numérotation), Flutter, Vitest.

### Phase 2 — V1 (hors périmètre de cette livraison)
Devis, BL, avoirs, conversion, transferts, gestion du site depuis le mobile, rapports, hors ligne complet, impression Bluetooth, domaines personnalisés (`domain-verify`), FCM, crons, export.

## 4. Journal des phases

### Phase 0 — Socle (terminée)

**Fait**
- Monorepo, Makefile, scripts, README, guide de déploiement, `.gitignore` / `.gitattributes`.
- Migrations : `profils`, `commercantes`, `boutiques`, `permissions`, `roles`, `permissions_role`, `membres_boutique`, `plans`, `abonnements`, `paiements_abonnement`, `journal_audit` (immuable), `appareils`, `notifications`, `tentatives_connexion` ; helpers RLS (`prive.*`), `boutique_est_active`, quotas de plan, triggers de protection de colonnes (slug, statut, rôles), audit.
- Edge Functions : `connexion_telephone_pin`, `admin-create-merchant`, `invite-member`, `reset-pin`, `changer-code` + modules partagés testés (Deno).
- Génération des types TypeScript et Dart (`scripts/gen_types.mjs`, sans Docker).
- Squelettes : `app_admin` (login + 2FA TOTP obligatoire, i18n ar/fr + RTL, thème clair/sombre), `app_boutique` (i18n, RTL, thème par variables CSS, connexion cliente, Helmet), `app_commercante` (GetX, ARB ar/fr, RTL, thème, routage + garde, connexion téléphone + code).
- Tests : 47 tests SQL (RLS, quotas, audit, verrouillage), 8 Deno, 9 + 11 Vitest, 15 Flutter.

**Reste** : voir la phase 1.

