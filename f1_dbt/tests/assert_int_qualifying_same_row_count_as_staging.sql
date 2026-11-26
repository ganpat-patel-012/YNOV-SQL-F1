-- pas de doublon ni de perte apres les jointures :
-- int_qualifying_vs_race doit avoir exactement le meme nombre de lignes que stg_f1__qualifying
with i as (select count(*) as nb from {{ ref('int_qualifying_vs_race') }}),
     s as (select count(*) as nb from {{ ref('stg_f1__qualifying') }})
select *
from i, s
where i.nb <> s.nb
