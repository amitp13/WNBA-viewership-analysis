with source AS (
    SELECT * FROM {{ source('raw', 'player_box') }}
),

renamed AS (
    SELECT 
        --ids
        game_id,
        athlete_id,
        season,
        -- game
        athlete_display_name          AS athlete_name,
        team_id,
        opponent_team_id,
        home_away = 'home'            AS is_home,
        did_not_play,
        CASE 
            WHEN did_not_play THEN reason 
        END                           AS dnp_reason,
        minutes                       AS minutes_played,
        starter                       AS is_starter,
        points                    
    FROM source
)

SELECT * FROM renamed