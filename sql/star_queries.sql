-- ============================================================================
-- exercices flash : fenetres (window functions) & ctes — version star schema (dw)
-- base de donnees : f1 (schema dw : 1 table de faits + 5 dimensions)
-- style : tout en minuscules, une clause par ligne pour faciliter la lecture
-- ============================================================================


-- ============================================================================
-- exercice 1 : top 3 des pilotes par ecurie selon le total de points
-- (jointures directes 1-hop depuis dw.fact_race_results)
-- ============================================================================
-- etape 1 (cte 1) : calculer le total de points de chaque pilote par ecurie
-- etape 2 (cte 2) : classer les pilotes de 1 a n dans chaque ecurie (row_number)
-- etape 3         : garder seulement les rangs 1, 2 et 3

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


-- ============================================================================
-- exercice 2 : evolution des points mensuels en % par rapport au mois precedent
-- (utilise dw.dim_date directement)
-- ============================================================================
-- etape 1 (cte 1) : regrouper les points par mois (date_trunc sur full_date)
-- etape 2 (cte 2) : recuperer les points du mois precedent avec lag()
-- etape 3         : calculer le % d'evolution (nullif evite la division par 0)

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


-- ============================================================================
-- exercice 3 : segmenter les pilotes en 4 quartiles selon leurs points totaux
-- ============================================================================
-- etape 1 (cte) : calculer le total de points en carriere de chaque pilote
-- etape 2       : couper la liste en 4 groupes egaux avec ntile(4)
--                 (1 = top 25% des pilotes, 4 = derniers 25%)

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


-- ============================================================================
-- exercice 4 : afficher le chemin complet de chaque circuit (cte recursive)
-- (utilise la hierarchie pays > ville > circuit dans dw.dim_circuit)
-- ============================================================================
-- etape 1 (nodes)    : construire l'arbre parent -> enfant
-- etape 2 (geo_tree) : parcourir l'arbre recursivement pour coller le chemin

with recursive nodes as (
    -- niveau 1 : les pays (pas de parent)
    select distinct
        country as id,
        null::text as parent_id,
        country as label
    from dw.dim_circuit

    union

    -- niveau 2 : les villes (parent = pays)
    select distinct
        country || ':' || city as id,
        country as parent_id,
        city as label
    from dw.dim_circuit

    union

    -- niveau 3 : les circuits (parent = pays:ville)
    select
        circuit_key::text as id,
        country || ':' || city as parent_id,
        circuit_name as label
    from dw.dim_circuit
),
geo_tree as (
    -- point de depart : les racines (pays)
    select
        id,
        label,
        label as full_path,
        1 as lvl
    from nodes
    where parent_id is null

    union all

    -- partie recursive : on descend d'un niveau a chaque tour
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


-- ============================================================================
-- exercice 5 : delai moyen (en jours) entre deux courses d'un meme pilote
-- ============================================================================
-- etape 1 (cte) : pour chaque course d'un pilote, trouver la date de sa course
--                 precedente avec lag()
-- etape 2       : calculer la moyenne de (full_date - prev_race_date)

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


-- ============================================================================
-- exercice 6 (bonus star schema) : kpis par decennie et categorie d'abandon
-- (montre la puissance des kpis pre-calcules dans dw.fact_race_results +
--  dw.dim_date + dw.dim_status + dw.dim_circuit en jointures directes)
-- ============================================================================
-- etape 1 (cte) : calculer le nombre de departs, victoires, podiums, abandons
--                 et taux d'abandon (%) par decennie et categorie de statut
-- etape 2       : calculer la part (%) de chaque categorie dans sa decennie
--                 avec sum() over (partition by decade)

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
