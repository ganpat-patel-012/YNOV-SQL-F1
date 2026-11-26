-- grain : une ligne par ecurie et par Grand Prix (depuis 1958)
-- cles : date_key -> dim_date (AAAAMMJJ), *_key -> cles de substitution des dimensions (dbt_utils.generate_surrogate_key)
-- materialise en table le modele intermediate (ephemeral) pour l'analyse
select
    constructor_results_id,
    cast(to_char(date_race, 'YYYYMMDD') as integer)  as date_key,
    {{ dbt_utils.generate_surrogate_key(['race_id']) }}  as race_key,
    {{ dbt_utils.generate_surrogate_key(['constructor_id']) }}  as constructor_key,
    {{ dbt_utils.generate_surrogate_key(['circuit_id']) }}  as circuit_key,
    race_id,
    constructor_id,
    circuit_id,
    season_year,
    round_number,
    date_race,
    points,
    is_disqualified,
    drivers_entered,
    wins,
    podiums,
    best_finish_position_order
from {{ ref('int_constructor_race_results') }}
