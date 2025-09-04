-- Author: Elly Kadenyo
-- Date: 2025-09-01 2025-09-04
-- Description: SQL script to create a materialized view for trips per day in PostgreSQL with indexing and access permissions.
-- Usage: psql -f database-system/analytics/materialized_views/trips_per_day.sql -d your_database_name -U your_admin_user
-- Reference: https://www.postgresql.org/docs/current/sql-creatematerializedview.html
-- Reference: https://www.postgresql.org/docs/current/sql-grant.html

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

-- Query from Metabase example:
--SELECT * FROM mv_trips_by_day LIMIT 100;