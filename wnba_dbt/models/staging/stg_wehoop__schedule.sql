with source AS (
    SELECT * 
    FROM {{source('raw', 'wnba_schedule')}}
),

renamed AS (
    SELECT 
    -- ids
        game_id,
        season,

        type_id,
    -- game type details (derived)
        CASE type_id
            WHEN 1  THEN 'regular_season'
            WHEN 39 THEN 'commissioners_cup_final'
            WHEN 14 THEN 'first_round'
            WHEN 16 THEN 'semifinals'
            WHEN 17 THEN 'finals'
        END                        AS game_type,
        type_id IN (14, 16, 17)    AS is_playoff,
        COALESCE(notes_headline ilike '%commissioner%cup%', false)
                                   AS is_commissioners_cup,
    -- time
        game_date,
        convert_timezone('America/New_York', game_date_time)::timestamp_ntz 
                                   AS start_time_et,
    -- teams
        home_id                    AS home_team_id,
        home_display_name          AS home_team_name,
        home_abbreviation          AS home_team_abbr,
        away_id                    AS away_team_id,
        away_display_name          AS away_team_name,
        away_abbreviation          AS away_team_abbr,
    -- results
        home_score,
        away_score, 
    -- venue and broadcast
        neutral_site               AS is_neutral_site,
        attendance::integer        AS attendance,
        broadcast_name             AS espn_broadcast_network,
        broadcast_market           AS espn_broadcast_market,
        notes_headline
    FROM source
    WHERE type_id != 4    -- drop All-Star games (see docs/decisions.md)
) 

SELECT * FROM renamed