#!/usr/bin/env bash
# ingest_run.sh - wrapper that installs dependencies, runs ingestion helper
#Ensure it is executable # chmod +x db/ingest_run.sh
set -euo pipefail

LOG() { echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') [ingest_run] $*"; }

LOG "Starting dataloader container; ensuring Python deps are available..."
# Install minimal deps if not present (container is python:3.11-slim)
pip install --no-cache-dir psycopg2-binary

LOG "Running ingest_helper.py..."
python /app/ingest_helper.py

LOG "Dataloader finished. Sleeping to keep container alive for debugging..."
sleep 3600