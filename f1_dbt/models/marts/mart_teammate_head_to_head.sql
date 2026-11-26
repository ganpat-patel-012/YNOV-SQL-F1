-- grain : une ligne par saison, ecurie, pilote et coequipier
-- jointure : auto-jointure des resultats sur la meme course et la meme ecurie (meme voiture)
-- dedoublonnage AVANT l'auto-jointure : un pilote peut avoir 2 resultats dans un GP (voitures partagees)
-- finish_position_order classe aussi les non-classes (au nombre de tours) : chaque duel a un gagnant
with driver_race as (
    select
        season_year,
        race_id,
        constructor_id,
        driver_id,
        min(finish_position_order)  as finish_position_order
    from {{ ref('int_race_results_enriched') }}
    group by
        season_year,
        race_id,
        constructor_id,
        driver_id
),
duels as (
    select
        a.season_year,
        a.constructor_id,
        a.driver_id,
        b.driver_id                                            as teammate_id,
        a.finish_position_order < b.finish_position_order      as finished_ahead
    from driver_race a
    join driver_race b
        on b.race_id = a.race_id
       and b.constructor_id = a.constructor_id
       and b.driver_id <> a.driver_id
)
select
    du.season_year,
    du.constructor_id,
    c.constructor_name,
    du.driver_id,
    d.full_name                                                as driver_name,
    du.teammate_id,
    t.full_name                                                as teammate_name,
    count(*)                                                   as races_together,
    count(*) filter (where du.finished_ahead)                  as races_ahead,
    round(100.0 * count(*) filter (where du.finished_ahead) / count(*), 1)
                                                               as pct_races_ahead
from duels du
join {{ ref('stg_f1__constructors') }} c
    on c.constructor_id = du.constructor_id
join {{ ref('stg_f1__drivers') }} d
    on d.driver_id = du.driver_id
join {{ ref('stg_f1__drivers') }} t
    on t.driver_id = du.teammate_id
group by
    du.season_year,
    du.constructor_id,
    c.constructor_name,
    du.driver_id,
    d.full_name,
    du.teammate_id,
    t.full_name
