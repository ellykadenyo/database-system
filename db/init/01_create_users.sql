-- db/init/create_users.sql
-- Run on coordinator during initial database init
-- Uses environment variable substitution via envsubst in coordinator-init.sh

-- Application users with limited privileges
CREATE ROLE ${METABASE_DB_USER} WITH LOGIN PASSWORD '${METABASE_DB_PASSWORD}';
CREATE ROLE ${PROM_EXPORTER_DB_USER} WITH LOGIN PASSWORD '${PROM_EXPORTER_DB_PASSWORD}';
CREATE ROLE ${DATALOADER_DB_USER} WITH LOGIN PASSWORD '${DATALOADER_DB_PASSWORD}';
CREATE ROLE ${PGPOOL_DB_USER} WITH LOGIN PASSWORD '${PGPOOL_DB_PASSWORD}';

-- Create the special streaming-replication / health-check user for pgpool
-- Note: this user needs REPLICATION (or at least connection) privileges depending on pgpool config
CREATE ROLE ${PGPOOL_SR_CHECK_USER} WITH LOGIN REPLICATION PASSWORD '${PGPOOL_SR_CHECK_PASSWORD}';

-- Create pgpool admin user in DB (pgpool uses this for admin UI/auth)
CREATE ROLE ${PGPOOL_ADMIN_USERNAME} WITH LOGIN PASSWORD '${PGPOOL_ADMIN_PASSWORD}';

-- Grant connection and usage to app users
GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${METABASE_DB_USER}, ${PROM_EXPORTER_DB_USER}, ${DATALOADER_DB_USER}, ${PGPOOL_DB_USER};
GRANT USAGE ON SCHEMA public TO ${METABASE_DB_USER}, ${PROM_EXPORTER_DB_USER}, ${DATALOADER_DB_USER}, ${PGPOOL_DB_USER};
GRANT CREATE ON DATABASE ${POSTGRES_DB} TO ${DATALOADER_DB_USER}; -- ingestion needs to create temp tables