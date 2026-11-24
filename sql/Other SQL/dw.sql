-- ============================================================================
-- formula 1 star schema (elt : public -> dw)
-- cree un schema analytique "dw" (1 table de faits + 5 dimensions)
-- sans modifier les tables sources dans "public"
-- ============================================================================

-- 1. creer (ou reinitialiser) le schema dw
drop schema if exists dw cascade;
create schema dw;


-- ============================================================================
-- dimensions (5 tables plates)
-- ============================================================================

-- dim_date : calendrier et informations de course (1 ligne par course)
create table dw.dim_date as
select
    r.race_id as date_key,
    r.date as full_date,
    r.year,
    (r.year / 10) * 10 as decade,
    extract(quarter from r.date)::integer as quarter,
    extract(month from r.date)::integer as month,
    trim(to_char(r.date, 'Month')) as month_name,
    trim(to_char(r.date, 'Day')) as day_of_week,
    r.round,
    r.name as race_name
from public.races r;

alter table dw.dim_date
    add primary key (date_key);


-- dim_driver : pilotes
create table dw.dim_driver as
select
    d.driver_id as driver_key,
    d.driver_ref,
    d.forename || ' ' || d.surname as full_name,
    d.code,
    d.number,
    d.dob,
    d.nationality
from public.drivers d;

alter table dw.dim_driver
    add primary key (driver_key);


-- dim_constructor : ecuries
create table dw.dim_constructor as
select
    c.constructor_id as constructor_key,
    c.constructor_ref,
    c.name as constructor_name,
    c.nationality
from public.constructors c;

alter table dw.dim_constructor
    add primary key (constructor_key);


-- dim_circuit : circuits et geographie (pays > ville > circuit)
create table dw.dim_circuit as
select
    ci.circuit_id as circuit_key,
    ci.circuit_ref,
    ci.name as circuit_name,
    ci.location as city,
    ci.country,
    ci.lat,
    ci.lng,
    ci.alt
from public.circuits ci;

alter table dw.dim_circuit
    add primary key (circuit_key);


-- dim_status : statuts d'arrivee regroupes par categorie
create table dw.dim_status as
select
    s.status_id as status_key,
    s.status,
    case
        when s.status = 'Finished' then 'Finished'
        when s.status like '+%Lap%' then 'Lapped'
        when s.status in ('Accident', 'Collision', 'Spun off', 'Collision damage', 'Damage') then 'Accident / Collision'
        when s.status in ('Disqualified', 'Excluded', 'Withdrew', 'Did not qualify', 'Did not prequalify') then 'Disqualified / DNS'
        else 'Mechanical / Other DNF'
    end as category
from public.status s;

alter table dw.dim_status
    add primary key (status_key);


-- ============================================================================
-- table de faits centrale : fact_race_results
-- grain : 1 pilote dans 1 grand prix (26 759 lignes)
-- ============================================================================

create table dw.fact_race_results as
with pit_summary as (
    -- agreger les arrets aux stands par course et par pilote
    select
        race_id,
        driver_id,
        count(*)::integer as pit_stop_count,
        sum(milliseconds)::integer as total_pit_ms
    from public.pit_stops
    group by
        race_id,
        driver_id
)
select
    res.result_id as result_key,
    res.race_id as date_key,
    res.driver_id as driver_key,
    res.constructor_id as constructor_key,
    ra.circuit_id as circuit_key,
    res.status_id as status_key,
    res.grid,
    res.position_order,
    case
        when res.grid > 0 then res.grid - res.position_order
        else null
    end as positions_gained,
    res.points,
    res.laps,
    res.milliseconds,
    res.fastest_lap_speed,
    case when res.position = 1 then 1::smallint else 0::smallint end as is_win,
    case when res.position between 1 and 3 then 1::smallint else 0::smallint end as is_podium,
    case when res.position is null then 1::smallint else 0::smallint end as is_dnf,
    coalesce(ps.pit_stop_count, 0) as pit_stop_count,
    ps.total_pit_ms
from public.results res
join public.races ra
    on ra.race_id = res.race_id
left join pit_summary ps
    on ps.race_id = res.race_id
   and ps.driver_id = res.driver_id;


-- ============================================================================
-- contraintes (cle primaire + 5 cles etrangeres) et index
-- ============================================================================

alter table dw.fact_race_results
    add primary key (result_key),
    add foreign key (date_key) references dw.dim_date(date_key),
    add foreign key (driver_key) references dw.dim_driver(driver_key),
    add foreign key (constructor_key) references dw.dim_constructor(constructor_key),
    add foreign key (circuit_key) references dw.dim_circuit(circuit_key),
    add foreign key (status_key) references dw.dim_status(status_key);

create index idx_fact_date_key on dw.fact_race_results(date_key);
create index idx_fact_driver_key on dw.fact_race_results(driver_key);
create index idx_fact_constructor_key on dw.fact_race_results(constructor_key);
create index idx_fact_circuit_key on dw.fact_race_results(circuit_key);
create index idx_fact_status_key on dw.fact_race_results(status_key);
