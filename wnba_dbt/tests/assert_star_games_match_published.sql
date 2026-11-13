-- Regular season games played for 5 star-seasons, checked against published counts.
-- Sources:
-- Sabally 2024, 15: https://au.sports.yahoo.com/wnba-free-agent-star-satou-sabally-says-shes-played-final-game-for-dallas-wings-211018086.html
-- Collier 2024, 34: https://africa.espn.com/wnba/player/stats/_/id/3917450
-- Collier 2025, 33: https://www.wnba.com/webview/player/1629483/napheesa-collier
-- Stewart 2025, 31: https://fieldlevelmedia.com/news/liberty-f-breanna-stewart-game-time-decision-for-game-2/
-- Clark 2025, 13: https://fever.wnba.com/news/indiana-fever-guard-caitlin-clark-ruled-out-for-remainder-of-2025-season

WITH published AS (
    SELECT * FROM (VALUES
        (2024, 4281929, 15),
        (2024, 3917450, 34),
        (2025, 3917450, 33),
        (2025, 2998928, 31),
        (2025, 4433403, 13)
    ) AS t(season, athlete_id, expected_played)
),

ours AS (
    SELECT
        a.season,
        a.athlete_id,
        COUNT_IF(a.is_available) AS played
    FROM {{ ref('int_star_availability') }} AS a
    INNER JOIN {{ ref('stg_wehoop__schedule') }} AS s
        ON a.game_id = s.game_id
    WHERE s.game_type = 'regular_season'
    GROUP BY a.season, a.athlete_id
)

-- fails on any mismatch or missing player
SELECT p.season, p.athlete_id, p.expected_played, o.played
FROM published AS p
LEFT JOIN ours AS o
    ON o.season = p.season
   AND o.athlete_id = p.athlete_id
WHERE o.played IS NULL
   OR o.played != p.expected_played