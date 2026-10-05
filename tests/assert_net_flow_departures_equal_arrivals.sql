
-- suma odjazdów równa sumie przyjazdów
SELECT
    SUM(departures) AS total_departures,
    SUM(arrivals)   AS total_arrivals
FROM {{ ref('mart_station_net_flow') }}
HAVING SUM(departures) != SUM(arrivals)