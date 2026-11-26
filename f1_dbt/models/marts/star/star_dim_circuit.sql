{{ config(alias='dim_circuit') }}
-- grain : une ligne par circuit, comme dw.dim_circuit
select
    circuit_id    as circuit_key,
    circuit_ref,
    circuit_name,
    city,
    country,
    latitude      as lat,
    longitude     as lng,
    altitude_m    as alt
from {{ ref('stg_f1__circuits') }}
