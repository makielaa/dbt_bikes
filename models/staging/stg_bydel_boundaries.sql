-- one row per bydel, polygon as GEOGRAPHY
select
    bydel_code,
    bydel_name,
    try_to_geography(geom_geojson) as geom
from {{ source('stage', 'bydel_boundaries') }}