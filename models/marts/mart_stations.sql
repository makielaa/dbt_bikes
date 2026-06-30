-- models/marts/mart_stations.sql

WITH departures AS (
    SELECT
        start_station_id   AS station_id,
        start_station_name AS station_name,
        start_station_latitude  AS latitude,
        start_station_longitude AS longitude,
        COUNT(*)            AS departures
    FROM {{ ref('mart_oslo_bikes') }}
    GROUP BY 1, 2, 3, 4
),

arrivals AS (
    SELECT
        end_station_id   AS station_id,
        COUNT(*)          AS arrivals
    FROM {{ ref('mart_oslo_bikes') }}
    GROUP BY 1
),

final AS (
    SELECT
        d.station_id,
        d.station_name,
        d.latitude,
        d.longitude,
        d.departures,
        COALESCE(a.arrivals, 0)                       AS arrivals,
        d.departures + COALESCE(a.arrivals, 0)         AS total_trips,
        d.departures - COALESCE(a.arrivals, 0)         AS net_flow  -- dodatnie = więcej wyjazdów niż przyjazdów
    FROM departures d
    LEFT JOIN arrivals a ON d.station_id = a.station_id
)

SELECT * FROM final
ORDER BY total_trips DESC