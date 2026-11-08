WITH source AS (
    SELECT * FROM {{ source('raw', 'wnba_elo') }}
),

renamed AS (
    SELECT
        -- game
        season,
        TO_DATE("DATE")                   AS game_date,
        playoff = 1                       AS is_playoff,
        commissioners_cup_final = 1       AS is_commissioners_cup_final,
        -- teams (FiveThirtyEight codes; mapped to team_key in intermediate)
        home_team_abbr,
        away_team_abbr,
        -- ratings
        home_team_pregame_rating          AS home_elo_pre,
        away_team_pregame_rating          AS away_elo_pre,
        home_team_postgame_rating         AS home_elo_post,
        away_team_postgame_rating         AS away_elo_post,
        home_team_winprob                 AS home_win_prob,
        -- scores (needed to replay the Elo updates)
        home_team_score,
        away_team_score
    FROM source
    WHERE season >= 2021
)

SELECT * FROM renamed