{{ config(materialized='table') }}

WITH base AS (
    SELECT
        end_station_id          AS station_id,
        end_station_name        AS station_name,
        end_station_latitude    AS latitude,
        end_station_longitude   AS longitude,
        ended_at                AS event_at
    FROM {{ ref('mart_oslo_bikes') }}
    WHERE end_station_id IS NOT NULL
)

SELECT
    station_id,
    MAX(station_name)            AS station_name,
    MAX(latitude)                AS latitude,
    MAX(longitude)               AS longitude,
    YEAR(event_at)               AS year,
    MONTH(event_at)              AS month_number,
    TO_CHAR(event_at, 'MMMM')    AS month_name,
    DAYOFWEEKISO(event_at)       AS day_of_week,
    HOUR(event_at)               AS hour_of_day,
    COUNT(*)                     AS arrivals
FROM base
GROUP BY
    station_id, year, month_number, month_name, day_of_week, hour_of_day