-- une ligne par pilote, par course et par arret aux stands
select
    race_id,
    driver_id,
    stop          as stop_number,
    lap           as lap_number,
    time          as time_of_day,
    duration      as pit_duration,
    milliseconds  as pit_milliseconds
from {{ source('f1', 'pit_stops') }}
