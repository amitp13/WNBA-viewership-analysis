-- One row per WNBA franchise.
select
    team_key,
    team_name,
    espn_team_id
from {{ ref('team_map') }}