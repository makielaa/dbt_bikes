{{ config(materialized='table') }}

SELECT
    start_station_id                     AS station_id,
    MAX(start_station_name)              AS station_name,
    MAX(start_station_latitude)          AS latitude,
    MAX(start_station_longitude)         AS longitude,
    YEAR(started_at)                     AS year,
    MONTH(started_at)                    AS month_number,
    TO_CHAR(started_at, 'MMMM')          AS month_name,
    DAYOFWEEKISO(started_at)             AS day_of_week,
    HOUR(started_at)                     AS hour_of_day,
    COUNT(*)                             AS departures
FROM {{ ref('mart_oslo_bikes') }}
WHERE start_station_id IS NOT NULL
GROUP BY
    start_station_id, year, month_number, month_name, day_of_week, hour_of_day