{{ config(materialized='table') }}

WITH base AS (
    SELECT
        start_station_id        AS station_id,
        start_station_name      AS station_name,
        start_station_latitude  AS latitude,
        start_station_longitude AS longitude,
        started_at              AS event_at,
        CAST(started_at AS DATE) AS trip_date
    FROM {{ ref('mart_oslo_bikes') }}
    WHERE start_station_id IS NOT NULL
)

SELECT
    station_id,
    MAX(station_name)            AS station_name,
    MAX(latitude)                AS latitude,
    MAX(longitude)               AS longitude,
    trip_date,
    YEAR(event_at)               AS year,
    MONTH(event_at)              AS month_number,
    TO_CHAR(event_at, 'MMMM')    AS month_name,
    DAYOFWEEKISO(event_at)       AS day_of_week,
    HOUR(event_at)               AS hour_of_day,
    COUNT(*)                     AS departures
FROM base
GROUP BY
    station_id, trip_date, year, month_number, month_name, day_of_week, hour_of_day