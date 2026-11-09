#!/usr/bin/env bash
# Rejoue uniquement supabase/seed.sql sur la base locale (sans toucher aux migrations).
set -euo pipefail
cd "$(dirname "$0")/.."
DB_URL="${DATABASE_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
psql "$DB_URL" -v ON_ERROR_STOP=1 -f supabase/seed.sql
