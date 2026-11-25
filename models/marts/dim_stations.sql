select
    station_id,
    station_name,
    latitude,
    longitude,
    bydel_code,
    bydel_name,
    match_type          -- 'inside' / 'nearest' / 'none' (how the bydel was assigned)
from {{ ref('int_stations_bydel') }}