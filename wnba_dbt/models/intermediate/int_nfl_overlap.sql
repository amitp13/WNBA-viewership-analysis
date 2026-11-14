-- One row per 2024-2025 WNBA game: how many NFL games were on during its broadcast.
-- Rule (docs/decisions.md, NFL overlap rule): NFL window = kickoff to +3h15m, WNBA window = tip-off to +2h.
-- Two windows overlap when each one starts before the other one ends.

with wnba as (
    select game_id, game_date, start_time_et
    from {{ ref('stg_wehoop__schedule') }}
    where season in (2024, 2025)
),

nfl as (
    select game_id, kickoff_et
    from {{ ref('stg_nfl__games') }}
)

select
    w.game_id,
    w.game_date,
    w.start_time_et,
    count(n.game_id)      as nfl_games_overlapping,
    count(n.game_id) > 0  as has_nfl_overlap
from wnba as w
left join nfl as n
    on  n.kickoff_et < dateadd(hour, 2, w.start_time_et)        -- NFL starts before WNBA ends
    and dateadd(minute, 195, n.kickoff_et) > w.start_time_et    -- NFL ends (3h15m = 195 min) after WNBA starts
group by w.game_id, w.game_date, w.start_time_et