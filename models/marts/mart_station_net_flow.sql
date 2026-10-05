{{ config(materialized='table') }}

WITH unioned AS (
    SELECT
        station_id, station_name, latitude, longitude,
        trip_date,
        year, month_number, month_name, day_of_week, hour_of_day,
        departures,
        0 AS arrivals
    FROM {{ ref('mart_station_departures') }}

    UNION ALL

    SELECT
        station_id, station_name, latitude, longitude,
        trip_date,
        year, month_number, month_name, day_of_week, hour_of_day,
        0 AS departures,
        arrivals
    FROM {{ ref('mart_station_arrivals') }}
)

SELECT
    station_id,
    MAX(station_name)                   AS station_name,
    MAX(latitude)                       AS latitude,
    MAX(longitude)                      AS longitude,
    trip_date,
    year,
    month_number,
    month_name,
    day_of_week,
    hour_of_day,
    SUM(departures)                     AS departures,
    SUM(arrivals)                       AS arrivals,
    SUM(arrivals) - SUM(departures)     AS net_flow   -- >0 nadwyżka rowerów, <0 deficyt
FROM unioned
GROUP BY
    station_id, trip_date, year, month_number, month_name, day_of_week, hour_of_day
    