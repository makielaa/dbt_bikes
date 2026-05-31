SELECT *,
    CASE
        WHEN started_at IS NULL THEN 'missing_started_at'
        WHEN ended_at IS NULL THEN 'missing_ended_at'
        WHEN duration < 0 THEN 'invalid_duration'
        WHEN ended_at < started_at THEN 'invalid_time'
        WHEN start_station_id IS NULL THEN 'missing_start_station_id'
        WHEN start_station_name IS NULL THEN 'missing_start_station_name'
        WHEN end_station_id IS NULL THEN 'missing_end_station_id'
        WHEN end_station_name IS NULL THEN 'missing_end_station_name'
        WHEN start_station_latitude IS NULL OR start_station_longitude IS NULL THEN 'missing_start_coordinates'
        WHEN end_station_latitude IS NULL OR end_station_longitude IS NULL THEN 'missing_end_coordinates'
        ELSE NULL
    END AS error_reason,

    CASE
        WHEN started_at IS NOT NULL
         AND ended_at IS NOT NULL
         AND duration >= 0
         AND ended_at >= started_at
         AND start_station_id IS NOT NULL
         AND end_station_id IS NOT NULL
         AND start_station_latitude IS NOT NULL
         AND start_station_longitude IS NOT NULL
         AND end_station_latitude IS NOT NULL
         AND end_station_longitude IS NOT NULL
        THEN TRUE
        ELSE FALSE
    END AS is_valid

FROM {{ ref('stg_oslo_bikes') }} 

