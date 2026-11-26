-- pas de doublon ni de perte apres les jointures :
-- int_constructor_race_results doit avoir exactement le meme nombre de lignes que stg_f1__constructor_results
with i as (select count(*) as nb from {{ ref('int_constructor_race_results') }}),
     s as (select count(*) as nb from {{ ref('stg_f1__constructor_results') }})
select *
from i, s
where i.nb <> s.nb
