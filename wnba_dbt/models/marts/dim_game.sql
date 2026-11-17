-- One row per 2024-2025 WNBA game, with teams as team keys.
select
    s.game_id,
    s.season,
    s.game_type,
    s.is_playoff,
    s.is_commissioners_cup,
    h.team_key       as home_team,
    a.team_key       as away_team,
    s.home_score,
    s.away_score,
    s.attendance
from {{ ref('stg_wehoop__schedule') }} as s
join {{ ref('team_map') }} as h on h.espn_team_id = s.home_team_id
join {{ ref('team_map') }} as a on a.espn_team_id = s.away_team_id
where s.season in (2024, 2025)