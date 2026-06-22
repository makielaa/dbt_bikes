-- models/marts/mart_routes.sql

WITH source AS (
    SELECT * FROM {{ ref('mart_oslo_bikes') }}
),

aggregated AS (
    SELECT
        route_id,

        -- === STACJE ===
        start_station_id,
        start_station_name,
        end_station_id,
        end_station_name,

        -- === PODSTAWOWE AGREGATY ===
        COUNT(*)                                    AS total_trips,
        ROUND(AVG(duration_minutes), 1)             AS avg_duration_minutes,
        ROUND(AVG(distance_km), 2)                  AS avg_distance_km,
        ROUND(MIN(distance_km), 2)                  AS distance_km,  -- dystans jest stały dla trasy

        -- === COMMUTER VS LEISURE ===
        SUM(CASE WHEN is_weekend = FALSE 
            AND time_of_day IN ('morning', 'evening') 
            THEN 1 ELSE 0 END)                      AS commuter_trips,
        SUM(CASE WHEN is_weekend = TRUE 
            OR time_of_day = 'afternoon' 
            THEN 1 ELSE 0 END)                      AS leisure_trips,

        -- === POPULARNOSC CZASOWA ===
        SUM(CASE WHEN time_of_day = 'morning'   THEN 1 ELSE 0 END)  AS morning_trips,
        SUM(CASE WHEN time_of_day = 'afternoon' THEN 1 ELSE 0 END)  AS afternoon_trips,
        SUM(CASE WHEN time_of_day = 'evening'   THEN 1 ELSE 0 END)  AS evening_trips,
        SUM(CASE WHEN time_of_day = 'night'     THEN 1 ELSE 0 END)  AS night_trips,

        SUM(CASE WHEN is_weekend = FALSE THEN 1 ELSE 0 END)         AS weekday_trips,
        SUM(CASE WHEN is_weekend = TRUE  THEN 1 ELSE 0 END)         AS weekend_trips,

        -- === SEZONOWOSC ===
        SUM(CASE WHEN MONTH(started_at) IN (12, 1, 2)  THEN 1 ELSE 0 END)  AS winter_trips,
        SUM(CASE WHEN MONTH(started_at) IN (3, 4, 5)   THEN 1 ELSE 0 END)  AS spring_trips,
        SUM(CASE WHEN MONTH(started_at) IN (6, 7, 8)   THEN 1 ELSE 0 END)  AS summer_trips,
        SUM(CASE WHEN MONTH(started_at) IN (9, 10, 11) THEN 1 ELSE 0 END)  AS autumn_trips,

        -- === ROUND TRIPS ===
        SUM(CASE WHEN is_round_trip = TRUE THEN 1 ELSE 0 END)       AS round_trips,

        -- === PREDKOSC ===
        ROUND(AVG(avg_speed_kmh), 1)                AS avg_speed_kmh

    FROM source
    GROUP BY 
        route_id,
        start_station_id,
        start_station_name,
        end_station_id,
        end_station_name
),

final AS (
    SELECT
        *,
        -- jaki % to commuter
        ROUND(commuter_trips * 100.0 / NULLIF(total_trips, 0), 1)  AS commuter_pct,
        -- jaki % to leisure
        ROUND(leisure_trips * 100.0 / NULLIF(total_trips, 0), 1)   AS leisure_pct,
        -- dominujacy typ trasy
        CASE
            WHEN commuter_trips > leisure_trips THEN 'commuter'
            WHEN leisure_trips > commuter_trips THEN 'leisure'
            ELSE 'mixed'
        END                                                          AS route_type

    FROM aggregated
)

SELECT * FROM final