-- une ligne par pilote et par seance de qualification
select
    qualify_id,
    race_id,
    driver_id,
    constructor_id,
    number    as car_number,
    position  as qualifying_position,
    q1        as q1_time,
    q2        as q2_time,
    q3        as q3_time
from {{ source('f1', 'qualifying') }}
