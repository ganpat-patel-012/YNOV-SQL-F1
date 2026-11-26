-- grain : une ligne par Grand Prix
-- jointures : Grand Prix + circuit + presence d'une course sprint
with sprint_races as (
    select distinct race_id
    from {{ ref('int_sprint_results_enriched') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['ra.race_id']) }} as race_key,
    ra.race_id,
    ra.season_year,
    ra.round_number,
    ra.race_name,
    ra.date_race,
    ra.time_race,
    ra.circuit_id,
    c.circuit_name,
    c.city,
    c.country,
    s.race_id is not null  as is_sprint_weekend,
    ra.round_number = max(ra.round_number) over (partition by ra.season_year)
                           as is_season_finale
from {{ ref('stg_f1__races') }} ra
join {{ ref('stg_f1__circuits') }} c
    on c.circuit_id = ra.circuit_id
left join sprint_races s
    on s.race_id = ra.race_id
