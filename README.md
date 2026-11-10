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
- [Supabase CLI](https://supabase.com/docs/guides/local-development) (déploiement des migrations et des fonctions) ; Docker uniquement pour l'option locale — les tests SQL tournent aussi sans Docker (`make test-db-local`)
- Deno 2 (Edge Functions) — installé aussi par `make setup` (dépendance npm `deno` dans `scripts/`)
- `make` (Git Bash / WSL sous Windows)

## Installation (projet Supabase hébergé)

Les apps utilisent un projet Supabase **hébergé** ; aucun Docker n'est nécessaire.

```bash
make setup                     # dépendances npm (outils, 2 apps web), flutter pub get, code généré, fichiers .env
# 1. Renseigner les .env (voir « Variables d'environnement ») avec l'URL et la clé publique du projet
# 2. Initialiser le projet distant (une seule fois) :
supabase login
supabase link --project-ref <ref-du-projet>          # la « ref » est le début de l'URL : https://<ref>.supabase.co
make db-push                                         # applique les migrations sur le projet distant
supabase secrets set PIN_SECRET="$(openssl rand -hex 32)" PHONE_EMAIL_DOMAIN=tel.invalid PAYS_INDICATIF=222
supabase functions deploy connexion_telephone_pin inscription-cliente admin-create-merchant admin-create-staff   invite-member reset-pin changer-code send-notification
# 3. Créer le premier super-admin : docs/guide_deploiement.md (section 3)

make admin        # http://localhost:5173
make boutique     # http://localhost:5174  (ex. http://ma-boutique.localhost:5174)
make mobile       # app Flutter sur l'appareil connecté (lit apps/app_commercante/.env)
```

`make gen-types` régénère les types TypeScript/Dart depuis les migrations (sans base ni Docker).

### Windows (PowerShell) sans `make` ni CLI installée

`make` et la CLI Supabase ne sont pas fournis avec Windows. Équivalents sans rien installer de plus que Node :

```powershell
npm --prefix scripts install; npm --prefix apps/app_admin install; npm --prefix apps/app_boutique install
cd apps/app_commercante; flutter pub get; dart run build_runner build; cd ../..
npx supabase@latest login
npx supabase@latest link --project-ref <ref-du-projet>
npx supabase@latest db push
npx supabase@latest secrets set PIN_SECRET=<64-caractères-hex> PHONE_EMAIL_DOMAIN=tel.invalid PAYS_INDICATIF=222
npx supabase@latest functions deploy connexion_telephone_pin inscription-cliente admin-create-merchant admin-create-staff invite-member reset-pin changer-code send-notification
npm --prefix apps/app_admin run dev          # make admin
npm --prefix apps/app_boutique run dev       # make boutique
cd apps/app_commercante; flutter run --dart-define-from-file=.env   # make mobile
```

### Alternative : Supabase local (Docker)

Pour développer sans toucher au projet distant : `make db-start`, `make db-reset`, `make fn-serve`, avec les `.env.example` (ils pointent sur `127.0.0.1:54321`).

## Commandes `make`

| Commande | Rôle |
| --- | --- |
| `setup` | Installe toutes les dépendances et crée les `.env` depuis les `.env.example` |
| `db-start` / `db-stop` | (option locale) Démarre / arrête Supabase local via Docker |
| `db-reset` | (option locale) Recrée la base locale (migrations + `supabase/seed.sql`) et régénère les types |
| `db-push` | Applique les migrations sur le projet Supabase distant lié |
| `gen-types` | Régénère les types TypeScript (web) et Dart (mobile) depuis les migrations |
| `fn-serve` | (option locale) Sert les Edge Functions en local |
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
make test-db-local          # 211 tests SQL : RLS, FIFO, stock ≥ 0, numérotation, commandes, Storage
cd supabase/functions && deno test --allow-env --allow-net _shared/
npm --prefix apps/app_admin run test
npm --prefix apps/app_boutique run test
cd apps/app_commercante && flutter test      # (build_runner requis une fois : make setup)
```

## Déploiement

Voir [docs/guide_deploiement.md](docs/guide_deploiement.md) : projet Supabase, migrations, secrets des Edge Functions, création du premier super-admin, hébergement des deux apps web (wildcard DNS), build Android.

## Licences tierces

- Police **Amiri** (SIL Open Font License 1.1) : `assets/fonts/` (mobile) et `public/fonts/` (web), utilisée pour l'arabe dans les PDF.
