-- grain : une ligne par circuit ayant accueilli au moins un Grand Prix avec resultats
-- jointures : resultats agreges par circuit + qualifications agregees par circuit + circuit
-- positions gagnees calculees sur les pilotes classes seulement (un abandon n'est pas un depassement subi)
with race_stats as (
    select
        circuit_id,
        count(distinct race_id)                                       as races,
        round(avg(positions_gained) filter (where not is_not_classified), 2)
                                                                      as avg_positions_gained,
        round(100.0 * count(*) filter (where is_not_classified) / count(*), 1)
                                                                      as pct_not_classified,
        round(avg(pit_stop_count) filter (where season_year >= 2011), 2)
                                                                      as avg_pit_stops_since_2011
    from {{ ref('int_race_results_enriched') }}
    group by circuit_id
),
pole_stats as (
    select
        ra.circuit_id,
        count(*) filter (where q.is_pole_position)          as poles,
        count(*) filter (where q.is_pole_converted_to_win)  as poles_converted
    from {{ ref('int_qualifying_vs_race') }} q
    join {{ ref('stg_f1__races') }} ra
        on ra.race_id = q.race_id
    group by ra.circuit_id
)
select
    c.circuit_id,
    c.circuit_name,
    c.city,
    c.country,
    rs.races,
    rs.avg_positions_gained,
    rs.pct_not_classified,
    rs.avg_pit_stops_since_2011,
    ps.poles,                                         -- qualifications depuis 1994
    round(100.0 * ps.poles_converted / nullif(ps.poles, 0), 1)
                                                      as pct_pole_to_win
from race_stats rs
join {{ ref('stg_f1__circuits') }} c
    on c.circuit_id = rs.circuit_id
left join pole_stats ps
    on ps.circuit_id = rs.circuit_id
