-- une ligne par pilote
select
    driver_id,
    trim(driver_ref)                       as driver_ref,
    number                                 as driver_number,
    upper(trim(code))                      as driver_code,
    trim(forename)                         as first_name,
    trim(surname)                          as last_name,
    trim(forename) || ' ' || trim(surname) as full_name,
    dob                                    as date_birth,
    trim(nationality)                      as driver_nationality
from {{ source('f1', 'drivers') }}
