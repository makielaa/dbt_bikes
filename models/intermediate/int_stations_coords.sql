-- one row per station with its latest known coordinates.
-- Stations appear as start and end stations in BIKES_STATIONS, so take both.
-- ASSUMPTION: standard Urban Sharing column names - check with
--   describe table OSLO_CITY_BIKES.STAGE.BIKES_STATIONS;
with points as (

    select
        start_station_id                  as station_id,
        start_station_name                as station_name,
        start_station_latitude::float     as latitude,
        start_station_longitude::float    as longitude,
        started_at                        as seen_at
    from {{ source('stage', 'bikes_stations') }}

    union all

    select
        end_station_id,
        end_station_name,
        end_station_latitude::float,
        end_station_longitude::float,
        ended_at
    from {{ source('stage', 'bikes_stations') }}

)

select
    station_id,
    max_by(station_name, seen_at) as station_name,
    max_by(latitude,     seen_at) as latitude,
    max_by(longitude,    seen_at) as longitude
from points
where station_id is not null
  and latitude  is not null
  and longitude is not null
group by station_id