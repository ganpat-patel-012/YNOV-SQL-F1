-- grain : une ligne par jour, du 1950-01-01 au 2024-12-31 (couvre toutes les dates de Grand Prix)
-- dimension generee (generate_series), pas issue d'une table source
select
    cast(to_char(d, 'YYYYMMDD') as integer)    as date_key,
    cast(d as date)                            as date_day,
    cast(extract(year from d) as integer)      as year,
    cast(extract(year from d) as integer) / 10 * 10
                                               as decade,
    cast(extract(quarter from d) as integer)   as quarter,
    cast(extract(month from d) as integer)     as month,
    trim(to_char(d, 'Month'))                  as month_name,
    cast(extract(isodow from d) as integer)    as day_of_week,
    trim(to_char(d, 'Day'))                    as day_name,
    extract(isodow from d) in (6, 7)           as is_weekend
from generate_series(date '1950-01-01', date '2024-12-31', interval '1 day') as d
