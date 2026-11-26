-- regle metier : exactement un champion du monde pilotes par saison
select
    season_year,
    count(*) filter (where is_champion) as nb_champions
from {{ ref('int_driver_season_standings') }}
group by season_year
having count(*) filter (where is_champion) <> 1
