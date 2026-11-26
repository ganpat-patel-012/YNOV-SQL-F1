-- grain : une ligne par pilote et par saison
-- jointures : classement pilotes apres chaque course + Grand Prix (saison, manche)
-- logique : on garde le classement apres la derniere manche de la saison = classement final
with standings_by_round as (
    select
        ra.season_year,
        ra.round_number,
        ds.driver_id,
        ds.points,
        ds.standing_position,
        ds.standing_status,
        ds.wins,
        row_number() over (
            partition by ra.season_year, ds.driver_id
            order by ra.round_number desc
        ) as round_rank_desc
    from {{ ref('stg_f1__driver_standings') }} ds
    join {{ ref('stg_f1__races') }} ra
        on ra.race_id = ds.race_id
)
select
    season_year,
    driver_id,
    round_number               as final_round_number,
    points                     as season_points,
    standing_position          as final_position,
    standing_status,
    wins                       as season_wins,
    standing_position = 1      as is_champion
from standings_by_round
where round_rank_desc = 1
