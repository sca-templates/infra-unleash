SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

COMPOSE_FILE := compose.yml
COMPOSE_PROJECT_NAME := unleash
COMPOSE := docker compose -f $(COMPOSE_FILE) -p $(COMPOSE_PROJECT_NAME)
# Vault is a sibling project in this repo (aws/vault)
VAULT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))/../vault

.PHONY: help
help:
	@echo 'unleash — Feature flag management (Unleash server + private Postgres)'
	@echo ''
	@echo '  make setup         First time: Vault secrets + .env (idempotent)'
	@echo '  make all           setup + up + validate (all-in-one)'
	@echo '  make up            Start Unleash (imports the flags-as-code seed)'
	@echo '  make validate      Verify containers, health and seeded flag'
	@echo ''
	@echo '  make vault-secrets Store admin + DB passwords in Vault'
	@echo '  make env           Generate .env from Vault'
	@echo ''
	@echo '  make down          Stop and remove stack'
	@echo '  make restart       down + up'
	@echo '  make stop          Stop without removing'
	@echo '  make logs          Live logs'
	@echo '  make ps            Container status'
	@echo '  make clean         down -v + remove .env'

.PHONY: vault-secrets
vault-secrets:
	@echo '=== Storing UNLEASH secrets in Vault ==='
	scripts/vault-secrets.sh

.PHONY: env
env:
	@echo '=== Generating .env from Vault ==='
	scripts/gen-env.sh

.PHONY: setup
setup: vault-secrets env
	@echo '=== Setup complete. Next: make up ==='

.PHONY: up
up:
	@echo '=== Starting Unleash ==='
	$(COMPOSE) up -d

.PHONY: validate
validate:
	@echo '=== Validating Unleash ==='
	scripts/validate.sh

.PHONY: all
all: setup up validate
	@echo ''
	@echo '============================================'
	@echo '  Unleash ready:'
	@echo '  UI/API : http://127.0.0.1:4242  (admin creds in Vault secret/unleash/dev)'
	@echo '  Seed   : unleash/sca-flags.json imported on start (flags-as-code)'
	@echo '============================================'

.PHONY: down
down:
	@echo '=== Stopping stack ==='
	$(COMPOSE) down

.PHONY: restart
restart: down up

.PHONY: stop
stop:
	$(COMPOSE) stop

.PHONY: logs
logs:
	$(COMPOSE) logs -f

.PHONY: ps
ps:
	$(COMPOSE) ps

.PHONY: clean
clean:
	@echo '=== Cleaning up ==='
	-$(COMPOSE) down -v 2>/dev/null || true
	rm -f .env
	@echo 'Done.'
