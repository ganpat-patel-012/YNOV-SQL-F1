-- 1. top 3 des pilotes par ecurie selon le total de points
with driver_constructor_pts as (
    select
        c.constructor_name,
        d.full_name as driver_name,
        sum(f.points) as total_points
    from dw.fact_race_results f
    join dw.dim_driver d
        on d.driver_key = f.driver_key
    join dw.dim_constructor c
        on c.constructor_key = f.constructor_key
    group by
        c.constructor_name,
        d.driver_key,
        d.full_name
),
ranked as (
    select
        constructor_name,
        driver_name,
        total_points,
        row_number() over (
            partition by constructor_name
            order by total_points desc
        ) as rnk
    from driver_constructor_pts
)
select
    constructor_name,
    driver_name,
    total_points,
    rnk
from ranked
where rnk <= 3
order by
    constructor_name,
    rnk;

-- 2. evolution des points mensuels en % par rapport au mois precedent
with monthly_pts as (
    select
        date_trunc('month', dt.full_date)::date as race_month,
        sum(f.points) as total_points
    from dw.fact_race_results f
    join dw.dim_date dt
        on dt.date_key = f.date_key
    group by
        date_trunc('month', dt.full_date)::date
),
with_prev as (
    select
        race_month,
        total_points,
        lag(total_points) over (
            order by race_month
        ) as prev_points
    from monthly_pts
)
select
    race_month,
    total_points,
    prev_points,
    round(
        ((total_points - prev_points) / nullif(prev_points, 0) * 100)::numeric,
        2
    ) as evolution_pct
from with_prev
order by
    race_month desc;

-- 3. segmenter les pilotes en 4 quartiles selon leurs points totaux
with driver_totals as (
    select
        d.driver_key,
        d.full_name as driver_name,
        sum(f.points) as total_points
    from dw.fact_race_results f
    join dw.dim_driver d
        on d.driver_key = f.driver_key
    group by
        d.driver_key,
        d.full_name
)
select
    driver_key,
    driver_name,
    total_points,
    ntile(4) over (
        order by total_points desc
    ) as quartile
from driver_totals
order by
    quartile,
    total_points desc;

-- 4. chemin complet de chaque circuit (pays > ville > circuit) via cte recursive
with recursive nodes as (
    select distinct
        country as id,
        null::text as parent_id,
        country as label
    from dw.dim_circuit
    union
    select distinct
        country || ':' || city as id,
        country as parent_id,
        city as label
    from dw.dim_circuit
    union
    select
        circuit_key::text as id,
        country || ':' || city as parent_id,
        circuit_name as label
    from dw.dim_circuit
),
geo_tree as (
    select
        id,
        label,
        label as full_path,
        1 as lvl
    from nodes
    where parent_id is null
    union all
    select
        n.id,
        n.label,
        g.full_path || ' > ' || n.label as full_path,
        g.lvl + 1 as lvl
    from nodes n
    join geo_tree g
        on n.parent_id = g.id
)
select
    lvl,
    label,
    full_path
from geo_tree
order by
    full_path;

-- 5. delai moyen en jours entre deux courses consecutives d'un meme pilote
with driver_races as (
    select
        d.driver_key,
        d.full_name as driver_name,
        dt.full_date as race_date,
        lag(dt.full_date) over (
            partition by d.driver_key
            order by dt.full_date
        ) as prev_race_date
    from dw.fact_race_results f
    join dw.dim_driver d
        on d.driver_key = f.driver_key
    join dw.dim_date dt
        on dt.date_key = f.date_key
)
select
    driver_key,
    driver_name,
    count(*) as total_races,
    round(avg(race_date - prev_race_date), 2) as avg_days_between_races
from driver_races
where prev_race_date is not null
group by
    driver_key,
    driver_name
order by
    total_races desc;

-- 6. part (%) des statuts d'arrivee par decennie (kpis star schema)
with decade_status as (
    select
        dt.decade,
        s.category as status_category,
        count(*) as race_entries,
        sum(f.is_win) as total_wins,
        sum(f.is_podium) as total_podiums,
        sum(f.is_dnf) as total_dnfs
    from dw.fact_race_results f
    join dw.dim_date dt
        on dt.date_key = f.date_key
    join dw.dim_status s
        on s.status_key = f.status_key
    group by
        dt.decade,
        s.category
)
select
    decade,
    status_category,
    race_entries,
    total_wins,
    total_podiums,
    total_dnfs,
    round(
        (race_entries * 100.0 / sum(race_entries) over (partition by decade)),
        2
    ) as pct_of_decade
from decade_status
order by
    decade desc,
    race_entries desc;
