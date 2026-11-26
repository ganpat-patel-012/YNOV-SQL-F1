-- Tâche 3 — 3 questions métier sur le schéma en étoile dbt (schéma dw_star)
-- fact_race_results (grain : 1 pilote x 1 Grand Prix) + 5 dimensions : dim_date, dim_driver,
-- dim_constructor, dim_circuit, dim_status. Une jointure par axe d'analyse.


-- 1. Quelle écurie a dominé chaque décennie (nombre de victoires en Grand Prix) ?
--    fact_race_results x dim_constructor x dim_date
with victoires as (
    select
        dt.decade,
        c.constructor_name,
        sum(f.is_win)  as victoires
    from dw_star.fact_race_results f
    join dw_star.dim_constructor c on c.constructor_key = f.constructor_key
    join dw_star.dim_date dt       on dt.date_key = f.date_key
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
--    fact_race_results x dim_circuit x dim_date
select
    ci.circuit_name,
    ci.country,
    sum(f.is_win)                                                     as grands_prix,
    sum(case when f.is_win = 1 and f.grid = 1 then 1 else 0 end)      as victoires_depuis_la_pole,
    round(100.0 * sum(case when f.is_win = 1 and f.grid = 1 then 1 else 0 end)
          / sum(f.is_win), 1)                                         as pct_victoires_depuis_la_pole
from dw_star.fact_race_results f
join dw_star.dim_circuit ci on ci.circuit_key = f.circuit_key
join dw_star.dim_date dt    on dt.date_key = f.date_key
where dt.year >= 2000
group by ci.circuit_name, ci.country
having sum(f.is_win) >= 10
order by pct_victoires_depuis_la_pole desc
limit 10;


-- 3. Quels pilotes ont marqué le plus de points sur l'ère hybride (2014–2024),
--    et combien de courses ont-ils perdu sur casse mécanique ?
--    fact_race_results x dim_driver x dim_status x dim_date
select
    d.full_name,
    d.nationality,
    sum(f.points)                                                          as points,
    sum(f.is_podium)                                                       as podiums,
    sum(case when s.category = 'Mechanical / Other DNF' then 1 else 0 end) as abandons_mecaniques
from dw_star.fact_race_results f
join dw_star.dim_driver d on d.driver_key = f.driver_key
join dw_star.dim_status s on s.status_key = f.status_key
join dw_star.dim_date dt  on dt.date_key = f.date_key
where dt.year between 2014 and 2024
group by d.full_name, d.nationality
order by points desc
limit 10;
