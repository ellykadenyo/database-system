-- Author: Elly Kadenyo
-- Date: 2025-09-01 2025-09-04
-- Description: SQL script to create materialized views for analytics dashboards in PostgreSQL and grant access to metabase_user.
-- Usage: psql -f database-system/analytics/materialized_views/dataloader_mv_execution.sql -d your_database_name -U your_admin_user
-- Reference: https://www.postgresql.org/docs/current/sql-creatematerializedview.html
-- Reference: https://www.postgresql.org/docs/current/sql-grant.html
-- This script will be run by the dataloader container after data ingestion is complete

-- Create the materialized view for average trip duration by pickup hour
-- This MV calculates the average trip duration in minutes for each hour of the day
CREATE MATERIALIZED VIEW mv_avg_trip_duration_by_hour AS
SELECT 
    EXTRACT(HOUR FROM tpep_pickup_datetime) AS pickup_hour,
    ROUND(AVG(EXTRACT(EPOCH FROM (tpep_dropoff_datetime - tpep_pickup_datetime)) / 60)) AS avg_trip_duration_minutes
FROM yellow_tripdata
WHERE tpep_dropoff_datetime > tpep_pickup_datetime
GROUP BY pickup_hour
ORDER BY pickup_hour
WITH NO DATA;

-- Create an index to optimize lookups by pickup_hour
CREATE INDEX idx_mv_avg_trip_duration_by_hour
    ON mv_avg_trip_duration_by_hour (pickup_hour);

-- Refresh command to populate or update the MV
-- Run manually or schedule via cron/pgagent
REFRESH MATERIALIZED VIEW mv_avg_trip_duration_by_hour;

-- Grant access to metabase_user
GRANT SELECT ON mv_avg_trip_duration_by_hour TO metabase_user;

-- Create the materialized view for month-over-month tips change by pickup hour
-- This MV calculates the total tips per hour for each month and the MoM % change
CREATE MATERIALIZED VIEW mv_tips_mom_change AS
WITH tips_by_month AS (
    SELECT
        TO_CHAR(tpep_pickup_datetime, 'YYYY-MM') AS month,
        EXTRACT(HOUR FROM tpep_pickup_datetime) AS pickup_hour,
        ROUND(SUM(tip_amount)) AS total_tips
    FROM yellow_tripdata
    GROUP BY TO_CHAR(tpep_pickup_datetime, 'YYYY-MM'), pickup_hour
),
tips_with_change AS (
    SELECT
        month,
        pickup_hour,
        total_tips,
        LAG(total_tips) OVER (PARTITION BY pickup_hour ORDER BY month) AS prev_month_tips
    FROM tips_by_month
)
SELECT
    month,
    pickup_hour,
    total_tips,
    CASE 
        WHEN prev_month_tips IS NULL OR prev_month_tips = 0 THEN 'No change'
        ELSE ROUND(((total_tips - prev_month_tips) / prev_month_tips::numeric) * 100, 2)::text
    END AS mom_percent_change
FROM tips_with_change
ORDER BY month, pickup_hour
WITH NO DATA;

-- Optional: create index to speed up Metabase queries by month/hour
CREATE INDEX idx_mv_tips_mom_change_month_hour
    ON mv_tips_mom_change (month, pickup_hour);

-- Refresh command to populate/update MV
REFRESH MATERIALIZED VIEW mv_tips_mom_change;

-- Grant access to metabase_user
GRANT SELECT ON mv_tips_mom_change TO metabase_user;

-- Create the materialized view for quarter-over-quarter tips change by pickup hour
-- This MV calculates the total tips per hour for each quarter and the QoQ % change
CREATE MATERIALIZED VIEW mv_tips_qoq_change AS
WITH tips_by_quarter AS (
    SELECT
        TO_CHAR(tpep_pickup_datetime, 'YYYY-"Q"Q') AS quarter,
        EXTRACT(HOUR FROM tpep_pickup_datetime) AS pickup_hour,
        ROUND(SUM(tip_amount)) AS total_tips
    FROM yellow_tripdata
    GROUP BY TO_CHAR(tpep_pickup_datetime, 'YYYY-"Q"Q'), pickup_hour
),
tips_with_change AS (
    SELECT
        quarter,
        pickup_hour,
        total_tips,
        LAG(total_tips) OVER (PARTITION BY pickup_hour ORDER BY quarter) AS prev_quarter_tips
    FROM tips_by_quarter
)
SELECT
    quarter,
    pickup_hour,
    total_tips,
    CASE 
        WHEN prev_quarter_tips IS NULL OR prev_quarter_tips = 0 THEN 'No change'
        ELSE ROUND(((total_tips - prev_quarter_tips) / prev_quarter_tips::numeric) * 100, 2)::text
    END AS qoq_percent_change
