WITH departures AS (
    SELECT
        start_station_id   AS station_id,
        start_station_name AS station_name,
        start_station_latitude  AS latitude,
        start_station_longitude AS longitude,
        YEAR(started_at)                          AS trip_year,
        DATE_TRUNC('month', started_at)::date      AS trip_month_date,
        COUNT(*)            AS departures
    FROM {{ ref('mart_oslo_bikes') }}
    GROUP BY 1, 2, 3, 4, 5, 6
),

arrivals AS (
    SELECT
        end_station_id     AS station_id,
        YEAR(started_at)                          AS trip_year,
        DATE_TRUNC('month', started_at)::date      AS trip_month_date,
        COUNT(*)            AS arrivals
    FROM {{ ref('mart_oslo_bikes') }}
    GROUP BY 1, 2, 3
),

final AS (
    SELECT
        d.station_id,
        d.station_name,
        d.latitude,
        d.longitude,
        d.trip_year,
        d.trip_month_date,
        d.departures,
        COALESCE(a.arrivals, 0)                       AS arrivals,
        d.departures + COALESCE(a.arrivals, 0)         AS total_trips,
        d.departures - COALESCE(a.arrivals, 0)         AS net_flow
    FROM departures d
    LEFT JOIN arrivals a 
        ON d.station_id = a.station_id 
        AND d.trip_year = a.trip_year 
        AND d.trip_month_date = a.trip_month_date
)

SELECT * FROM final
ORDER BY trip_year, trip_month_date, total_trips DESC