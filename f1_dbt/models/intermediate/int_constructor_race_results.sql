-- grain : une ligne par ecurie et par Grand Prix (depuis 1958)
-- jointures : points de l'ecurie + Grand Prix (saison, date, circuit)
--             + resultats de ses pilotes agreges par course
with drivers_per_constructor_race as (
    select
        race_id,
        constructor_id,
        count(*)                                     as drivers_entered,
        count(*) filter (where finish_position = 1)  as wins,
        count(*) filter (where finish_position <= 3) as podiums,
        min(finish_position_order)                   as best_finish_position_order
    from {{ ref('stg_f1__results') }}
    group by
        race_id,
        constructor_id
)
select
    cr.constructor_results_id,
    cr.race_id,
    cr.constructor_id,
    ra.circuit_id,
    ra.season_year,
    ra.round_number,
    ra.date_race,
    cr.points,
    coalesce(cr.result_status = 'D', false)   as is_disqualified,
    coalesce(d.drivers_entered, 0)            as drivers_entered,
    coalesce(d.wins, 0)                       as wins,
    coalesce(d.podiums, 0)                    as podiums,
    d.best_finish_position_order
from {{ ref('stg_f1__constructor_results') }} cr
join {{ ref('stg_f1__races') }} ra
    on ra.race_id = cr.race_id
left join drivers_per_constructor_race d
    on d.race_id = cr.race_id
   and d.constructor_id = cr.constructor_id
