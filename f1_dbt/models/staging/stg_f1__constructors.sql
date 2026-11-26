-- une ligne par ecurie
select
    constructor_id,
    trim(constructor_ref)  as constructor_ref,
    trim(name)             as constructor_name,
    trim(nationality)      as constructor_nationality
from {{ source('f1', 'constructors') }}
