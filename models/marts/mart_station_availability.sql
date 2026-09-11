-- models/marts/mart_station_availability.sql

{{
    config(
        materialized='incremental',
        unique_key=['station_id', 'snapshot_at']
    )
}}

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
left join (
    select distinct
        start_station_id as station_id,
        start_station_name as station_name
    from {{ ref('mart_oslo_bikes') }}
) st
    on s.station_id = st.station_id

{% if is_incremental() %}
where s.snapshot_at > (select max(snapshot_at) from {{ this }})
{% endif %}

qualify row_number() over (
    partition by s.station_id, s.snapshot_at
    order by s.snapshot_at desc
) = 1