-- One row per date that has at least one national broadcast.
select distinct
    game_date,
    year(game_date)                         as year,
    month(game_date)                        as month,
    dayname(game_date)                      as day_name,
    dayofweekiso(game_date) in (6, 7)       as is_weekend
from {{ ref('stg_telecasts') }}