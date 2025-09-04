-- Author: Elly Kadenyo
-- Date: 2025-09-01 2025-09-04
-- Description: SQL script to create a materialized view for month-over-month change in total tips by hour in PostgreSQL and grant access to metabase_user.
-- Usage: psql -f database-system/analytics/materialized_views/MoM_hourly_tips_change.sql -d your_database_name -U your_admin_user
-- Reference: https://www.postgresql.org/docs/current/sql-creatematerializedview.html
-- Reference: https://www.postgresql.org/docs/current/sql-grant.html

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

-- Query example from Metabase:
--SELECT * FROM mv_tips_mom_change LIMIT 100;