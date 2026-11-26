-- 1. top 3 des pilotes par ecurie selon le total de points
with driver_constructor_pts as (
    select
        c.name as constructor_name,
        d.forename || ' ' || d.surname as driver_name,
        sum(r.points) as total_points
    from results r
    join drivers d
        on d.driver_id = r.driver_id
    join constructors c
        on c.constructor_id = r.constructor_id
    group by
        c.name,
        d.driver_id,
        d.forename,
        d.surname
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
        date_trunc('month', ra.date)::date as race_month,
        sum(r.points) as total_points
    from results r
    join races ra
        on ra.race_id = r.race_id
    group by
        date_trunc('month', ra.date)::date
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
        d.driver_id,
        d.forename || ' ' || d.surname as driver_name,
        sum(r.points) as total_points
    from results r
    join drivers d
        on d.driver_id = r.driver_id
    group by
        d.driver_id,
        d.forename,
        d.surname
)
select
    driver_id,
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
    from circuits
    union
    select distinct
        country || ':' || location as id,
        country as parent_id,
        location as label
    from circuits
    union
    select
        circuit_id::text as id,
        country || ':' || location as parent_id,
        name as label
    from circuits
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
        r.driver_id,
        d.forename || ' ' || d.surname as driver_name,
        ra.date as race_date,
        lag(ra.date) over (
            partition by r.driver_id
            order by ra.date
        ) as prev_race_date
    from results r
    join drivers d
        on d.driver_id = r.driver_id
    join races ra
        on ra.race_id = r.race_id
)
select
    driver_id,
    driver_name,
    count(*) as total_races,
    round(avg(race_date - prev_race_date), 2) as avg_days_between_races
from driver_races
where prev_race_date is not null
group by
    driver_id,
    driver_name
order by
    total_races desc;

-- 7. cumul des points et moyenne mobile sur 3 courses des 3 premiers pilotes de la saison 2023
--    fenetre glissante : rows between unbounded preceding / 2 preceding and current row
with top_drivers as (
    select
        r.driver_id
    from results r
    join races ra
        on ra.race_id = r.race_id
    where ra.year = 2023
    group by
        r.driver_id
    order by
        sum(r.points) desc
    limit 3
)
select
    d.forename || ' ' || d.surname as driver_name,
    ra.round,
    ra.name as race_name,
    r.points,
    sum(r.points) over (
        partition by r.driver_id
        order by ra.round
        rows between unbounded preceding and current row
    ) as cumulative_points,
    round(avg(r.points) over (
        partition by r.driver_id
        order by ra.round
        rows between 2 preceding and current row
    )::numeric, 2) as moving_avg_3_races
from results r
join top_drivers t
    on t.driver_id = r.driver_id
join drivers d
    on d.driver_id = r.driver_id
join races ra
    on ra.race_id = r.race_id
where ra.year = 2023
order by
    driver_name,
    ra.round;
