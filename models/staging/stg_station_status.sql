-- models/staging/stg_station_status.sql

select
    station_id::string                  as station_id,
    num_bikes_available::integer        as bikes_available,
    num_docks_available::integer        as docks_available,
    is_installed::boolean               as is_installed,
    is_renting::boolean                 as is_renting,
    is_returning::boolean               as is_returning,
    last_reported::timestamp_ntz        as last_reported_at,
    snapshot_at::timestamp_ntz          as snapshot_at
from {{ source('oslo_city_bikes_stage', 'STATION_STATUS_SNAPSHOTS') }}