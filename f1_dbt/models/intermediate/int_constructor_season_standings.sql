-- grain : une ligne par ecurie et par saison (championnat constructeurs depuis 1958)
-- jointures : classement constructeurs apres chaque course + Grand Prix (saison, manche)
-- logique : on garde le classement apres la derniere manche de la saison = classement final
with standings_by_round as (
    select
        ra.season_year,
        ra.round_number,
        cs.constructor_id,
        cs.points,
        cs.standing_position,
        cs.standing_status,
        cs.wins,
        row_number() over (
            partition by ra.season_year, cs.constructor_id
            order by ra.round_number desc
        ) as round_rank_desc
    from {{ ref('stg_f1__constructor_standings') }} cs
    join {{ ref('stg_f1__races') }} ra
        on ra.race_id = cs.race_id
)
select
    season_year,
    constructor_id,
    round_number               as final_round_number,
    points                     as season_points,
    standing_position          as final_position,
    standing_status,
    wins                       as season_wins,
    standing_position = 1      as is_champion
from standings_by_round
where round_rank_desc = 1
