-- pas de doublon ni de perte apres les jointures :
-- int_race_results_enriched doit avoir exactement le meme nombre de lignes que stg_f1__results
with i as (select count(*) as nb from {{ ref('int_race_results_enriched') }}),
     s as (select count(*) as nb from {{ ref('stg_f1__results') }})
select *
from i, s
where i.nb <> s.nb
