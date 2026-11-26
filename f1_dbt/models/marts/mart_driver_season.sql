-- grain : une ligne par pilote et par saison
-- jointures : classement final + stats de course + poles + sprints + ecurie(s) de la saison
-- chaque source est agregee au grain (saison, pilote) AVANT la jointure, pour ne pas dupliquer les lignes
-- season_points vient du classement officiel (resultats retires dans les annees anciennes, points sprint inclus)
with race_stats as (
    select
        res.season_year,
        res.driver_id,
        count(distinct res.race_id)                                   as races,
        count(distinct res.race_id) filter (where res.is_winner)      as wins,
        count(distinct res.race_id) filter (where res.is_podium)      as podiums,
        count(*) filter (where res.is_not_classified)                 as not_classified,
        round(avg(res.positions_gained), 2)                           as avg_positions_gained,
        sum(res.laps_led)                                             as laps_led,
        string_agg(distinct c.constructor_name, ', ')                 as constructor_names
    from {{ ref('int_race_results_enriched') }} res
    join {{ ref('stg_f1__constructors') }} c
        on c.constructor_id = res.constructor_id
    group by
        res.season_year,
        res.driver_id
),
poles as (
    select
        season_year,
        driver_id,
        count(*) filter (where is_pole_position)  as poles
    from {{ ref('int_qualifying_vs_race') }}
    group by
        season_year,
        driver_id
),
sprints as (
    select
        season_year,
        driver_id,
        count(*) filter (where is_winner)  as sprint_wins,
        sum(points)                        as sprint_points
    from {{ ref('int_sprint_results_enriched') }}
    group by
        season_year,
        driver_id
)
select
    st.season_year,
    st.driver_id,
    d.full_name,
    d.driver_nationality,
    rs.constructor_names,
    st.final_position,
    st.season_points,
    st.is_champion,
    rs.races,
    rs.wins,
    rs.podiums,
    rs.not_classified,
    p.poles,                                       -- vide avant 1994 (pas de donnees de qualification)
    s.sprint_wins,                                 -- vide avant 2021 (pas de sprints)
    s.sprint_points,
    rs.avg_positions_gained,
    rs.laps_led
from {{ ref('int_driver_season_standings') }} st
join {{ ref('stg_f1__drivers') }} d
    on d.driver_id = st.driver_id
left join race_stats rs
    on rs.season_year = st.season_year
   and rs.driver_id = st.driver_id
left join poles p
    on p.season_year = st.season_year
   and p.driver_id = st.driver_id
left join sprints s
    on s.season_year = st.season_year
   and s.driver_id = st.driver_id
