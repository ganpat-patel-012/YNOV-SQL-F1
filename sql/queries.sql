-- ============================================================================
-- exercices flash : fenetres (window functions) & ctes
-- base de donnees : f1 (postgresql)
-- style : tout en minuscules, une clause par ligne pour faciliter la lecture
-- ============================================================================


-- ============================================================================
-- exercice 1 : top 3 des pilotes par ecurie selon le total de points
-- (equivalent slide : top 3 des produits par categorie selon le ca)
-- ============================================================================
-- etape 1 (cte 1) : calculer le total de points de chaque pilote par ecurie
-- etape 2 (cte 2) : numeroter les pilotes de 1 a n dans chaque ecurie (row_number)
-- etape 3         : garder seulement les rangs 1, 2 et 3 (where rnk <= 3)

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


-- ============================================================================
-- exercice 2 : evolution des points mensuels en % par rapport au mois precedent
-- (equivalent slide : evolution du ca mensuel en % par rapport au mois precedent)
-- ============================================================================
-- etape 1 (cte 1) : regrouper les points par mois (date_trunc)
-- etape 2 (cte 2) : recuperer les points du mois precedent avec lag()
-- etape 3         : calculer le % d'evolution (nullif evite la division par 0)

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


-- ============================================================================
-- exercice 3 : segmenter les pilotes en 4 quartiles selon leurs points totaux
-- (equivalent slide : segmenter les clients en quartiles de chiffre d'affaires)
-- ============================================================================
-- etape 1 (cte) : calculer le total de points en carriere de chaque pilote
-- etape 2       : couper la liste en 4 groupes egaux avec ntile(4)
--                 (1 = top 25% des pilotes, 4 = derniers 25%)

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


-- ============================================================================
-- exercice 4 : afficher le chemin complet de chaque circuit (cte recursive)
-- (equivalent slide : afficher le chemin complet de chaque categorie)
-- ============================================================================
-- etape 1 (nodes)    : construire l'arbre parent -> enfant
--                      niveau 1 = pays, niveau 2 = ville, niveau 3 = circuit
-- etape 2 (geo_tree) : parcourir l'arbre recursivement pour coller le chemin
--                      exemple : france > le castellet > circuit paul ricard

with recursive nodes as (
    -- niveau 1 : les pays (pas de parent)
    select distinct
        country as id,
        null::text as parent_id,
        country as label
    from circuits

    union

    -- niveau 2 : les villes (parent = pays)
    select distinct
        country || ':' || location as id,
        country as parent_id,
        location as label
    from circuits

    union

    -- niveau 3 : les circuits (parent = pays:ville)
    select
        circuit_id::text as id,
        country || ':' || location as parent_id,
        name as label
    from circuits
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
-- (equivalent slide : delai moyen entre deux commandes d'un meme client)
-- ============================================================================
-- etape 1 (cte) : pour chaque course d'un pilote, trouver la date de sa course
--                 precedente avec lag()
-- etape 2       : faire la moyenne de (date_course - date_course_precedente)

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
