-- One row per star per game her team played. See docs/decisions.md, "Star rule".
-- Availability starts from team games, not box scores (decisions.md, finding 4):
-- no box score row or DID_NOT_PLAY = unavailable.

WITH stars AS (
    SELECT season, athlete_id, athlete_name, tier
    FROM {{ ref('star_tiers') }}
),

schedule AS (
    SELECT game_id, season, game_date, home_team_id, away_team_id
    FROM {{ ref('stg_wehoop__schedule') }}
),

-- box score rows for real games only (the schedule already drops All-Star games)
box AS (
    SELECT b.game_id, b.athlete_id, b.team_id, b.did_not_play, b.dnp_reason
    FROM {{ ref('stg_wehoop__player_box') }} AS b
    INNER JOIN schedule AS s
        ON b.game_id = s.game_id
),

-- each star's team that season, taken from her own box score rows
star_team AS (
    SELECT DISTINCT
        st.season,
        st.athlete_id,
        b.team_id
    FROM stars AS st
    INNER JOIN box AS b
        ON b.athlete_id = st.athlete_id
    INNER JOIN schedule AS s
        ON b.game_id = s.game_id
       AND s.season = st.season
),

-- every game each team played, home or away
team_games AS (
    SELECT game_id, season, game_date, home_team_id AS team_id FROM schedule
    UNION ALL
    SELECT game_id, season, game_date, away_team_id AS team_id FROM schedule
)

SELECT
    tg.game_id,
    tg.season,
    tg.game_date,
    st.athlete_id,
    stars.athlete_name,
    stars.tier,
    st.team_id,
    COALESCE(NOT b.did_not_play, FALSE)   AS is_available,
    b.athlete_id IS NULL                  AS has_no_box_row,
    b.dnp_reason
FROM star_team AS st
INNER JOIN stars
    ON stars.season = st.season
   AND stars.athlete_id = st.athlete_id
INNER JOIN team_games AS tg
    ON tg.season = st.season
   AND tg.team_id = st.team_id
LEFT JOIN box AS b
    ON b.game_id = tg.game_id
   AND b.athlete_id = st.athlete_id