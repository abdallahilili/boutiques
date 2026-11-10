# Plateforme SaaS « boutiques » — commandes de développement.
# Prérequis : Node 20+, Flutter 3.4x, Supabase CLI, Docker (pour la base locale), Deno (Edge Functions).
SHELL := /bin/bash

ADMIN_DIR    := apps/app_admin
BOUTIQUE_DIR := apps/app_boutique
MOBILE_DIR   := apps/app_commercante

.PHONY: help setup db-start db-stop db-reset db-push gen-types fn-serve admin boutique mobile \
        test test-db test-db-local test-admin test-boutique test-mobile test-fn lint lint-admin lint-boutique lint-mobile

help: ## Liste les commandes disponibles
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-14s %s\n", $$1, $$2}'

setup: ## Installe toutes les dépendances (outils, web, Flutter + code généré)
	./scripts/setup.sh

db-start: ## Démarre Supabase en local (Docker)
	supabase start

db-stop: ## Arrête Supabase local
	supabase stop

db-reset: ## Recrée la base locale : migrations + seed.sql
	./scripts/reset_db.sh

db-push: ## Applique les migrations sur le projet Supabase distant lié
	supabase db push

gen-types: ## Régénère les types TypeScript et Dart depuis les migrations
	./scripts/gen_types.sh

fn-serve: ## Sert les Edge Functions en local (secrets dans supabase/functions/.env)
	supabase functions serve --env-file supabase/functions/.env

admin: ## Lance la console éditeur (app_admin)
	npm --prefix $(ADMIN_DIR) run dev

boutique: ## Lance la boutique en ligne (app_boutique)
	npm --prefix $(BOUTIQUE_DIR) run dev

mobile: ## Lance l'app commerçante (Flutter) sur l'appareil/émulateur connecté
	cd $(MOBILE_DIR) && flutter run --dart-define-from-file=.env

test: test-db test-fn test-admin test-boutique test-mobile ## Lance toutes les suites de tests

test-db: ## Tests pgTAP (RLS, stock, numérotation, transferts) via Supabase CLI
	supabase test db

test-db-local: ## Mêmes tests SQL sans Docker (PGlite, shim pgTAP)
	npm --prefix scripts run test:db

test-fn: ## Vérifie le typage des Edge Functions et lance leurs tests unitaires
	cd supabase/functions && deno check */index.ts && deno test --allow-env --allow-net _shared/

test-admin:
	npm --prefix $(ADMIN_DIR) run test

test-boutique:
	npm --prefix $(BOUTIQUE_DIR) run test

test-mobile:
	cd $(MOBILE_DIR) && flutter test

lint: lint-admin lint-boutique lint-mobile ## Lint + typage de toutes les apps
	cd supabase/functions && deno lint

lint-admin:
	npm --prefix $(ADMIN_DIR) run lint && npm --prefix $(ADMIN_DIR) run typecheck

lint-boutique:
	npm --prefix $(BOUTIQUE_DIR) run lint && npm --prefix $(BOUTIQUE_DIR) run typecheck

lint-mobile:
	cd $(MOBILE_DIR) && flutter analyze
