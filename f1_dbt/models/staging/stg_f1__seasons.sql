-- une ligne par saison
select
    cast(year as integer) as season_year
from {{ source('f1', 'seasons') }}
