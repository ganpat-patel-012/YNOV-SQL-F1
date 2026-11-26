{{ config(alias='fact_race_results') }}
-- grain : une ligne par pilote et par Grand Prix (= un result_id), comme dw.fact_race_results
-- cles : date_key -> dim_date (race_id), driver_key, constructor_key, circuit_key, status_key
-- mesures issues de int_race_results_enriched (arrets aux stands agreges avant la jointure)
select
    result_id                                as result_key,
    race_id                                  as date_key,
    driver_id                                as driver_key,
    constructor_id                           as constructor_key,
    circuit_id                               as circuit_key,
    status_id                                as status_key,
    grid_position                            as grid,
    finish_position_order                    as position_order,
    positions_gained,
    points,
    laps_completed                           as laps,
    race_milliseconds                        as milliseconds,
    fastest_lap_speed_kph                    as fastest_lap_speed,
    cast(case when is_winner then 1 else 0 end as smallint)          as is_win,
    cast(case when is_podium then 1 else 0 end as smallint)          as is_podium,
    cast(case when is_not_classified then 1 else 0 end as smallint)  as is_dnf,
    pit_stop_count,
    total_pit_milliseconds                   as total_pit_ms
from {{ ref('int_race_results_enriched') }}
