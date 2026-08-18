#!/usr/bin/env bash
# ── openDesk SME — Start ────────────────────
# Starts all configured services using COMPOSE_FILE.
# Defaults to core + keycloak + opencloud.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

DEFAULT_FILES="docker-compose.yml:idm/keycloak.yml:opencloud/opencloud.yml"
COMPOSE_FILE="${COMPOSE_FILE:-$DEFAULT_FILES}"

echo "🚀 Starting openDesk SME..."
echo "   Compose file(s): ${COMPOSE_FILE}"

docker compose up -d

echo ""
echo "✅ openDesk SME is starting up."
