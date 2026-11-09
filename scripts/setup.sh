#!/usr/bin/env bash
# Installe toutes les dépendances du monorepo.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "→ Outils (PGlite, Deno)"
npm --prefix scripts install

for app in app_admin app_boutique; do
  echo "→ $app"
  npm --prefix "apps/$app" install
done

echo "→ app_commercante (Flutter)"
(cd apps/app_commercante && flutter pub get && dart run build_runner build --delete-conflicting-outputs)

for f in supabase/functions/.env apps/app_admin/.env apps/app_boutique/.env apps/app_commercante/.env; do
  example="$f.example"
  [ -f "$example" ] && [ ! -f "$f" ] && cp "$example" "$f" && echo "→ créé $f (à compléter)"
done
echo "Terminé. Étape suivante : make db-start && make db-reset"
