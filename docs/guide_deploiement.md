# Guide de déploiement

## 1. Projet Supabase

```bash
supabase login
supabase link --project-ref <ref-du-projet>
supabase db push                      # applique supabase/migrations
```

Les migrations créent les tables, la RLS, les fonctions, les vues publiques, les buckets Storage, les rôles/permissions, le plan d'essai et les thèmes. `supabase/seed.sql` (plans payants d'exemple) n'est **pas** exécuté en production : créez vos plans depuis `app_admin`.

Réglages Auth (Dashboard → Authentication) :
- désactiver les inscriptions publiques (les comptes sont créés par les Edge Functions) ;
- activer MFA TOTP ;
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

1. Dashboard Supabase → Authentication → Users → *Add user* (email + mot de passe fort, « Auto confirm »).
2. SQL Editor :

```sql
insert into public.profils (id, nom_fr, email, role_plateforme)
select id, 'Éditeur', email, 'super_admin' from auth.users where email = 'vous@exemple.com';
```

À la première connexion sur `app_admin`, l'enrôlement TOTP est obligatoire. Les autres membres de l'équipe sont créés depuis *Utilisateurs internes*.

## 4. Applications web

Variables de build (voir README) : `VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY` ; pour la boutique, `VITE_DOMAINE_BASE`.

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
- Avant chaque mise en production : `make test` (dont l'isolement RLS entre deux boutiques).
