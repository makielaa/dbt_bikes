WITH source AS (
    SELECT * FROM {{ ref('stg_oslo_bikes') }}
    WHERE started_at IS NOT NULL
      AND ended_at IS NOT NULL
      AND duration >= 0
      AND ended_at >= started_at
      AND start_station_id IS NOT NULL
      AND end_station_id IS NOT NULL
      AND start_station_latitude IS NOT NULL
      AND start_station_longitude IS NOT NULL
      AND end_station_latitude IS NOT NULL
      AND end_station_longitude IS NOT NULL
),

enriched AS (
    SELECT
        -- === KLUCZE ===
        {{ dbt_utils.generate_surrogate_key(['started_at', 'start_station_id', 'end_station_id']) }} AS trip_id,

        -- trasa bez kierunku (A-B = B-A)
        LEAST(start_station_id, end_station_id) 
            || '-' || 
        GREATEST(start_station_id, end_station_id)                          AS route_id,

        -- === ORYGINALNE KOLUMNY ===
        started_at,
        ended_at,
        duration,
        start_station_id,
        start_station_name,
        start_station_latitude,
        start_station_longitude,
        end_station_id,
        end_station_name,
        end_station_latitude,
        end_station_longitude,

        -- === CZAS ===
        ROUND(duration / 60.0, 1)                                           AS duration_minutes,
        EXTRACT(HOUR FROM started_at)                                       AS hour_of_day,
        EXTRACT(DAYOFWEEK FROM started_at)                                  AS day_of_week,       -- 1=Niedziela, 7=Sobota
        CASE 
            WHEN EXTRACT(DAYOFWEEK FROM started_at) IN (1, 7) THEN TRUE 
            ELSE FALSE 
        END                                                                 AS is_weekend,
        CASE
            WHEN EXTRACT(HOUR FROM started_at) BETWEEN 6  AND 9  THEN 'morning'
            WHEN EXTRACT(HOUR FROM started_at) BETWEEN 10 AND 16 THEN 'afternoon'
            WHEN EXTRACT(HOUR FROM started_at) BETWEEN 17 AND 21 THEN 'evening'
            ELSE 'night'
        END                                                                 AS time_of_day,

        -- === GEOGRAFIA ===
        CASE 
            WHEN start_station_id = end_station_id THEN TRUE 
            ELSE FALSE 
        END                                                                 AS is_round_trip,

        -- dystans haversine w km
        2 * 6371 * ASIN(
            SQRT(
                POWER(SIN(RADIANS(end_station_latitude  - start_station_latitude)  / 2), 2)
                + COS(RADIANS(start_station_latitude))
                * COS(RADIANS(end_station_latitude))
                * POWER(SIN(RADIANS(end_station_longitude - start_station_longitude) / 2), 2)
            )
        )                                                                   AS distance_km,

        processed_at

    FROM source
),

final AS (
    SELECT
        *,
        -- prędkość tylko dla sensownych przejazdów
        CASE
            WHEN duration > 60 AND distance_km > 0.1 
            THEN ROUND(distance_km / (duration / 3600.0), 1)
            ELSE NULL
        END                                                                 AS avg_speed_kmh

    FROM enriched
)

SELECT * FROM final


