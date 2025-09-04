-- Author: Elly Kadenyo
-- Date: 2025-09-01 2025-09-04
-- Description: SQL script to create a materialized view for hourly average trip duration in PostgreSQL and grant access to metabase_user.
-- Usage: psql -f database-system/analytics/materialized_views/hourly_average_trip_duration.sql -d your_database_name -U your_admin_user
-- Reference: https://www.postgresql.org/docs/current/sql-creatematerializedview.html
-- Reference: https://www.postgresql.org/docs/current/sql-grant.html

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

-- Query example from Metabase:
--SELECT * FROM mv_avg_trip_duration_by_hour LIMIT 100;