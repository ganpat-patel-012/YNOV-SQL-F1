-- regle metier : exactement un champion du monde constructeurs par saison (depuis 1958)
select
    season_year,
    count(*) filter (where is_champion) as nb_champions
from {{ ref('int_constructor_season_standings') }}
group by season_year
having count(*) filter (where is_champion) <> 1
