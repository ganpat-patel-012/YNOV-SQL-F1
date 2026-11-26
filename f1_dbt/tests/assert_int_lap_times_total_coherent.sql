-- coherence : le total des tours agreges doit egaler le nombre de tours du staging
with i as (select sum(laps_timed) as nb from {{ ref('int_lap_times_per_driver_race') }}),
     s as (select count(*) as nb from {{ ref('stg_f1__lap_times') }})
select *
from i, s
where i.nb <> s.nb
