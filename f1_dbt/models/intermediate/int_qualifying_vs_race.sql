-- grain : une ligne par pilote et par seance de qualification (donnees depuis 1994)
-- jointures : qualification + resultat de course du meme pilote + Grand Prix
-- enrichissement : places gagnees ou perdues entre la qualification et l'arrivee
select
    q.qualify_id,
    q.race_id,
    q.driver_id,
    q.constructor_id,
    ra.season_year,
    ra.date_race,
    q.qualifying_position,
    res.grid_position,
    res.finish_position,
    res.finish_position_order,
    res.classification_status,
    q.qualifying_position - res.finish_position_order  as places_gained_vs_qualifying,
    q.qualifying_position = 1                          as is_pole_position,
    coalesce(q.qualifying_position = 1 and res.finish_position = 1, false)
                                                       as is_pole_converted_to_win
from {{ ref('stg_f1__qualifying') }} q
join {{ ref('stg_f1__results') }} res
    on res.race_id = q.race_id
   and res.driver_id = q.driver_id
join {{ ref('stg_f1__races') }} ra
    on ra.race_id = q.race_id
