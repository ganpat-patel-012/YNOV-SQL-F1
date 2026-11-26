-- grain : une ligne par ecurie et par saison (championnat constructeurs depuis 1958)
-- jointures : classement final + stats de course agregees par saison + pilotes de la saison
-- on agrege d'abord par course (doubles 1-2, abandons), puis par saison
with per_race as (
    select
        season_year,
        race_id,
        constructor_id,
        count(*) filter (where finish_position in (1, 2))  as cars_in_top_2,
        count(*) filter (where is_podium)                  as podium_finishes,
        count(*) filter (where is_not_classified)          as not_classified,
        bool_or(is_winner)                                 as has_won
    from {{ ref('int_race_results_enriched') }}
    group by
        season_year,
        race_id,
        constructor_id
),
race_stats as (
    select
        season_year,
        constructor_id,
        count(*)                                 as races,
        count(*) filter (where has_won)          as wins,
        count(*) filter (where cars_in_top_2 = 2) as one_two_finishes,
        sum(podium_finishes)                     as podium_finishes,
        sum(not_classified)                      as not_classified
    from per_race
    group by
        season_year,
        constructor_id
),
drivers as (
    select
        res.season_year,
        res.constructor_id,
        string_agg(distinct d.full_name, ', ')  as driver_names
    from {{ ref('int_race_results_enriched') }} res
    join {{ ref('stg_f1__drivers') }} d
        on d.driver_id = res.driver_id
    group by
        res.season_year,
        res.constructor_id
)
select
    st.season_year,
    st.constructor_id,
    c.constructor_name,
    c.constructor_nationality,
    dr.driver_names,
    st.final_position,
    st.season_points,
    st.is_champion,
    rs.races,
    rs.wins,
    rs.one_two_finishes,
    rs.podium_finishes,
    rs.not_classified
from {{ ref('int_constructor_season_standings') }} st
join {{ ref('stg_f1__constructors') }} c
    on c.constructor_id = st.constructor_id
left join race_stats rs
    on rs.season_year = st.season_year
   and rs.constructor_id = st.constructor_id
left join drivers dr
    on dr.season_year = st.season_year
   and dr.constructor_id = st.constructor_id
