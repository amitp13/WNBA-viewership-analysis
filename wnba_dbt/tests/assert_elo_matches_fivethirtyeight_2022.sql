-- Backtest: our Elo must reproduce FiveThirtyEight's published 2022 ratings.
-- Returns a row (= test fails) for any 2022 game that is missing on either side
-- or differs by more than 0.001 Elo points. See docs/decisions.md, "Elo backtest".

with evaluated as (
    select e.*, h.fivethirtyeight_abbr as home_abbr
    from {{ ref('int_elo_by_game') }} as e
    join {{ ref('team_map') }} as h
        on h.team_key = e.home_team
    where e.season = 2022
),

five_thirty_eight as (
    select *
    from {{ ref('stg_fivethirtyeight__elo') }}
    where season = 2022
)

select
    coalesce(f.game_date, e.game_date) as game_date,
    f.home_team_abbr,
    e.home_team,
    e.home_elo_pre  - f.home_elo_pre  as diff_home_pre,
    e.away_elo_pre  - f.away_elo_pre  as diff_away_pre,
    e.home_elo_post - f.home_elo_post as diff_home_post,
    e.away_elo_post - f.away_elo_post as diff_away_post
from five_thirty_eight as f
full outer join evaluated as e
    on  e.game_date = f.game_date
    and e.home_abbr = f.home_team_abbr
where e.home_team is null              -- game in FiveThirtyEight, missing from evaluated
   or f.home_team_abbr is null         -- game in evaluated, missing from FiveThirtyEight
   or abs(e.home_elo_pre  - f.home_elo_pre)  > 0.001
   or abs(e.away_elo_pre  - f.away_elo_pre)  > 0.001
   or abs(e.home_elo_post - f.home_elo_post) > 0.001
   or abs(e.away_elo_post - f.away_elo_post) > 0.001