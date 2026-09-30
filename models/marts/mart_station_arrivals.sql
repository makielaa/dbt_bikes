{{ config(materialized='table') }}

SELECT
    end_station_id                       AS station_id,
    MAX(end_station_name)                AS station_name,
    MAX(end_station_latitude)            AS latitude,
    MAX(end_station_longitude)           AS longitude,
    YEAR(ended_at)                       AS year,
    MONTH(ended_at)                      AS month_number,
    TO_CHAR(ended_at, 'MMMM')            AS month_name,
    DAYOFWEEKISO(ended_at)               AS day_of_week,
    HOUR(ended_at)                       AS hour_of_day,
    COUNT(*)                             AS arrivals
FROM {{ ref('mart_oslo_bikes') }}
WHERE end_station_id IS NOT NULL
GROUP BY
    end_station_id, year, month_number, month_name, day_of_week, hour_of_day