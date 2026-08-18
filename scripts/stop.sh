#!/usr/bin/env bash
# ── openDesk SME — Stop ─────────────────────
# Stops all running opendesk containers in the current project.
# Uses 'docker compose down' with the same COMPOSE_FILE that was used
# to start (default: core + keycloak + opencloud), falling back to
# stopping any remaining opendesk-* containers.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml:idm/keycloak.yml:opencloud/opencloud.yml}"

echo "🛑 Stopping openDesk SME..."

# Try compose down with the expected files
COMPOSE_FILE="$COMPOSE_FILE" docker compose down --remove-orphans 2>/dev/null || true

# Catch any remaining opendesk containers that may have been
# started with a different compose file combination
REMAINING=$(docker ps --filter "name=opendesk-" --format '{{.Names}}' 2>/dev/null || true)
if [ -n "$REMAINING" ]; then
  echo "   Stopping leftover containers: ${REMAINING}"
  echo "$REMAINING" | xargs -r docker stop 2>/dev/null || true
  echo "$REMAINING" | xargs -r docker rm 2>/dev/null || true
fi

echo "✅ openDesk SME stopped."
