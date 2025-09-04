-- Author: Elly Kadenyo
-- Date: 2025-09-01 2025-09-04
-- Description: SQL script to create a materialized view for taxi density per square kilometer in PostgreSQL and set appropriate privileges for Metabase user.
-- Usage: psql -f database-system/analytics/materialized_views/taxi_density_per_square_km.sql -d your_database_name -U your_admin_user
-- Reference: https://www.postgresql.org/docs/current/sql-creatematerializedview.html
-- Reference: https://www.postgresql.org/docs/current/sql-grant.html

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

-- Query example from Metabase:
--SELECT * FROM mv_taxi_density LIMIT 100;