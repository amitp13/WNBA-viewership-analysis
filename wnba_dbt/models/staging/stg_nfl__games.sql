WITH source AS (
    SELECT * FROM {{ source('raw', 'nfl_games') }}
),

renamed AS (
    SELECT
        -- ids
        game_id,
        season,
        game_type,
        -- time (nflverse times are Eastern; confirmed Nov 8, 2026)
        TO_DATE(gameday)                  AS game_date,
        weekday,
        TO_TIMESTAMP_NTZ(gameday || ' ' || gametime, 'YYYY-MM-DD HH24:MI')
                                          AS kickoff_et,
        -- teams (NFL codes; never joined to WNBA teams)
        home_team,
        away_team
    FROM source
    -- filter on date, not season: an NFL season runs into the next calendar year
    WHERE TO_DATE(gameday) BETWEEN '2024-01-01' AND '2025-12-31'
)

SELECT * FROM renamed