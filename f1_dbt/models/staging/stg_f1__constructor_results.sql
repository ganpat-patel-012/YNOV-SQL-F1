-- une ligne par ecurie et par Grand Prix
select
    constructor_results_id,
    race_id,
    constructor_id,
    cast(points as numeric(5, 2))  as points,
    status                         as result_status
from {{ source('f1', 'constructor_results') }}
