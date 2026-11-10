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

## 6. Tâches planifiées, notifications push, domaines et export (phase 2)

**Secrets** (dans `supabase/functions/.env`, jamais commité, puis `npm run functions:secrets`) : `CRON_SECRET`, `WEBHOOK_SECRET` (>= 16 caractères, `openssl rand -hex 32`), `FCM_SERVICE_ACCOUNT` (JSON du compte de service Firebase sur une ligne), `DOMAIN_CNAME_TARGET`, et facultativement `VERCEL_TOKEN`, `VERCEL_PROJECT_ID`, `VERCEL_TEAM_ID`.

**Tâches quotidiennes** : `subscription-cron` (rappels J-7/J-3/J-1, grâce de 7 jours, suspension, expiration des devis) et `stock-alerts-cron` (ruptures, seuils bas, lots proches de l'expiration, impayés échus). Elles s'authentifient par l'en-tête `x-cron-secret`. Avec `pg_cron` + `pg_net` (extensions à activer dans le tableau de bord Supabase) :

```sql
select cron.schedule('subscription-cron', '0 6 * * *', $$
  select net.http_post(
    url := 'https://<projet>.supabase.co/functions/v1/subscription-cron',
    headers := jsonb_build_object('x-cron-secret', '<CRON_SECRET>', 'Content-Type', 'application/json'),
    body := '{}'::jsonb);
$$);
select cron.schedule('stock-alerts-cron', '10 6 * * *', $$
  select net.http_post(
    url := 'https://<projet>.supabase.co/functions/v1/stock-alerts-cron',
    headers := jsonb_build_object('x-cron-secret', '<CRON_SECRET>', 'Content-Type', 'application/json'),
    body := '{}'::jsonb);
$$);
```

Le même appel peut être fait par n'importe quel planificateur (`curl -X POST -H "x-cron-secret: ..."`). Ne placez pas le secret dans le dépôt : saisissez-le directement dans l'éditeur SQL.

**Push de nouvelle commande** : les notifications in-app sont créées par un trigger ; pour le push FCM, créer dans *Database → Webhooks* un webhook sur `INSERT` de `public.commandes` vers `…/functions/v1/on-order-created` avec l'en-tête `x-cron-secret: <WEBHOOK_SECRET>`.

**Firebase** : créer un projet Firebase, ajouter l'app Android (`google-services.json` dans `apps/app_commercante/android/app/`), générer une clé de compte de service (Paramètres du projet → Comptes de service) et la placer dans `FCM_SERVICE_ACCOUNT`. Sans cela, les notifications in-app fonctionnent et le push est simplement ignoré.

**Domaines personnalisés** : la commerçante saisit son domaine (plan qui l'autorise) ; `domain-verify` lit le DNS (DNS-over-HTTPS) et exige un `CNAME` vers `DOMAIN_CNAME_TARGET` (ou un `A` listé dans `DOMAIN_A_TARGETS`), puis rattache le domaine au projet Vercel si `VERCEL_TOKEN` et `VERCEL_PROJECT_ID` sont définis ; sinon le SSL reste « en attente ».

**Export** : `export-data` (propriétaire, 3 exports par heure) renvoie un CSV par table (UTF-8 avec BOM, séparateur « ; », ouvrable dans Excel), 20 000 lignes maximum par table.

## 7. Sauvegardes et exploitation

- Activer les sauvegardes quotidiennes Supabase (PITR sur plan Pro) et programmer un export mensuel externe.
- Surveiller les Edge Functions et les crons ; alerter sur les échecs.
- Avant chaque mise en production : `npm test` (dont l'isolement RLS entre deux boutiques).
