-- create_schema.sql
-- Creates efficient tripdata schema
-- Choose efficient datatypes: timestamps, numeric for decimals, double precision for lat/long

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
  total_amount numeric(12,2),
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