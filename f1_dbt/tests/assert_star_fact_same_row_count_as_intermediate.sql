-- le fait du schema en etoile a exactement le meme nombre de lignes que l'intermediate (slide 26)
with f as (select count(*) as nb from {{ ref('star_fact_race_results') }}),
     i as (select count(*) as nb from {{ ref('int_race_results_enriched') }})
select *
from f, i
where f.nb <> i.nb
