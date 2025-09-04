-- Author: Elly Kadenyo
-- Date: 2025-09-01 2025-09-04
-- Description: SQL script to create a materialized view for quarter-over-quarter change in total tips by hour in PostgreSQL and grant access to metabase_user.
-- Usage: psql -f database-system/analytics/materialized_views/QoQ_hourly_tips_change.sql -d your_database_name -U your_admin_user
-- Reference: https://www.postgresql.org/docs/current/sql-creatematerializedview.html
-- Reference: https://www.postgresql.org/docs/current/sql-grant.html

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

-- Query example from Metabase:
--SELECT * FROM mv_tips_qoq_change LIMIT 100;