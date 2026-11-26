-- une ligne par pilote et par Grand Prix
select
    result_id,
    race_id,
    driver_id,
    constructor_id,
    status_id,
    number                              as car_number,
    grid                                as grid_position,
    position                            as finish_position,
    position_order                      as finish_position_order,
    case
        when position_text ~ '^[0-9]+$' then 'Classified'
        else position_text
    end                                 as classification_status,
    cast(points as numeric(5, 2))       as points,
    laps                                as laps_completed,
    time                                as race_time,
    milliseconds                        as race_milliseconds,
    fastest_lap                         as fastest_lap_number,
    rank                                as fastest_lap_rank,
    fastest_lap_time,
    cast(fastest_lap_speed as numeric(7, 3)) as fastest_lap_speed_kph
from {{ source('f1', 'results') }}
