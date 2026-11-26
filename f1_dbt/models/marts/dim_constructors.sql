-- grain : une ligne par ecurie
-- jointures : ecurie + statistiques historiques + titres constructeurs (championnat depuis 1958)
with history as (
    select
        constructor_id,
        min(season_year)                                  as first_season,
        max(season_year)                                  as last_season,
        count(distinct race_id)                           as races,
        count(distinct race_id) filter (where is_winner)  as wins,
        count(*) filter (where is_podium)                 as podium_finishes
    from {{ ref('int_race_results_enriched') }}
    group by constructor_id
),
titles as (
    select
        constructor_id,
        count(*) filter (where is_champion)  as championships
    from {{ ref('int_constructor_season_standings') }}
    group by constructor_id
)
select
    c.constructor_id,
    c.constructor_ref,
    c.constructor_name,
    c.constructor_nationality,
    h.first_season,
    h.last_season,
    coalesce(h.races, 0)            as races,
    coalesce(h.wins, 0)             as wins,
    coalesce(h.podium_finishes, 0)  as podium_finishes,
    coalesce(t.championships, 0)    as championships
from {{ ref('stg_f1__constructors') }} c
left join history h
    on h.constructor_id = c.constructor_id
left join titles t
    on t.constructor_id = c.constructor_id