FROM tips_with_change
ORDER BY quarter, pickup_hour
WITH NO DATA;

-- Optional: index to speed up lookups
CREATE INDEX idx_mv_tips_qoq_change_quarter_hour
    ON mv_tips_qoq_change (quarter, pickup_hour);

-- Populate/refresh the MV
REFRESH MATERIALIZED VIEW mv_tips_qoq_change;

-- Grant access to metabase_user
GRANT SELECT ON mv_tips_qoq_change TO metabase_user;

-- Create the materialized view for quarter-over-quarter tips change by pickup hour
-- This MV calculates the total tips per hour for each quarter and the QoQ % change
CREATE MATERIALIZED VIEW mv_tips_qoq_change AS
WITH tips_by_quarter AS (
    SELECT
        TO_CHAR(tpep_pickup_datetime, 'YYYY-"Q"Q') AS quarter,
        EXTRACT(HOUR FROM tpep_pickup_datetime) AS pickup_hour,
        ROUND(SUM(tip_amount)) AS total_tips
    FROM yellow_tripdata
    GROUP BY TO_CHAR(tpep_pickup_datetime, 'YYYY-"Q"Q'), pickup_hour
),
tips_with_change AS (
    SELECT
        quarter,
        pickup_hour,
        total_tips,
        LAG(total_tips) OVER (PARTITION BY pickup_hour ORDER BY quarter) AS prev_quarter_tips
    FROM tips_by_quarter
)
SELECT
    quarter,
    pickup_hour,
    total_tips,
    CASE 
        WHEN prev_quarter_tips IS NULL OR prev_quarter_tips = 0 THEN 'No change'
        ELSE ROUND(((total_tips - prev_quarter_tips) / prev_quarter_tips::numeric) * 100, 2)::text
    END AS qoq_percent_change
FROM tips_with_change
ORDER BY quarter, pickup_hour
WITH NO DATA;

-- Optional: index to speed up lookups
CREATE INDEX idx_mv_tips_qoq_change_quarter_hour
    ON mv_tips_qoq_change (quarter, pickup_hour);

-- Populate/refresh the MV
REFRESH MATERIALIZED VIEW mv_tips_qoq_change;

-- Grant access to metabase_user
GRANT SELECT ON mv_tips_qoq_change TO metabase_user;

-- Create the materialized view for taxi density analysis per square km
-- This MV calculates the number of taxi pickups in each 0.001 degree grid cell
CREATE MATERIALIZED VIEW mv_taxi_density AS
WITH taxi_locations AS (
    SELECT 
        ROUND(pickup_longitude::numeric, 3) AS lon_grid,
        ROUND(pickup_latitude::numeric, 3) AS lat_grid,
        COUNT(*) AS taxi_count
    FROM yellow_tripdata
    WHERE pickup_longitude BETWEEN -74.05 AND -73.75
      AND pickup_latitude BETWEEN 40.63 AND 40.85
    GROUP BY lon_grid, lat_grid
)
SELECT 
    lon_grid,
    lat_grid,
    taxi_count
FROM taxi_locations
ORDER BY taxi_count DESC
WITH NO DATA;

-- Optional: add index for faster lookups in dashboards
CREATE INDEX idx_mv_taxi_density_grid
    ON mv_taxi_density (lat_grid, lon_grid);

-- Populate/refresh the MV
REFRESH MATERIALIZED VIEW mv_taxi_density;

--Grant access to metabase_user
GRANT SELECT ON mv_taxi_density TO metabase_user;

-- Create the materialized view for number of trips by day
-- This MV calculates the total number of trips for each day
CREATE MATERIALIZED VIEW mv_trips_by_day AS
SELECT 
    DATE(tpep_pickup_datetime) AS trip_date,
    COUNT(*) AS trip_count
FROM yellow_tripdata
GROUP BY trip_date
ORDER BY trip_date
WITH NO DATA;

-- index to speed up time-based filtering
CREATE INDEX idx_mv_trips_by_day_date
    ON mv_trips_by_day (trip_date);

-- Populate/refresh the MV
REFRESH MATERIALIZED VIEW mv_trips_by_day;

--Grant access to metabase_user
GRANT SELECT ON mv_trips_by_day TO metabase_user;

--END--