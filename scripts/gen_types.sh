#!/usr/bin/env bash
# Génère les types TypeScript (apps web) et Dart (app mobile) à partir des migrations SQL.
# Les migrations sont appliquées dans PGlite (Postgres WASM) : aucun Docker requis.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -d scripts/node_modules ] || npm --prefix scripts install
node scripts/gen_types.mjs
