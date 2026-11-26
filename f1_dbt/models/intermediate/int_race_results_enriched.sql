-- grain : une ligne par resultat (un pilote dans un Grand Prix) = une ligne de stg_f1__results
-- jointures : resultats + Grand Prix (saison, date, circuit) + arrets aux stands agreges + tours agreges
-- enrichissements : positions gagnees, victoire, podium, abandon, points marques
select
    res.result_id,
    res.race_id,
    res.driver_id,
    res.constructor_id,
    res.status_id,
    ra.circuit_id,
    ra.season_year,
    ra.round_number,
    ra.date_race,
    res.grid_position,
    res.finish_position,
    res.finish_position_order,
    res.classification_status,
    res.points,
    res.laps_completed,
    res.race_milliseconds,
    res.fastest_lap_speed_kph,
    case
        when res.grid_position > 0 then res.grid_position - res.finish_position_order
    end                                              as positions_gained,
    coalesce(res.finish_position = 1, false)         as is_winner,
    coalesce(res.finish_position <= 3, false)        as is_podium,
    res.finish_position is null                      as is_not_classified,
    res.points > 0                                   as has_scored_points,
    coalesce(ps.pit_stop_count, 0)                   as pit_stop_count,
    ps.total_pit_milliseconds,
    coalesce(lt.laps_led, 0)                         as laps_led,
    lt.best_lap_milliseconds,
    lt.avg_lap_milliseconds
from {{ ref('stg_f1__results') }} res
join {{ ref('stg_f1__races') }} ra
    on ra.race_id = res.race_id
left join {{ ref('int_pit_stops_per_driver_race') }} ps
    on ps.race_id = res.race_id
   and ps.driver_id = res.driver_id
left join {{ ref('int_lap_times_per_driver_race') }} lt
    on lt.race_id = res.race_id
   and lt.driver_id = res.driver_id
