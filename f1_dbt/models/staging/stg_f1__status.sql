-- une ligne par statut d'arrivee
select
    status_id,
    trim(status) as status_label
from {{ source('f1', 'status') }}
