-- une ligne par pilote, par course et par tour
select
    race_id,
    driver_id,
    lap           as lap_number,
    position      as lap_position,
    time          as lap_time,
    milliseconds  as lap_milliseconds
from {{ source('f1', 'lap_times') }}
