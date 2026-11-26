-- grain : une ligne par circuit
-- jointures : circuit + Grand Prix organises sur ce circuit
with races_hosted as (
    select
        circuit_id,
        count(*)          as races_hosted,
        min(season_year)  as first_season,
        max(season_year)  as last_season
    from {{ ref('stg_f1__races') }}
    group by circuit_id
)
select
    c.circuit_id,
    c.circuit_ref,
    c.circuit_name,
    c.city,
    c.country,
    c.latitude,
    c.longitude,
    c.altitude_m,
    coalesce(r.races_hosted, 0)  as races_hosted,
    r.first_season,
    r.last_season
from {{ ref('stg_f1__circuits') }} c
left join races_hosted r
    on r.circuit_id = c.circuit_id
