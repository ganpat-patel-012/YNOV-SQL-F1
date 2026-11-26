-- grain : une ligne par pilote et par course sprint (depuis 2021)
-- cles : date_key -> dim_date (AAAAMMJJ), *_key -> cles de substitution des dimensions (dbt_utils.generate_surrogate_key)
-- jointures : resultats sprint enrichis + libelle du statut
select
    sr.sprint_result_id,
    cast(to_char(sr.date_race, 'YYYYMMDD') as integer)  as date_key,
    {{ dbt_utils.generate_surrogate_key(['sr.race_id']) }}  as race_key,
    {{ dbt_utils.generate_surrogate_key(['sr.driver_id']) }}  as driver_key,
    {{ dbt_utils.generate_surrogate_key(['sr.constructor_id']) }}  as constructor_key,
    {{ dbt_utils.generate_surrogate_key(['sr.circuit_id']) }}  as circuit_key,
    sr.race_id,
    sr.driver_id,
    sr.constructor_id,
    sr.circuit_id,
    sr.season_year,
    sr.round_number,
    sr.date_race,
    sr.status_id,
    st.status_label,
    sr.grid_position,
    sr.finish_position,
    sr.finish_position_order,
    sr.classification_status,
    sr.positions_gained,
    sr.points,
    sr.laps_completed,
    sr.is_winner,
    sr.is_podium,
    sr.is_not_classified,
    sr.has_scored_points
from {{ ref('int_sprint_results_enriched') }} sr
join {{ ref('stg_f1__status') }} st
    on st.status_id = sr.status_id
