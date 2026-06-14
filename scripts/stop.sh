#!/usr/bin/env bash
# ── openDesk SME — Stop ─────────────────────
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"

echo "🛑 Stopping openDesk SME..."
COMPOSE_FILE="$COMPOSE_FILE" docker compose down
echo "✅ openDesk SME stopped."
