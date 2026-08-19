# openDesk Compose — Makefile
#
# SOTA test pyramid for SME Docker Compose deployments.
#
# Architecture: core services + optional Docker profiles
# Tiers: soho (4c/8G) | small (8c/24G) | medium (16c/48G)
#
# Profile mapping:
#   soho:   core only (9 containers)
#   small:  core + office + tika (11 containers)
#   medium: core + office + chat + collab + element + tika (13 containers)
#
# Quick start:
#   make bootstrap        # install deps
#   make test             # layers 0-3
#   make test-all         # layers 0-6
#   make lint             # static checks only
#   make host-check       # ansible dry-run
#   make up               # starts soho by default
#   make up PROFILE=small
#   make down

.PHONY: test test-all test-static lint host-check container smoke integration e2e security \
        docker-check compose-check env-check secret-scan shell-check yaml-check \
        ansible-check ansible-apply ansible-galaxy bootstrap clean help \
        up down status logs pull

.DEFAULT_GOAL := help

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
GREEN  := \033[0;32m
RED    := \033[0;31m
YELLOW := \033[1;33m
BLUE   := \033[0;34m
NC     := \033[0m

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
PROFILE    ?= soho
DOMAIN     ?= $(shell grep -m1 '^DOMAIN=' .env.production 2>/dev/null | cut -d= -f2 || echo 'localhost')
COMPOSE    ?= docker compose
TEST_ENV   ?= .env.production
PYTHON     ?= python3
ANSIBLE    ?= ansible-playbook

# ---------------------------------------------------------------------------
# Profile selection by tier
# ---------------------------------------------------------------------------
# soho:   core only — 9 containers (~2.3 GB)
#         Services: Traefik, PostgreSQL, Casdoor, Redis, Stalwart, SOGo,
#                   Invoice Ninja, Paperless, Paperless-Gotenberg
#
# small:  core + office + tika — 11 containers (~3.4 GB)
#         Adds: OpenCloud (file sharing), Paperless-Tika (enhanced OCR)
#
# medium: core + office + chat + collab + element + tika — 13 containers
#         Adds: Synapse (Matrix chat), Element-Web, CryptPad (collab docs)

ifeq ($(PROFILE),soho)
COMPOSE_FILES   := -f docker-compose.yml
COMPOSE_PROFILES :=
TIER_SERVICES   := core (9 containers)
else ifeq ($(PROFILE),small)
COMPOSE_FILES   := -f docker-compose.yml -f docker-compose.small.yml
COMPOSE_PROFILES := --profile office --profile tika
TIER_SERVICES   := core + office + tika (11 containers)
else ifeq ($(PROFILE),medium)
COMPOSE_FILES   := -f docker-compose.yml -f docker-compose.medium.yml
COMPOSE_PROFILES := --profile office --profile chat --profile collab --profile element --profile tika
TIER_SERVICES   := core + office + chat + collab + element + tika (13 containers)
else
$(error Unknown PROFILE "$(PROFILE)". Use: soho, small, or medium)
endif

FULL_COMPOSE  := $(COMPOSE) $(COMPOSE_FILES) $(COMPOSE_PROFILES)

# ---------------------------------------------------------------------------
# Docker Compose Operations
# ---------------------------------------------------------------------------
up:
	@echo -e "$(BLUE)── starting openDesk (profile: $(PROFILE), $(TIER_SERVICES)) ──$(NC)"
	@$(FULL_COMPOSE) --env-file $(TEST_ENV) up -d
	@echo -e "$(GREEN)✓ Stack started ($(TIER_SERVICES))$(NC)"

up-all:
	@echo -e "$(BLUE)── starting openDesk (ALL services, profile: $(PROFILE)) ──$(NC)"
	@$(FULL_COMPOSE) --env-file $(TEST_ENV) \
		--profile element --profile notes --profile memcached \
		up -d
	@echo -e "$(GREEN)✓ Stack started with all optional services$(NC)"

down:
	@$(FULL_COMPOSE) down --remove-orphans
	@echo -e "$(GREEN)✓ Stack stopped$(NC)"

down-volumes:
	@$(FULL_COMPOSE) down -v --remove-orphans
	@echo -e "$(RED)⚠ Volumes removed — data is gone!$(NC)"

status:
	@$(FULL_COMPOSE) ps

logs:
	@$(FULL_COMPOSE) logs -f --tail=100

pull:
	@$(FULL_COMPOSE) pull
	@echo -e "$(GREEN)✓ Images pulled$(NC)"

# ---------------------------------------------------------------------------
# Layer 0 — Static Validation (no containers needed)
# ---------------------------------------------------------------------------
lint: shell-check yaml-check compose-check env-check secret-scan
	@echo -e "$(GREEN)✅ All linting passed$(NC)"

shell-check:
	@echo -e "$(BLUE)── shellcheck ──$(NC)"
	@find scripts tests -name '*.sh' -exec shellcheck --severity=warning {} + 2>&1 || true

yaml-check:
	@echo -e "$(BLUE)── yamllint ──$(NC)"
	@yamllint -c tests/yamllint.yml docker-compose.yml docker-compose.*.yml .env.example 2>&1 || true

compose-check:
	@echo -e "$(BLUE)── docker compose config (profile: $(PROFILE)) ──$(NC)"
	@$(FULL_COMPOSE) --env-file $(TEST_ENV) config --quiet 2>&1
	@echo -e "$(GREEN)✓ compose config valid ($(PROFILE) profile)$(NC)"

env-check:
	@echo -e "$(BLUE)── env completeness ──$(NC)"
	@$(PYTHON) tests/00-static/check_env.py .env.example $(TEST_ENV) 2>&1

secret-scan:
	@echo -e "$(BLUE)── secret scanning ──$(NC)"
	@$(PYTHON) tests/00-static/scan_secrets.py . 2>&1

test-static: lint compose-check env-check secret-scan

# ---------------------------------------------------------------------------
# Layer 1 — Host Tuning (Ansible)
# ---------------------------------------------------------------------------
ansible-check:
	@echo -e "$(BLUE)── ansible check (profile: $(PROFILE)) ──$(NC)"
	@$(ANSIBLE) --check --diff --inventory localhost, \
		--connection local ansible/site.yml \
		-e "compose_profile=$(PROFILE)" 2>&1

ansible-apply:
	@echo -e "$(YELLOW)⚠ Applying host tuning (needs sudo, profile: $(PROFILE)) ──$(NC)"
	@$(ANSIBLE) --inventory localhost, \
		--connection local --become \
		ansible/site.yml \
		-e "compose_profile=$(PROFILE)" 2>&1

ansible-galaxy:
	@echo -e "$(BLUE)── ansible galaxy ──$(NC)"
	@ansible-galaxy collection install community.general community.docker ansible.posix --upgrade 2>&1 || true

host-check: ansible-check

# ---------------------------------------------------------------------------
# Layer 2+ — Require running stack
# ---------------------------------------------------------------------------
container:
	@echo -e "$(BLUE)── layer 2: container health ──$(NC)"
	@bash tests/02-container/run.sh $(DOMAIN)

smoke:
	@echo -e "$(BLUE)── layer 3: smoke tests ──$(NC)"
	@bash tests/03-smoke/run.sh $(DOMAIN)

integration:
	@echo -e "$(BLUE)── layer 4: integration ──$(NC)"
	@$(PYTHON) tests/04-integration/test_integration.py --domain $(DOMAIN)

e2e:
	@echo -e "$(BLUE)── layer 5: e2e playwright ──$(NC)"
	@cd tests/05-e2e && npx playwright test --project=chromium 2>&1

security:
	@echo -e "$(BLUE)── layer 6: security audit ──$(NC)"
	@bash tests/06-security/run.sh $(DOMAIN)

# ---------------------------------------------------------------------------
# Combined targets
# ---------------------------------------------------------------------------
test: test-static host-check
	@echo -e "$(BLUE)═══ container + smoke (stack must be running) ═══$(NC)"
	@$(MAKE) container smoke

test-all: test
	@$(MAKE) integration e2e security
	@echo -e "$(GREEN)═══════════════════════════════════$(NC)"
	@echo -e "$(GREEN) All test layers complete.$(NC)"
	@echo -e "$(GREEN)═══════════════════════════════════$(NC)"

# ---------------------------------------------------------------------------
# Bootstrap / Cleanup
# ---------------------------------------------------------------------------
bootstrap:
	@echo -e "$(BLUE)── bootstrapping ──$(NC)"
	@cp .env.example .env.production 2>/dev/null || true
	@$(MAKE) ansible-galaxy
	@cd tests/05-e2e && npm install 2>/dev/null || true
	@echo -e "$(GREEN)✅ Bootstrap complete$(NC)"

clean:
	@rm -rf tests/05-e2e/test-results/ tests/05-e2e/playwright-report/
	@rm -f /tmp/opendesk-test-*.json

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
help:
	@echo ""
	@echo -e "$(BLUE)openDesk Compose -- Makefile (PROFILE=$(PROFILE))$(NC)"
	@echo ""
	@echo -e "  $(GREEN)Architecture: core + optional profiles$(NC)"
	@echo "    Core (always on): Traefik, PostgreSQL, Casdoor (SSO),"
	@echo "                     Redis, Stalwart, SOGo, Invoice Ninja,"
	@echo "                     Paperless-ngx, Paperless-Gotenberg"
	@echo "    --profile office   OpenCloud (file sharing)"
	@echo "    --profile chat     Synapse (Matrix chat)"
	@echo "    --profile collab   CryptPad (collaborative docs)"
	@echo "    --profile element  Element-Web (Matrix web client)"
	@echo "    --profile notes    Notes/Impress (3 containers + MinIO)"
	@echo "    --profile tika     Paperless-Tika (enhanced OCR)"
	@echo "    --profile memcached Memcached cache layer"
	@echo ""
	@echo -e "  $(GREEN)VPS Tiers (auto-select profiles)$(NC)"
	@echo "    make up PROFILE=soho     4c /  8 GB / 120 GB  (core only, 9 containers)"
	@echo "    make up PROFILE=small    8c / 24 GB / 480 GB  (core+office+tika, 11 containers)"
	@echo "    make up PROFILE=medium  16c / 48 GB / 960 GB  (core+office+chat+collab+element+tika, 13 containers)"
	@echo ""
	@echo -e "  $(GREEN)Operations$(NC)"
	@echo "    make up                  Start stack (PROFILE=soho|small|medium)"
	@echo "    make up-all              Start with ALL optional services"
	@echo "    make down                Stop stack"
	@echo "    make down-volumes        Stop + remove volumes (data loss!)"
	@echo "    make status              Show container status"
	@echo "    make logs                Tail logs"
	@echo "    make pull                Pull images"
	@echo ""
	@echo -e "  $(GREEN)Testing$(NC)"
	@echo "    make test                Layers 0-3 (static + host + container + smoke)"
	@echo "    make test-all            Layers 0-6 (full suite)"
	@echo "    make test-static         Layer 0 only (lint + config + secrets)"
	@echo "    make lint                Shellcheck + yamllint + compose config"
	@echo "    make host-check          Ansible host tuning dry-run (PROFILE aware)"
	@echo "    make container           Layer 2 -- container health"
	@echo "    make smoke               Layer 3 -- HTTP/SSL/port smoke"
	@echo "    make integration         Layer 4 -- OIDC, email, API tests"
	@echo "    make e2e                 Layer 5 -- Playwright browser tests"
	@echo "    make security            Layer 6 -- secrets, privileges, TLS"
	@echo ""
	@echo -e "  $(GREEN)Ansible Host Tuning$(NC)"
	@echo "    make host-check          Dry-run (no changes)"
	@echo "    make ansible-apply       Apply tuning (needs sudo)"
	@echo ""
	@echo -e "  $(GREEN)Other$(NC)"
	@echo "    make bootstrap           Install deps (ansible, playwright)"
	@echo "    make clean               Remove test artifacts"
	@echo ""
