-- une ligne par ecurie apres chaque Grand Prix
select
    constructor_standings_id,
    race_id,
    constructor_id,
    cast(points as numeric(6, 2))  as points,
    position                       as standing_position,
    case
        when position_text ~ '^[0-9]+$' then 'Classified'
        else position_text
    end                            as standing_status,
    wins
from {{ source('f1', 'constructor_standings') }}
