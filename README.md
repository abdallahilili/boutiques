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
- Flutter 3.4x (Dart 3.9+) pour l'app mobile (Android Studio / Xcode pour les émulateurs)
- Aucune autre installation : la CLI Supabase et Deno sont des dépendances npm (`npm install` les télécharge). Docker n'est utile que pour un Supabase local (facultatif).

## Installation et lancement (projet Supabase hébergé)

Tout passe par npm, à la racine du dépôt :

```bash
npm install                # installe tout : outils, CLI Supabase, app_admin, app_boutique
npm run mobile:setup       # Flutter : flutter pub get + code généré (une fois)
```

1. Renseigner les `.env` (voir plus bas) avec l'URL et la clé publique du projet.
2. Initialiser le projet distant (une seule fois) :

```bash
npm run db:login           # ouvre le navigateur
npm run db:link            # demande le mot de passe de la base (projet kgwsdlgeldtfpjqdztup)
npm run db:push            # applique les migrations
npm run functions:secrets  # envoie supabase/functions/.env (PIN_SECRET…) vers Supabase
npm run functions:deploy   # déploie les Edge Functions
```

`npm run deploy` enchaîne `db:push`, `functions:secrets` et `functions:deploy` pour les mises à jour suivantes.
3. Créer le premier super-admin : [docs/guide_deploiement.md](docs/guide_deploiement.md) (section 3).
4. Lancer les apps :

```bash
npm run dev                # console éditeur  → http://localhost:5173
npm run dev:boutique       # boutique en ligne → http://localhost:5174 (ex. http://ma-boutique.localhost:5174)
npm run dev:mobile         # app Flutter sur l'appareil connecté (lit apps/app_commercante/.env)
```

Pour changer de projet Supabase, modifier `--project-ref` dans le script `db:link` de `package.json`.

## Commandes npm

| Commande | Rôle |
| --- | --- |
| `npm install` | Installe toutes les dépendances (racine, scripts, apps web) |
| `npm run mobile:setup` | `flutter pub get` + code généré (Drift) |
| `npm run dev` / `dev:admin` / `dev:boutique` / `dev:mobile` | Lance l'application correspondante |
| `npm run db:login` / `db:link` / `db:push` | Connexion, liaison et migrations du projet Supabase |
| `npm run functions:secrets` / `functions:deploy` / `deploy` | Secrets et déploiement des Edge Functions |
| `npm run gen:types` | Régénère les types TypeScript (web) et Dart (mobile) depuis les migrations |
| `npm test` | Toutes les suites (SQL, Deno, Vitest ×2, Flutter) ; chacune aussi seule : `test:db`, `test:functions`, `test:admin`, `test:boutique`, `test:mobile` |
| `npm run lint` | ESLint + `tsc` (web) et `flutter analyze` |
| `npm run build:admin` / `build:boutique` | Builds de production |

Option Supabase local (Docker) : `npx supabase start` puis `npx supabase db reset`, avec les `.env.example` (ils pointent sur `127.0.0.1:54321`).

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
npm test                   # SQL (211 tests : RLS, FIFO, stock ≥ 0, numérotation, commandes, Storage), Deno, Vitest ×2, Flutter
```

Les tests SQL s'exécutent dans PGlite (Postgres WASM) avec un substitut de pgTAP : pas de Docker requis. Avec Docker : `npx supabase test db`.

## Déploiement

Voir [docs/guide_deploiement.md](docs/guide_deploiement.md) : projet Supabase, migrations, secrets des Edge Functions, création du premier super-admin, hébergement des deux apps web (wildcard DNS), build Android.

## Licences tierces

- Police **Amiri** (SIL Open Font License 1.1) : `assets/fonts/` (mobile) et `public/fonts/` (web), utilisée pour l'arabe dans les PDF.
