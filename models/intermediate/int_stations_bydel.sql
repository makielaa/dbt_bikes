-- one row per station with the bydel it falls in (spatial join)
-- 1) station inside a polygon -> that bydel ('inside')
-- 2) otherwise nearest bydel within 200 m ('nearest'); the boundary file is
--    simplified, so stations on the shoreline can fall a few metres outside
-- 3) otherwise 'unassigned'
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

inside as (

    select
        s.station_id,
        b.bydel_code,
        b.bydel_name,
        'inside' as match_type
    from stations s
    join bydel b
        on st_intersects(b.geom, s.geom)
    -- safety: if a point touches two polygons, keep one
    qualify row_number() over (partition by s.station_id order by b.bydel_code) = 1

),

nearest_all as (

    select
        s.station_id,
        b.bydel_code,
        b.bydel_name,
        st_distance(b.geom, s.geom) as dist_m          -- metres for GEOGRAPHY
    from stations s
    cross join bydel b
    where s.station_id not in (select station_id from inside)

),

nearest as (

    select
        station_id,
        bydel_code,
        bydel_name,
        'nearest' as match_type
    from nearest_all
    qualify row_number() over (partition by station_id order by dist_m) = 1
        and dist_m <= 200

)

select
    s.station_id,
    s.station_name,
    s.latitude,
    s.longitude,
    coalesce(i.bydel_code, n.bydel_code, 'unassigned') as bydel_code,
    coalesce(i.bydel_name, n.bydel_name, 'Unassigned')  as bydel_name,
    coalesce(i.match_type, n.match_type, 'none')        as match_type
from stations s
left join inside  i on s.station_id = i.station_id
left join nearest n on s.station_id = n.station_id
