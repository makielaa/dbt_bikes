-- sprawdza czy mamy jeden wiersz na stację × datę × godzinę, bez duplikatów

SELECT station_id, trip_date, hour_of_day, COUNT(*) AS n
FROM {{ ref('mart_station_net_flow') }}
GROUP BY station_id, trip_date, hour_of_day
HAVING COUNT(*) > 1