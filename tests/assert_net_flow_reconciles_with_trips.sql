-- sprawdza czy sumy w marcie zgadzają się z liczbą przejazdów w mart_oslo_bikes

WITH mart AS (
    SELECT
        SUM(departures) AS departures,
        SUM(arrivals)   AS arrivals
    FROM {{ ref('mart_station_net_flow') }}
),
src AS (
    SELECT
        COUNT_IF(start_station_id IS NOT NULL) AS departures,
        COUNT_IF(end_station_id   IS NOT NULL) AS arrivals
    FROM {{ ref('mart_oslo_bikes') }}
)
SELECT
    m.departures AS mart_departures, s.departures AS src_departures,
    m.arrivals   AS mart_arrivals,   s.arrivals   AS src_arrivals
FROM mart m
CROSS JOIN src s
WHERE m.departures != s.departures
   OR m.arrivals   != s.arrivals

   