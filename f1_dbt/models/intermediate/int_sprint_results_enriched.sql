-- grain : une ligne par pilote et par course sprint (depuis 2021)
-- jointures : resultats sprint + Grand Prix (saison, date, circuit)
-- enrichissements : positions gagnees, victoire, podium, non classe, points marques
select
    sr.sprint_result_id,
    sr.race_id,
    sr.driver_id,
    sr.constructor_id,
    sr.status_id,
    ra.circuit_id,
    ra.season_year,
    ra.round_number,
    ra.date_race,
    sr.grid_position,
    sr.finish_position,
    sr.finish_position_order,
    sr.classification_status,
    sr.points,
    sr.laps_completed,
    case
        when sr.grid_position > 0 then sr.grid_position - sr.finish_position_order
    end                                          as positions_gained,
    coalesce(sr.finish_position = 1, false)      as is_winner,
    coalesce(sr.finish_position <= 3, false)     as is_podium,
    sr.finish_position is null                   as is_not_classified,
    sr.points > 0                                as has_scored_points
from {{ ref('stg_f1__sprint_results') }} sr
join {{ ref('stg_f1__races') }} ra
    on ra.race_id = sr.race_id
