#!/usr/bin/env bash
# restore.sh - fetches latest backup from S3 and restores to the DB (destructive!)
# Make sure it is executable # chmod +x scripts/restore.sh
set -euo pipefail
LOG(){ echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') [restore] $*"; }

if [ ! -f .env ]; then
  LOG "ERROR: .env missing. Copy .env.example -> .env and fill values"
  exit 1
fi
source .env

TMP_FILE="/tmp/restore_latest.sql.gz"

LOG "Fetching latest backup from s3://${S3_BUCKET}/backups/"
aws s3 cp "s3://${S3_BUCKET}/backups/$(aws s3 ls s3://${S3_BUCKET}/backups/ | sort | tail -n 1 | awk '{print $4}')" "${TMP_FILE}"

LOG "Restoring into database - THIS WILL DROP AND RECREATE 'tripdata' DB"
# Drop and recreate DB (dangerous: only for demos)
docker run --rm -e PGPASSWORD="${POSTGRES_PASSWORD}" postgres:17 bash -c "
psql -h citus_coordinator -U ${POSTGRES_USER} -d postgres -c \"DROP DATABASE IF EXISTS ${POSTGRES_DB}; CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};\"
gunzip -c ${TMP_FILE} | psql -h citus_coordinator -U ${POSTGRES_USER} -d ${POSTGRES_DB}
"

LOG "Restore complete."