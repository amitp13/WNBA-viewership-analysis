-- One row per national TV broadcast, matched to its game in the schedule.
-- Match on Eastern game date + home team + away team (ESPN's game_date is the Eastern date; see decisions.md, item F).
-- Left joins on purpose: a row that fails to match keeps game_id empty, and the test in the next step catches it.

with telecasts as (
    select * from {{ ref('telecasts') }}
),

team_map as (
    select team_key, espn_team_id
    from {{ ref('team_map') }}
),

schedule as (
    select game_id, game_date, home_team_id, away_team_id
    from {{ ref('stg_wehoop__schedule') }}
)

select
    s.game_id,
    t.game_date,
    t.home_team,
    t.away_team,
    t.network,
    t.start_time_et,
    t.viewers,
    t.measurement,
    t.source_url,
    t.notes
from telecasts as t
left join team_map as h
    on h.team_key = t.home_team
left join team_map as a
    on a.team_key = t.away_team
left join schedule as s
    on  s.game_date    = t.game_date
    and s.home_team_id = h.espn_team_id
    and s.away_team_id = a.espn_team_id