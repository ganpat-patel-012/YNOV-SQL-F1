{{ config(alias='dim_status') }}
-- grain : une ligne par statut d'arrivee, comme dw.dim_status
-- category : regroupement des 139 statuts en 5 familles pour l'analyse de fiabilite
select
    status_id     as status_key,
    status_label  as status,
    case
        when status_label = 'Finished' then 'Finished'
        when status_label like '+%Lap%' then 'Lapped'
        when status_label in ('Accident', 'Collision', 'Spun off', 'Collision damage', 'Damage')
            then 'Accident / Collision'
        when status_label in ('Disqualified', 'Excluded', 'Withdrew', 'Did not qualify', 'Did not prequalify')
            then 'Disqualified / DNS'
        else 'Mechanical / Other DNF'
    end           as category
from {{ ref('stg_f1__status') }}
