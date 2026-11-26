{{ config(alias='dim_driver') }}
-- grain : une ligne par pilote, comme dw.dim_driver
select
    driver_id           as driver_key,
    driver_ref,
    full_name,
    driver_code         as code,
    driver_number       as number,
    date_birth          as dob,
    driver_nationality  as nationality
from {{ ref('stg_f1__drivers') }}
