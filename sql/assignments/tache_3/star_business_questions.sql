-- Tâche 3 — 3 questions métier sur le schéma en étoile dbt (schéma dw)
-- Chaque requête part d'une table de faits et filtre / groupe par ses dimensions (une jointure par axe).


-- 1. Quelles écuries ont dominé chaque décennie (victoires en Grand Prix) ?
--    fct_race_results x dim_constructors x dim_date
with victoires as (
    select
        dt.decade,
        c.constructor_name,
        count(*) filter (where f.is_winner)  as victoires
    from dw.fct_race_results f
    join dw.dim_constructors c on c.constructor_key = f.constructor_key
    join dw.dim_date dt        on dt.date_key = f.date_key
    group by dt.decade, c.constructor_name
),
classement as (
    select
        decade,
        constructor_name,
        victoires,
        rank() over (partition by decade order by victoires desc) as rang
    from victoires
)
select decade, constructor_name, victoires
from classement
where rang = 1
order by decade;


-- 2. Sur quels circuits partir en pole position est le plus décisif pour gagner (depuis 2000) ?
--    fct_race_results x dim_circuits x dim_date
select
    ci.circuit_name,
    ci.country,
    count(*) filter (where f.is_winner)                                  as grands_prix,
    count(*) filter (where f.is_winner and f.grid_position = 1)          as victoires_depuis_la_pole,
    round(100.0 * count(*) filter (where f.is_winner and f.grid_position = 1)
          / count(*) filter (where f.is_winner), 1)                      as pct_victoires_depuis_la_pole
from dw.fct_race_results f
join dw.dim_circuits ci on ci.circuit_key = f.circuit_key
join dw.dim_date dt     on dt.date_key = f.date_key
where dt.year >= 2000
group by ci.circuit_name, ci.country
having count(*) filter (where f.is_winner) >= 10
order by pct_victoires_depuis_la_pole desc
limit 10;


-- 3. Quels pilotes ont marqué le plus de points sur l'ère hybride (2014–2024), et avec quelle régularité ?
--    fct_race_results x dim_drivers x dim_date
select
    d.full_name,
    d.driver_nationality,
    sum(f.points)                                         as points,
    count(*) filter (where f.is_podium)                   as podiums,
    round(100.0 * avg(f.has_scored_points::int), 1)       as pct_courses_dans_les_points
from dw.fct_race_results f
join dw.dim_drivers d on d.driver_key = f.driver_key
join dw.dim_date dt   on dt.date_key = f.date_key
where dt.year between 2014 and 2024
group by d.full_name, d.driver_nationality
order by points desc
limit 10;
