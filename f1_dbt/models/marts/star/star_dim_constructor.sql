{{ config(alias='dim_constructor') }}
-- grain : une ligne par ecurie, comme dw.dim_constructor
select
    constructor_id           as constructor_key,
    constructor_ref,
    constructor_name,
    constructor_nationality  as nationality
from {{ ref('stg_f1__constructors') }}
