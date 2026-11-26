-- grain : une ligne par Grand Prix avec donnees d'arrets aux stands (depuis 2011)
-- jointures : resultats enrichis (arrets deja agreges par pilote) + Grand Prix
-- mediane plutot que moyenne pour la duree : un drapeau rouge cree des arrets de plusieurs minutes
with driver_stops as (
    select
        race_id,
        driver_id,
        is_winner,
        is_not_classified,
        positions_gained,
        pit_stop_count,
        total_pit_milliseconds / nullif(pit_stop_count, 0)  as avg_stop_milliseconds
    from {{ ref('int_race_results_enriched') }}
    where season_year >= 2011
)
select
    ds.race_id,
    ra.season_year,
    ra.round_number,
    ra.race_name,
    ra.circuit_id,
    round(avg(ds.pit_stop_count) filter (where not ds.is_not_classified), 2)
                                                          as avg_pit_stops_classified,
    max(ds.pit_stop_count) filter (where ds.is_winner)    as winner_pit_stops,
    percentile_cont(0.5) within group (order by ds.avg_stop_milliseconds)
                                                          as median_stop_milliseconds,
    round(cast(corr(ds.pit_stop_count, ds.positions_gained)
               filter (where not ds.is_not_classified) as numeric), 3)
                                                          as corr_stops_vs_positions_gained
from driver_stops ds
join {{ ref('stg_f1__races') }} ra
    on ra.race_id = ds.race_id
group by
    ds.race_id,
    ra.season_year,
    ra.round_number,
    ra.race_name,
    ra.circuit_id
having sum(ds.pit_stop_count) > 0
