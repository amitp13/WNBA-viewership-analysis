-- One row per national TV broadcast (2024-2025). The table the regression uses.

with telecasts as (
    select * from {{ ref('stg_telecasts') }}
),

games as (
    select game_id, season, game_type, is_playoff
    from {{ ref('stg_wehoop__schedule') }}
),

elo as (
    select game_id, home_elo_pre, away_elo_pre
    from {{ ref('int_elo_by_game') }}
),

stars as (
    select
        game_id,
        count_if(tier = 'superstar' and is_available)     as superstars_available,
        count_if(tier = 'superstar' and not is_available) as superstars_out,
        count_if(tier = 'star' and is_available)          as stars_available,
        count_if(tier = 'star' and not is_available)      as stars_out
    from {{ ref('int_star_availability') }}
    group by game_id
),

nfl as (
    select game_id, nfl_games_overlapping, has_nfl_overlap
    from {{ ref('int_nfl_overlap') }}
)

select
    -- keys
    t.game_id,
    t.game_date,
    t.home_team,
    t.away_team,
    t.network,
    -- outcome
    t.viewers,
    t.measurement,
    t.source_url,
    t.notes,
    -- game context
    g.season,
    g.game_type,
    g.is_playoff,
    t.start_time_et,
    dayname(t.start_time_et)                  as day_of_week,
    hour(t.start_time_et)                     as start_hour_et,
    -- stars
    coalesce(s.superstars_available, 0)       as superstars_available,
    coalesce(s.superstars_out, 0)             as superstars_out,
    coalesce(s.stars_available, 0)            as stars_available,
    coalesce(s.stars_out, 0)                  as stars_out,
    -- matchup quality
    e.home_elo_pre,
    e.away_elo_pre,
    (e.home_elo_pre + e.away_elo_pre) / 2     as elo_strength,
    abs(e.home_elo_pre - e.away_elo_pre)      as elo_gap,
    -- NFL competition
    n.nfl_games_overlapping,
    n.has_nfl_overlap
from telecasts as t
left join games as g on g.game_id = t.game_id
left join elo   as e on e.game_id = t.game_id
left join stars as s on s.game_id = t.game_id
left join nfl   as n on n.game_id = t.game_id