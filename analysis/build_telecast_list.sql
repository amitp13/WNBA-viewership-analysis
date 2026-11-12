-- Builds the national TV game list in wnba_dbt/seeds/telecasts.csv (step 4.2, Nov 11, 2026).
-- Run in Snowflake, download as CSV, lowercase the header, save as the seed.
-- Network filter and counts: docs/decisions.md, "National game list".
select
    s.game_date,
    h.team_key                  as home_team,
    a.team_key                  as away_team,
    s.espn_broadcast_network    as network,
    s.start_time_et,
    null                        as viewers,
    null                        as measurement,
    null                        as source_url,
    null                        as notes
from wnba.dev_staging.stg_wehoop__schedule as s
join wnba.dev_seeds.team_map as h
    on h.espn_team_id = s.home_team_id
join wnba.dev_seeds.team_map as a
    on a.espn_team_id = s.away_team_id
where s.season in (2024, 2025)
  and s.espn_broadcast_network in ('ABC', 'CBS', 'CBSSN', 'ESPN', 'ESPN2', 'ION', 'NBA TV')
order by s.game_date, s.start_time_et;