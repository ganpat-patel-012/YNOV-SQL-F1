-- grain : une ligne par pilote et par Grand Prix (donnees tour par tour depuis 1996)
-- agregation des tours AVANT la jointure avec les resultats,
-- pour ne pas dupliquer les lignes de resultats (jusqu'a 80+ tours par pilote)
select
    race_id,
    driver_id,
    count(*)                                  as laps_timed,
    count(*) filter (where lap_position = 1)  as laps_led,
    min(lap_milliseconds)                     as best_lap_milliseconds,
    round(avg(lap_milliseconds))              as avg_lap_milliseconds
from {{ ref('stg_f1__lap_times') }}
group by
    race_id,
    driver_id
