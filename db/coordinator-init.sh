#!/usr/bin/env bash
# coordinator-init.sh
# Runs inside citus_coordinator container as the service command.
# Responsibilities:
#  - Start Postgres (container's default entrypoint will run automatically)
#  - Wait for Postgres to be ready
#  - Create users and DB (using templated SQL)
#  - Register worker nodes with Citus (master_add_node)
#  - Create schema and distributed table
#
# This script is intentionally verbose with timestamps and logging to aid troubleshooting.
#Make sure it is executable # chmod +x db/coordinator-init.sh

set -euo pipefail

LOG() { echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') [coordinator-init] $*"; }

# Paths
INIT_SQL_DIR="/docker-entrypoint-initdb.d"
# The postgres image stores PGDATA in $PGDATA - default path; we rely on docker-entrypoint to initialize DB.
PGHOST=localhost
PGPORT=5432
PGUSER="${POSTGRES_USER:-postgres}"
PGPASSWORD="${POSTGRES_PASSWORD:-postgres}"
export PGPASSWORD

# Helper to wait for a TCP service
wait_for_port() {
  local host=$1; local port=$2; local timeout=${3:-60}
  LOG "Waiting for ${host}:${port} (timeout ${timeout}s)..."
  for i in $(seq 1 "$timeout"); do
    if nc -z "$host" "$port" >/dev/null 2>&1; then
      LOG "Port ${host}:${port} is available"
      return 0
    fi
    sleep 1
  done
  LOG "Timed out waiting for ${host}:${port}"
  return 1
}

# Wait for coordinator Postgres to be up
LOG "Waiting for local Postgres (coordinator) to accept connections..."
# use psql in a loop
for i in $(seq 1 60); do
  if pg_isready -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" >/dev/null 2>&1; then
    LOG "Coordinator Postgres is up"
    break
  fi
  sleep 1
  if [ "$i" -eq 60 ]; then
    LOG "Coordinator Postgres did not become available in time"
    exit 1
  fi
done

# Wait for workers to be up before registering them
LOG "Waiting for worker nodes..."
wait_for_port "${WORKER1_HOST}" "${WORKER1_PORT}" 120
wait_for_port "${WORKER2_HOST}" "${WORKER2_PORT}" 120
wait_for_port "${WORKER3_HOST}" "${WORKER3_PORT}" 120

# Substitute environment variables into SQL templates and run them
run_sql_template() {
  local template_file=$1
  LOG "Applying SQL from template: ${template_file}"
  # perform envsubst for placeholders like ${VAR}
  envsubst < "${template_file}" | psql -v ON_ERROR_STOP=1 -U "${PGUSER}" -d "postgres"
}

# Create users & initial DB objects (run on the postgres 'postgres' DB first)
if [ -f "${INIT_SQL_DIR}/create_users.sql" ]; then
  LOG "Creating users and database..."
  # We run against 'postgres' DB so creation of database succeeds
  envsubst < "${INIT_SQL_DIR}/create_users.sql" | psql -v ON_ERROR_STOP=1 -U "${PGUSER}" -d "postgres"
  LOG "Users/database creation SQL executed"
fi

# Now register workers with Citus (must be run on coordinator, after worker nodes are reachable)
LOG "Registering worker nodes with Citus..."
cat <<'EOF' | psql -v ON_ERROR_STOP=1 -U "${PGUSER}" -d "${POSTGRES_DB}"
SELECT master_add_node('citus_worker1', 5432);
SELECT master_add_node('citus_worker2', 5432);
SELECT master_add_node('citus_worker3', 5432);
EOF

LOG "Worker registration complete"

# Create schema and prepare distributed table
if [ -f "${INIT_SQL_DIR}/create_schema.sql" ]; then
  LOG "Creating schema and table..."
  envsubst < "${INIT_SQL_DIR}/create_schema.sql" | psql -v ON_ERROR_STOP=1 -U "${PGUSER}" -d "${POSTGRES_DB}"
  LOG "Schema SQL applied"
fi

# Now distribute the table using Citus command - must be executed on coordinator
LOG "Creating distributed table on coordinator..."
psql -U "${PGUSER}" -d "${POSTGRES_DB}" -c "SELECT create_distributed_table('yellow_tripdata','pickup_day');"

LOG "Distributed table created (yellow_tripdata)"

LOG "Coordinator initialization completed successfully."
# Sleep forever to let container run as normal Postgres server (the main image will keep running)
tail -f /dev/null