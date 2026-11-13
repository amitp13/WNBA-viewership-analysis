-- Fails if any star played for more than one team in a season.
SELECT season, athlete_id, COUNT(DISTINCT team_id) AS teams
FROM {{ ref('int_star_availability') }}
GROUP BY season, athlete_id
HAVING COUNT(DISTINCT team_id) > 1