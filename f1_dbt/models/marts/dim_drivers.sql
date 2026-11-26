-- grain : une ligne par pilote
-- jointures : pilote + statistiques de carriere + titres de champion
-- count(distinct race_id) : un pilote peut avoir 2 resultats dans un meme GP (voitures partagees, annees 50-60)
with career as (
    select
        driver_id,
        min(season_year)                                  as first_season,
        max(season_year)                                  as last_season,
        count(distinct race_id)                           as races,
        count(distinct race_id) filter (where is_winner)  as wins,
        count(distinct race_id) filter (where is_podium)  as podiums
    from {{ ref('int_race_results_enriched') }}
    group by driver_id
),
titles as (
    select
        driver_id,
        count(*) filter (where is_champion)  as championships
    from {{ ref('int_driver_season_standings') }}
    group by driver_id
)
select
    d.driver_id,
    d.driver_ref,
    d.driver_code,
    d.driver_number,
    d.first_name,
    d.last_name,
    d.full_name,
    d.date_birth,
    d.driver_nationality,
    c.first_season,
    c.last_season,
    coalesce(c.races, 0)          as races,
    coalesce(c.wins, 0)           as wins,
    coalesce(c.podiums, 0)        as podiums,
    coalesce(t.championships, 0)  as championships
from {{ ref('stg_f1__drivers') }} d
left join career c
    on c.driver_id = d.driver_id
left join titles t
    on t.driver_id = d.driver_id
