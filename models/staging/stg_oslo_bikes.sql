select
    try_to_timestamp(col1) as started_at,
    try_to_timestamp(col2) as ended_at,
    try_to_number(col3) as duration,
    try_to_number(col4) as start_station_id,
    col5 as start_station_name,
    col6 as start_station_description,
    try_to_double(col7) as start_station_latitude,
    try_to_double(col8) as start_station_longitude,
    try_to_number(col9) as end_station_id,
    col10 as end_station_name,
    col11 as end_station_description,
    try_to_double(col12) as end_station_latitude,
    try_to_double(col13) as end_station_longitude,
    added_at,
    current_timestamp() as processed_at

FROM {{ source('raw', 'oslo_bikes_raw') }}
