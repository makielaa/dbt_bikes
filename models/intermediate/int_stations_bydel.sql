-- one row per station with the bydel it falls in (spatial join)
with stations as (

    select
        station_id,
        station_name,
        latitude,
        longitude,
        st_makepoint(longitude, latitude) as geom     -- NOTE: longitude first
    from {{ ref('int_stations_coords') }}

),

bydel as (

    select bydel_code, bydel_name, geom
    from {{ ref('stg_bydel_boundaries') }}

),

joined as (

    select
        s.station_id,
        s.station_name,
        s.latitude,
        s.longitude,
        b.bydel_code,
        b.bydel_name
    from stations s
    left join bydel b
        on st_intersects(b.geom, s.geom)

)

select
    station_id,
    station_name,
    latitude,
    longitude,
    coalesce(bydel_code, 'unassigned') as bydel_code,
    coalesce(bydel_name, 'Unassigned') as bydel_name
from joined
-- safety: if a point touches two polygons, keep one row per station
qualify row_number() over (partition by station_id order by bydel_code) = 1