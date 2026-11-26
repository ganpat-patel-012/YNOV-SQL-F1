-- grain : une ligne par pilote et par Grand Prix (donnees d'arrets disponibles depuis 2011)
-- agregation des arrets aux stands AVANT la jointure avec les resultats,
-- pour ne pas dupliquer les lignes de resultats (1 a 5+ arrets par pilote)
select
    race_id,
    driver_id,
    count(*)               as pit_stop_count,
    sum(pit_milliseconds)  as total_pit_milliseconds
from {{ ref('stg_f1__pit_stops') }}
group by
    race_id,
    driver_id
