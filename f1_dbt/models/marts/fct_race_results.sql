-- grain : une ligne par resultat (un pilote dans un Grand Prix) = une ligne de int_race_results_enriched
-- cles : date_key -> dim_date (AAAAMMJJ), *_key -> cles de substitution des dimensions (dbt_utils.generate_surrogate_key)
-- jointures : resultats enrichis + libelle du statut + qualification du meme pilote (depuis 1994)
-- qualifying est unique par (race_id, driver_id) : la jointure ne duplique pas les resultats
select
    res.result_id,
    cast(to_char(res.date_race, 'YYYYMMDD') as integer)  as date_key,
    {{ dbt_utils.generate_surrogate_key(['res.race_id']) }}  as race_key,
    {{ dbt_utils.generate_surrogate_key(['res.driver_id']) }}  as driver_key,
    {{ dbt_utils.generate_surrogate_key(['res.constructor_id']) }}  as constructor_key,
    {{ dbt_utils.generate_surrogate_key(['res.circuit_id']) }}  as circuit_key,
    res.race_id,
    res.driver_id,
    res.constructor_id,
    res.circuit_id,
    res.season_year,
    res.round_number,
    res.date_race,
    res.status_id,
    st.status_label,
    q.qualifying_position,
    coalesce(q.qualifying_position = 1, false)  as is_pole_position,
    res.grid_position,
    res.finish_position,
    res.finish_position_order,
    res.classification_status,
    res.positions_gained,
    res.points,
    res.laps_completed,
    res.race_milliseconds,
    res.fastest_lap_speed_kph,
    res.is_winner,
    res.is_podium,
    res.is_not_classified,
    res.has_scored_points,
    res.pit_stop_count,
    res.total_pit_milliseconds,
    res.laps_led,
    res.best_lap_milliseconds,
    res.avg_lap_milliseconds
from {{ ref('int_race_results_enriched') }} res
join {{ ref('stg_f1__status') }} st
    on st.status_id = res.status_id
left join {{ ref('stg_f1__qualifying') }} q
    on q.race_id = res.race_id
   and q.driver_id = res.driver_id
