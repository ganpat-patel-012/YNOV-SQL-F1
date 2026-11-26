-- grain : une ligne par ecurie et par Grand Prix (depuis 1958)
-- materialise en table le modele intermediate (ephemeral) pour l'analyse
select
    constructor_results_id,
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
