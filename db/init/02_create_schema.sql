-- Author: Elly Kadenyo
-- Date: 2025-09-01 2025-09-04
-- Description: SQL script to create the tripdata schema and set appropriate privileges for application users.
-- Usage: psql -f db/init/02_create_schema.sql -d your_database_name -U your_admin_user
-- Reference: https://www.postgresql.org/docs/current/datatype.html
-- Reference: https://www.postgresql.org/docs/current/sql-grant.html
-- Creates efficient tripdata schema
-- Run on coordinator during initial database init
-- Uses environment variable substitution via envsubst in coordinator-init.sh

CREATE EXTENSION IF NOT EXISTS citus;

-- Create the table with appropriate types
CREATE TABLE IF NOT EXISTS public.yellow_tripdata (
  VendorID smallint,
  tpep_pickup_datetime timestamptz,
  tpep_dropoff_datetime timestamptz,
  passenger_count smallint,
  trip_distance double precision,
  pickup_longitude double precision,
  pickup_latitude double precision,
  RateCodeID smallint,
  store_and_fwd_flag boolean,
  dropoff_longitude double precision,
  dropoff_latitude double precision,
  payment_type smallint,
  fare_amount numeric(10,2),
  extra numeric(10,2),
  mta_tax numeric(10,2),
  tip_amount numeric(10,2),
  tolls_amount numeric(10,2),
  improvement_surcharge numeric(10,2),
  total_amount numeric(12,2)
);

-- Distribute table across workers on pickup_day
-- This command must run on the coordinator after workers are registered
-- The coordinator init will include this:
-- SELECT create_distributed_table('yellow_tripdata', 'tpep_pickup_datetime');

--Grant privileges to app users
-- Grant privileges to ingestion user
GRANT INSERT, UPDATE, DELETE, SELECT ON TABLE public.yellow_tripdata TO ${DATALOADER_DB_USER};
GRANT USAGE, CREATE ON SCHEMA public TO ${DATALOADER_DB_USER};

-- Grant read-only privileges to analytics and monitoring users
GRANT SELECT ON TABLE public.yellow_tripdata TO ${METABASE_DB_USER};
GRANT USAGE ON SCHEMA public TO ${METABASE_DB_USER};

GRANT SELECT ON TABLE public.yellow_tripdata TO ${PROM_EXPORTER_DB_USER};
GRANT USAGE ON SCHEMA public TO ${PROM_EXPORTER_DB_USER};

-- PGPOOL only needs connection
GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${PGPOOL_DB_USER};

--Metabase DB
CREATE DATABASE ${METABASE_DB} OWNER ${METABASE_DB_USER};