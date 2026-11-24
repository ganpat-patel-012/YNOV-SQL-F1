-- 1. scaling: duplicate all 6 star tables x50 with shifted keys
drop schema if exists benchmark cascade;
create schema benchmark;

create table benchmark.dim_date as
select
    d.date_key + (gs.copy_num - 1) * 100000 as date_key,
    d.full_date, d.year, d.decade, d.quarter, d.month,
    d.month_name, d.day_of_week, d.round, d.race_name, gs.copy_num
from dw.dim_date d
cross join generate_series(1, 50) as gs(copy_num);

create table benchmark.dim_driver as
select
    d.driver_key + (gs.copy_num - 1) * 100000 as driver_key,
    d.driver_ref, d.full_name, d.code, d.number, d.dob, d.nationality, gs.copy_num
from dw.dim_driver d
cross join generate_series(1, 50) as gs(copy_num);

create table benchmark.dim_constructor as
select
    c.constructor_key + (gs.copy_num - 1) * 100000 as constructor_key,
    c.constructor_ref, c.constructor_name, c.nationality, gs.copy_num
from dw.dim_constructor c
cross join generate_series(1, 50) as gs(copy_num);

create table benchmark.dim_circuit as
select
    ci.circuit_key + (gs.copy_num - 1) * 100000 as circuit_key,
    ci.circuit_ref, ci.circuit_name, ci.city, ci.country, ci.lat, ci.lng, ci.alt, gs.copy_num
from dw.dim_circuit ci
cross join generate_series(1, 50) as gs(copy_num);

create table benchmark.dim_status as
select
    s.status_key + (gs.copy_num - 1) * 100000 as status_key,
    s.status, s.category, gs.copy_num
from dw.dim_status s
cross join generate_series(1, 50) as gs(copy_num);

create table benchmark.fact_race_results as
select
    f.result_key + (gs.copy_num - 1) * 100000 as result_key,
    f.date_key + (gs.copy_num - 1) * 100000 as date_key,
    f.driver_key + (gs.copy_num - 1) * 100000 as driver_key,
    f.constructor_key + (gs.copy_num - 1) * 100000 as constructor_key,
    f.circuit_key + (gs.copy_num - 1) * 100000 as circuit_key,
    f.status_key + (gs.copy_num - 1) * 100000 as status_key,
    f.grid, f.position_order, f.positions_gained, f.points, f.laps,
    f.milliseconds, f.fastest_lap_speed, f.is_win, f.is_podium, f.is_dnf,
    f.pit_stop_count, f.total_pit_ms, gs.copy_num
from dw.fact_race_results f
cross join generate_series(1, 50) as gs(copy_num);

analyze benchmark.dim_date;
analyze benchmark.dim_driver;
analyze benchmark.dim_constructor;
analyze benchmark.dim_circuit;
analyze benchmark.dim_status;
analyze benchmark.fact_race_results;

-- 2. explain analyze before indexing
explain (analyze, buffers)
select d.full_name, c.constructor_name, count(*) as total_races, sum(f.points) as total_points, sum(f.is_win) as total_wins
from benchmark.fact_race_results f
join benchmark.dim_driver d on d.driver_key = f.driver_key
join benchmark.dim_constructor c on c.constructor_key = f.constructor_key
where f.driver_key = 1
group by d.full_name, c.constructor_name
order by total_points desc;

explain (analyze, buffers)
select d.full_name, count(*) as starts, sum(f.points) as total_points
from benchmark.fact_race_results f
join benchmark.dim_driver d on d.driver_key = f.driver_key
where f.constructor_key = 6 and f.circuit_key = 14
group by d.full_name
order by total_points desc;

explain (analyze, buffers)
select dt.full_date, ci.circuit_name, f.points
from benchmark.fact_race_results f
join benchmark.dim_date dt on dt.date_key = f.date_key
join benchmark.dim_circuit ci on ci.circuit_key = f.circuit_key
where f.is_win = 1 and f.driver_key = 1;

-- 3. indexing (primary keys + targeted b-tree, composite & partial indexes)
alter table benchmark.dim_date add primary key (date_key);
alter table benchmark.dim_driver add primary key (driver_key);
alter table benchmark.dim_constructor add primary key (constructor_key);
alter table benchmark.dim_circuit add primary key (circuit_key);
alter table benchmark.dim_status add primary key (status_key);
alter table benchmark.fact_race_results add primary key (result_key);

create index idx_bench_driver_key on benchmark.fact_race_results (driver_key);
create index idx_bench_constructor_circuit on benchmark.fact_race_results (constructor_key, circuit_key);
create index idx_bench_wins_driver on benchmark.fact_race_results (driver_key) where is_win = 1;

analyze benchmark.dim_date;
analyze benchmark.dim_driver;
analyze benchmark.dim_constructor;
analyze benchmark.dim_circuit;
analyze benchmark.dim_status;
analyze benchmark.fact_race_results;

-- 4. explain analyze after indexing
explain (analyze, buffers)
select d.full_name, c.constructor_name, count(*) as total_races, sum(f.points) as total_points, sum(f.is_win) as total_wins
from benchmark.fact_race_results f
join benchmark.dim_driver d on d.driver_key = f.driver_key
join benchmark.dim_constructor c on c.constructor_key = f.constructor_key
where f.driver_key = 1
group by d.full_name, c.constructor_name
order by total_points desc;

explain (analyze, buffers)
select d.full_name, count(*) as starts, sum(f.points) as total_points
from benchmark.fact_race_results f
join benchmark.dim_driver d on d.driver_key = f.driver_key
where f.constructor_key = 6 and f.circuit_key = 14
group by d.full_name
order by total_points desc;

explain (analyze, buffers)
select dt.full_date, ci.circuit_name, f.points
from benchmark.fact_race_results f
join benchmark.dim_date dt on dt.date_key = f.date_key
join benchmark.dim_circuit ci on ci.circuit_key = f.circuit_key
where f.is_win = 1 and f.driver_key = 1;

-- 5. verification: row counts, sizes & index usage
select
    t.table_name,
    (xpath('/row/cnt/text()', query_to_xml(format('select count(*) as cnt from dw.%I', t.table_name), false, true, '')))[1]::text::int as dw_rows,
    (xpath('/row/cnt/text()', query_to_xml(format('select count(*) as cnt from benchmark.%I', t.table_name), false, true, '')))[1]::text::int as benchmark_rows,
    pg_size_pretty(pg_total_relation_size(format('dw.%I', t.table_name))) as dw_size,
    pg_size_pretty(pg_total_relation_size(format('benchmark.%I', t.table_name))) as benchmark_size
from information_schema.tables t
where t.table_schema = 'benchmark'
order by benchmark_rows desc;

select
    relname as table_name,
    indexrelname as index_name,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
    idx_scan as times_used
from pg_stat_user_indexes
where schemaname = 'benchmark'
order by pg_relation_size(indexrelid) desc;
