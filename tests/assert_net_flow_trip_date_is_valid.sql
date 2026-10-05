-- sprawdza czy data nie jest pusta ani z przyszłości

SELECT *
FROM {{ ref('mart_station_net_flow') }}
WHERE trip_date IS NULL
   OR trip_date > CURRENT_DATE()