-- coherence : le total des arrets agreges doit egaler le nombre d'arrets du staging
with i as (select sum(pit_stop_count) as nb from {{ ref('int_pit_stops_per_driver_race') }}),
     s as (select count(*) as nb from {{ ref('stg_f1__pit_stops') }})
select *
from i, s
where i.nb <> s.nb
