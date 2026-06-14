#!/usr/bin/env bash
# ── openDesk SME — Start ────────────────────
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

# Default: core + keycloak + opencloud
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml:idm/keycloak.yml:opencloud/opencloud.yml}"

echo "🚀 Starting openDesk SME..."
echo "   Compose file(s): ${COMPOSE_FILE}"

COMPOSE_FILE="$COMPOSE_FILE" docker compose up -d

echo ""
echo "✅ openDesk SME is starting up."
echo "   Endpoints:"
echo "   - Portal:       https://portal.${OPENDESK_DOMAIN:-opendesk.example.com}"
echo "   - Keycloak:     https://${KEYCLOAK_DOMAIN:-auth.opendesk.example.com}"
echo "   - Traefik:      https://traefik.${OPENDESK_DOMAIN:-opendesk.example.com}"
echo "   - OpenCloud:    https://${OPENCLOUD_DOMAIN:-cloud.opendesk.example.com}"
