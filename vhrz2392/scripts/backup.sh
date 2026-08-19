#!/bin/bash
set -e

# openDesk Backup Script (Zendis images)
# Automates backup of all service volumes
#
# Usage:
#   ./scripts/backup.sh                        # Full backup
#   ./scripts/backup.sh --dry-run              # Preview what would be backed up
#   ./scripts/backup.sh --services <list>       # Backup specific services

COMPOSE_PROJECT="${COMPOSE_PROJECT_NAME:-opendesk-compose}"

# Parse arguments
DRY_RUN=false
SERVICES=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --services)
      shift
      SERVICES="$1"
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--dry-run] [--services service1,service2,...]"
      exit 1
      ;;
  esac
done

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="backups"
BACKUP_FILE="${BACKUP_DIR}/backup-${TIMESTAMP}.tar.gz"

VOLUMES=(
  "pgdata"
  "casdoor_data"
  "casdoor_data"
  "opencloud_data"
  "notes_data"
  "cryptpad_data"
  "synapse_data"
  "stalwart_data"
  "sogo_data"
  "minio_data"
  "redis_data"
  "traefik-acme"
)

BACKUP_VOLS=()
if [ -z "$SERVICES" ]; then
  BACKUP_VOLS=("${VOLUMES[@]}")
else
  for vol in $(echo "$SERVICES" | tr ',' ' '); do
    found=false
    for v in "${VOLUMES[@]}"; do
      if [ "$v" = "$vol" ]; then
        BACKUP_VOLS+=("$v")
        found=true
        break
      fi
    done
    if [ "$found" = false ]; then
      echo "Error: Unknown volume '$vol'"
      echo "Available volumes: ${VOLUMES[*]}"
      exit 1
    fi
  done
fi

if [ ${#BACKUP_VOLS[@]} -eq 0 ]; then
  echo "No volumes to backup"
  exit 1
fi

if [ "$DRY_RUN" = true ]; then
  echo "DRY RUN — What would be backed up:"
  echo "  Backup file: $BACKUP_FILE"
  echo "  Volumes:"
  for vol in "${BACKUP_VOLS[@]}"; do
    echo "    - $vol"
  done
  exit 0
fi

echo "Stopping services for consistent backup..."
docker compose stop
sleep 10

mkdir -p "$BACKUP_DIR"

PARTIAL_DIR="${BACKUP_DIR}/partial-${TIMESTAMP}"
mkdir -p "$PARTIAL_DIR"

for vol in "${BACKUP_VOLS[@]}"; do
  FULL_VOL="${COMPOSE_PROJECT}_${vol}"
  echo "  Backing up $vol..."
  docker run --rm \
    -v "${FULL_VOL}:/data" \
    -v "$(pwd)/${PARTIAL_DIR}:/backups" \
    alpine:3.20 \
    tar czf "/backups/${vol}.tar.gz" -C /data .
done

echo "Combining backups..."
find "$PARTIAL_DIR" -name '*.tar.gz' | sort | while read -r part; do
  cat "$part"
done > "$BACKUP_FILE"
rm -rf "$PARTIAL_DIR"

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

echo "Restarting services..."
docker compose up -d
sleep 30

echo ""
echo "Backup completed!"
echo "  File: $BACKUP_FILE"
echo "  Size: $BACKUP_SIZE"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Backup completed: $BACKUP_FILE ($BACKUP_SIZE)" >> "${BACKUP_DIR}/backup.log"

# Cleanup: keep last 7 days
find "$BACKUP_DIR" -name "backup-*.tar.gz" -type f -mtime +7 -delete
echo "Retention: Keeping last 7 days"
