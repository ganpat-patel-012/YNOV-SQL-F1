{{ config(alias='dim_date') }}
-- grain : une ligne par Grand Prix (date_key = race_id), comme dw.dim_date
select
    race_id                                        as date_key,
    date_race                                      as full_date,
    season_year                                    as year,
    (season_year / 10) * 10                        as decade,
    cast(extract(quarter from date_race) as integer) as quarter,
    cast(extract(month from date_race) as integer)   as month,
    trim(to_char(date_race, 'Month'))              as month_name,
    trim(to_char(date_race, 'Day'))                as day_of_week,
    round_number                                   as round,
    race_name
from {{ ref('stg_f1__races') }}
