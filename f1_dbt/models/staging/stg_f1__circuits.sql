-- une ligne par circuit
select
    circuit_id,
    trim(circuit_ref)              as circuit_ref,
    trim(name)                     as circuit_name,
    trim(location)                 as city,
    trim(country)                  as country,
    cast(lat as numeric(9, 6))     as latitude,
    cast(lng as numeric(9, 6))     as longitude,
    alt                            as altitude_m
from {{ source('f1', 'circuits') }}
