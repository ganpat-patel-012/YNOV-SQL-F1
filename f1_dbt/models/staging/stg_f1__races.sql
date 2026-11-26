-- une ligne par Grand Prix
-- colonnes url et fp1..sprint (> 90 % NULL) non reprises
select
    race_id,
    year        as season_year,
    round       as round_number,
    circuit_id,
    trim(name)  as race_name,
    date        as date_race,
    time        as time_race
from {{ source('f1', 'races') }}
