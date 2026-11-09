# Boutiques — plateforme SaaS de gestion de boutique pour commerçantes

Monorepo de trois applications adossées à **un seul projet Supabase** (PostgreSQL, Auth, Storage, Edge Functions, Realtime) :

| Dossier | Application | Technologie |
| --- | --- | --- |
| [apps/app_admin](apps/app_admin) | Console éditeur (commerçantes, boutiques, plans, abonnements, sites, audit) | React + Vite + TypeScript |
| [apps/app_boutique](apps/app_boutique) | Boutique en ligne multi-tenant (un domaine = une boutique) | React + Vite + TypeScript, PWA |
| [apps/app_commercante](apps/app_commercante) | App mobile commerçante (caisse, stock, commandes) — le vrai produit | Flutter + GetX + Drift |
| [supabase](supabase) | Migrations SQL, Edge Functions, seed, tests pgTAP | PostgreSQL / Deno |

Langue par défaut : **arabe (RTL)** dans les trois apps, bascule en **français**. Devise par défaut : MRU.
Spécification : [docs/cahier_des_charges.md](docs/cahier_des_charges.md) · décisions et état d'avancement : [docs/decisions.md](docs/decisions.md) · déploiement : [docs/guide_deploiement.md](docs/guide_deploiement.md).

## Prérequis

- Node.js 20+ et npm
- Flutter 3.4x (Dart 3.9+) — Android Studio / Xcode pour les émulateurs
- [Supabase CLI](https://supabase.com/docs/guides/local-development) et Docker (base locale) — *optionnels pour les tests SQL, voir `make test-db-local`*
- Deno 2 (Edge Functions) — installé aussi par `make setup` (dépendance npm `deno` dans `scripts/`)
- `make` (Git Bash / WSL sous Windows)

## Installation

```bash
make setup        # dépendances npm (outils, 2 apps web), flutter pub get, code généré, fichiers .env
make db-start     # Supabase local (Docker)
make db-reset     # migrations + seed + régénération des types
make fn-serve     # Edge Functions (dans un 2e terminal)
make admin        # http://localhost:5173
make boutique     # http://localhost:5174  (ex. http://ma-boutique.localhost:5174)
make mobile       # app Flutter sur l'appareil connecté
```

## Commandes `make`

| Commande | Rôle |
| --- | --- |
| `setup` | Installe toutes les dépendances et crée les `.env` depuis les `.env.example` |
| `db-start` / `db-stop` | Démarre / arrête Supabase local |
| `db-reset` | Recrée la base locale (migrations + `supabase/seed.sql`) et régénère les types |
| `db-push` | Applique les migrations sur le projet Supabase distant lié |
| `gen-types` | Régénère les types TypeScript (web) et Dart (mobile) depuis les migrations |
| `fn-serve` | Sert les Edge Functions en local |
| `admin` / `boutique` / `mobile` | Lance l'application correspondante |
| `test` | Toutes les suites : pgTAP, Deno, Vitest (×2), Flutter |
| `test-db` | Tests pgTAP via Supabase CLI (Docker) |
| `test-db-local` | Mêmes tests SQL **sans Docker** (PGlite + shim pgTAP) |
| `lint` | ESLint + `tsc` (web), `flutter analyze`, `deno lint` |

## Variables d'environnement

Aucun secret n'est commité : seuls les `.env.example` le sont.

| Fichier | Variable | Rôle |
| --- | --- | --- |
| `apps/app_admin/.env`, `apps/app_boutique/.env` | `VITE_SUPABASE_URL` | URL du projet Supabase |
| | `VITE_SUPABASE_PUBLISHABLE_KEY` | Clé **publique** (anon / publishable) |
| `apps/app_boutique/.env` | `VITE_DOMAINE_BASE` | Domaine de base des sous-domaines (`plateforme.com`, `localhost` en dev) |
| | `VITE_BOUTIQUE_SLUG` | (dev) boutique par défaut quand l'URL n'a pas de sous-domaine |
| `apps/app_commercante/.env` | `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` | Injectées par `--dart-define-from-file=.env` |
| `supabase/functions/.env` | `PIN_SECRET` | Poivre de conversion du code à 4 chiffres en secret d'authentification (≥ 16 car., **ne jamais changer** en production) |
| | `PHONE_EMAIL_DOMAIN`, `PAYS_INDICATIF` | Domaine technique des identités Auth (`tel.invalid`) et indicatif pays (`222`) |
| | `SUPABASE_SERVICE_ROLE_KEY` | Injectée par Supabase dans les Edge Functions ; **jamais** côté client |

> La clé `service_role` (ou « secret key ») ne doit exister que dans les Edge Functions. Si elle a été partagée ailleurs, la régénérer dans Supabase.

## Architecture en bref

- **Multi-tenant** : `boutique_id` sur toutes les tables métier, RLS par appartenance (`membres_boutique`), clés étrangères composites `(boutique_id, id)`.
- **Opérations sensibles** (vente, stock, numérotation, commande, transfert) : fonctions SQL `SECURITY DEFINER` transactionnelles et idempotentes ; les clients n'écrivent jamais directement dans le stock ni dans les documents.
- **Stock** : lots + mouvements en ajout seul, consommation FIFO/FEFO, coût figé sur les lignes de vente, jamais négatif par défaut.
- **Authentification** : téléphone + code à 4 chiffres via l'Edge Function `connexion_telephone_pin` (5 tentatives puis verrouillage) ; admin web : email + mot de passe + 2FA TOTP.
- **Documents** : aucun PDF stocké ; en-tête figé en base, PDF généré à la demande sur l'appareil ou le navigateur.
- **Aucune taxe / TVA** dans le modèle de données.

## Tests

```bash
make test-db-local          # 200+ tests SQL : RLS, FIFO, stock ≥ 0, numérotation, commandes, Storage
cd supabase/functions && deno test --allow-env --allow-net _shared/
npm --prefix apps/app_admin run test
npm --prefix apps/app_boutique run test
cd apps/app_commercante && flutter test
```

## Déploiement

Voir [docs/guide_deploiement.md](docs/guide_deploiement.md) : projet Supabase, migrations, secrets des Edge Functions, création du premier super-admin, hébergement des deux apps web (wildcard DNS), build Android.
