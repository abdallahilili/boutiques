#!/usr/bin/env bash
# Recrée la base locale (migrations + supabase/seed.sql) puis régénère les types.
set -euo pipefail
cd "$(dirname "$0")/.."
supabase db reset
./scripts/gen_types.sh
