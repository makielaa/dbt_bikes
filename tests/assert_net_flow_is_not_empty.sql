-- sprzawdza czy mart nie jest pusty

SELECT 'mart_station_net_flow is empty' AS issue
WHERE (SELECT COUNT(*) FROM {{ ref('mart_station_net_flow') }}) = 0