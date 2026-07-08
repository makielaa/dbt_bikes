-- tests/assert_station_attributes_consistent.sql
-- Test sprawdza, czy każdy station_id ma spójne atrybuty (nazwa, lat, lon)
-- niezależnie od tego, czy występuje jako start_station czy end_station.
-- Jeśli test zwróci jakiekolwiek wiersze - test FAILUJE.

WITH start_side AS (
    SELECT DISTINCT
        start_station_id   AS station_id,
        start_station_name AS station_name,
        start_station_latitude  AS latitude,
        start_station_longitude AS longitude
    FROM {{ ref('mart_oslo_bikes') }}
),

end_side AS (
    SELECT DISTINCT
        end_station_id   AS station_id,
        end_station_name AS station_name,
        end_station_latitude  AS latitude,
        end_station_longitude AS longitude
    FROM {{ ref('mart_oslo_bikes') }}
),

all_attributes AS (
    SELECT * FROM start_side
    UNION ALL
    SELECT * FROM end_side
),

inconsistencies AS (
    SELECT
        station_id,
        COUNT(DISTINCT station_name) AS distinct_names,
        COUNT(DISTINCT latitude)     AS distinct_lats,
        COUNT(DISTINCT longitude)    AS distinct_lons
    FROM all_attributes
    GROUP BY station_id
    HAVING 
        COUNT(DISTINCT station_name) > 1
        OR COUNT(DISTINCT latitude) > 1
        OR COUNT(DISTINCT longitude) > 1
)

SELECT * FROM inconsistencies