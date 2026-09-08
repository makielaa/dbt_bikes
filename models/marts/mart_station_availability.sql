
select
    s.station_id,
    st.station_name,
    s.bikes_available,
    s.docks_available,
    s.is_installed,
    s.is_renting,
    s.is_returning,
    s.last_reported_at,
    s.snapshot_at,
    date(s.snapshot_at) as snapshot_date
from {{ ref('stg_station_status') }} s
left join {{ ref('mart_oslo_bikes') }} st
    on s.station_id = st.station_id