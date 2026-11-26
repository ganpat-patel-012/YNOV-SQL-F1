-- pas de doublon ni de perte apres les jointures :
-- int_sprint_results_enriched doit avoir exactement le meme nombre de lignes que stg_f1__sprint_results
with i as (select count(*) as nb from {{ ref('int_sprint_results_enriched') }}),
     s as (select count(*) as nb from {{ ref('stg_f1__sprint_results') }})
select *
from i, s
where i.nb <> s.nb
