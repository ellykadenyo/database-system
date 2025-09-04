#!/usr/bin/env bash
# Author: Elly Kadenyo
# Date: 2025-09-01 2025-09-04
# Description: Script to backup PostgreSQL database to S3
# Usage: bash scripts/backup.sh
# Make sure it is executable # chmod +x scripts/backup.sh
set -euo pipefail
LOG(){ echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') [backup] $*"; }

if [ ! -f .env ]; then
  LOG "ERROR: .env missing. Copy .env.example -> .env and fill values"
  exit 1
fi
source .env

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_FILE="/tmp/backup_${TIMESTAMP}.sql.gz"

LOG "Running pg_dump via docker run..."
docker run --rm \
  -e PGPASSWORD="${POSTGRES_PASSWORD}" \
  postgres:17 \
  bash -c "pg_dump -h citus_coordinator -U ${POSTGRES_USER} -d ${POSTGRES_DB} | gzip -c" > "${OUT_FILE}"

LOG "Uploading ${OUT_FILE} to s3://${S3_BUCKET}/backups/"
aws s3 cp "${OUT_FILE}" "s3://${S3_BUCKET}/backups/${OUT_FILE##*/}"

LOG "Backup completed."