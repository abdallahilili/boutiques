# Guide de déploiement

## 1. Projet Supabase

```bash
npm run db:login
npm run db:link                       # projet lié (voir package.json)
npm run db:push                       # applique supabase/migrations
```

Les migrations créent les tables, la RLS, les fonctions, les vues publiques, les buckets Storage, les rôles/permissions, le plan d'essai et les thèmes. `supabase/seed.sql` (plans payants d'exemple) n'est **pas** exécuté en production : créez vos plans depuis `app_admin`.

Réglages Auth (Dashboard → Authentication) :
- désactiver les inscriptions publiques (les comptes sont créés par les Edge Functions) ;
- ajouter les URL de l'admin web dans les URL de redirection.

## 2. Edge Functions

```bash
supabase secrets set PIN_SECRET="$(openssl rand -hex 32)" PHONE_EMAIL_DOMAIN=tel.invalid PAYS_INDICATIF=222
supabase functions deploy connexion_telephone_pin inscription-cliente admin-create-merchant admin-create-staff \
  invite-member reset-pin changer-code send-notification
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY` et `SUPABASE_SERVICE_ROLE_KEY` sont injectées automatiquement.

> `PIN_SECRET` ne doit **jamais** être modifié après la mise en production : tous les codes à 4 chiffres existants deviendraient invalides. Conservez-le dans un coffre de secrets.

## 3. Premier super-admin

Après `npm run db:push` :

```bash
npm run admin:create -- 31177008 "MotDePasse" "Nom complet"
```

Le script lit `SUPABASE_URL` et `SUPABASE_SERVICE_ROLE_KEY` dans `supabase/functions/.env` (jamais commité), crée l'utilisateur Auth et son profil `super_admin`. Connexion sur `app_admin` avec le numéro de téléphone et le mot de passe (8 caractères minimum) ; relancer la commande remplace le mot de passe. Les autres membres de l'équipe sont créés depuis *Utilisateurs internes*.

## 4. Applications web

Variables de build (voir README) : `VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY` ; pour la boutique, `VITE_DOMAINE_BASE`.
Images : servies telles quelles (valable sur tous les plans Supabase). Sur le plan Pro, ajouter `VITE_IMAGE_TRANSFORMS=true` au build de la boutique pour activer le redimensionnement WebP des transformations Storage.

- **app_admin** : `npm --prefix apps/app_admin run build` → publier `dist/` (Vercel, Netlify ou Cloudflare Pages) avec réécriture SPA vers `index.html`.
- **app_boutique** : même build ; configurer un **domaine wildcard** `*.votreplateforme.com` vers le même déploiement. Chaque boutique est résolue par sous-domaine via la fonction SQL `resoudre_boutique`. Les domaines personnalisés (plans Premium) se déclarent dans la console et se rattachent au déploiement (phase 2 : vérification DNS automatisée).

## 5. Application Android

```bash
cd apps/app_commercante
flutter build apk --release --dart-define-from-file=.env
flutter build appbundle --release --dart-define-from-file=.env
```

Signature : créer `android/key.properties` (jamais commité) et référencer le keystore dans `android/app/build.gradle.kts`.

## 6. Sauvegardes et exploitation

- Activer les sauvegardes quotidiennes Supabase (PITR sur plan Pro) et programmer un export mensuel externe.
- Surveiller les Edge Functions et les crons (phase 2) ; alerter sur les échecs.
- Avant chaque mise en production : `npm test` (dont l'isolement RLS entre deux boutiques).
