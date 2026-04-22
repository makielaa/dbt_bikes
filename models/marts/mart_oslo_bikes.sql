SELECT
    DATE_TRUNC('day', started_at) AS ride_date,

    start_station_name,

    COUNT(*) AS total_trips,

    AVG(duration) AS avg_duration,

    MIN(duration) AS min_duration,

    MAX(duration) AS max_duration

FROM {{ ref('quality_oslo_bikes') }}

WHERE is_valid = TRUE
  AND started_at IS NOT NULL

GROUP BY 1, 2