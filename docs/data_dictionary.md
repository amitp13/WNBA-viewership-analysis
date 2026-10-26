# Data dictionary

This file will be a guide for information on 
1. Each raw table 
2. Content in the table (each row in the table) 
3. Columns used in the project.
4. Columns not listed (logos, colors, betting lines, weather and similar) are not used. 
5. Anything marked *unverified* is a reasonable reading of the column name that has not been checked against the data yet.

## How the tables fit together

The **schedule** is the backbone: one row per WNBA game. Everything else gets matched to it.

| Table | Connects to the schedule by | Used for |
|---|---|---|
| PLAYER_BOX | GAME_ID (same ESPN ID) | Was a star available for this game? |
| WNBA_ELO | Date + home team + away team (no shared ID, so team names must match) | How strong were the two teams? |
| NFL_GAMES | Time overlap only (was an NFL game on at the same time?) | Competition from the NFL |
| telecasts seed (not built yet) | Date + home team + away team | How many people watched |

## WNBA_SCHEDULE

**What it is:** Every WNBA game from ESPN, collected by the wehoop package. 2023, 2024 and 2025 seasons.
**One row =** one game. **Key:** GAME_ID. **Rows:** 839.
**Why 2023 is here:** it is out of scope for viewership, but it is needed to calculate Elo ratings for 2024 and 2025.

| Column | Meaning |
|---|---|
| GAME_ID | ESPN's unique ID for the game |
| SEASON | Season year |
| SEASON_TYPE | 2 = regular season bucket, 3 = postseason. Do not filter on this alone; see TYPE_ID |
| TYPE_ID | Finer game type: 1 = regular season, 4 = All-Star, 39 = Commissioner's Cup Championship, 14 = first round, 16 = semifinals, 17 = Finals |
| TYPE_ABBREVIATION | Short label for TYPE_ID (STD, ALLSTAR, CC, RD16, SEMI, FINAL). RD16 is the first round despite the name |
| NOTES_HEADLINE | Free-text note. The only marker of Commissioner's Cup group-stage games ("WNBA Commissioner's Cup") and of playoff game numbers |
| GAME_DATE | Date of the game |
| GAME_DATE_TIME | Exact start moment. Stored as TIMESTAMP_LTZ, so it displays in the session's time zone: "2023-09-10 10:00:00 -0700" is shown in Pacific and is 1:00 pm Eastern. Staging converts it to Eastern |
| HOME_ID, AWAY_ID | ESPN team IDs |
| HOME_DISPLAY_NAME, AWAY_DISPLAY_NAME | Full team names, for example "Indiana Fever" |
| HOME_ABBREVIATION, AWAY_ABBREVIATION | Short team codes |
| HOME_SCORE, AWAY_SCORE | Final scores |
| NEUTRAL_SITE | True if played at neither team's home arena |
| BROADCAST_NAME, BROADCAST_MARKET | Network and "national" or local, per ESPN. "National" includes streaming (Prime Video, ESPN3), so this cannot define a national telecast on its own; the telecasts seed decides |
| ATTENDANCE | Crowd at the arena (*not checked yet*) |

Dropped: ID (identical to GAME_ID on every row), UID, colors, logos, linescores, clock and status details, JSON flags.

## PLAYER_BOX

**What it is:** Box score lines from ESPN, collected by wehoop. 2024 and 2025 seasons.
**One row =** one player in one game. **Key:** GAME_ID + ATHLETE_ID. **Rows:** 13,069.
**Every game in the schedule has box score rows**, including All-Star and the Cup Championship.

| Column | Meaning |
|---|---|
| GAME_ID | Same ESPN game ID as the schedule |
| ATHLETE_ID | ESPN's unique player ID (Caitlin Clark = 4433403) |
| ATHLETE_DISPLAY_NAME | Player's name |
| TEAM_ID, TEAM_DISPLAY_NAME | The player's team in that game |
| OPPONENT_TEAM_ID | The other team |
| HOME_AWAY | Whether the player's team was home or away |
| DID_NOT_PLAY | True if the player was listed but did not play |
| REASON | Free text such as "COACH'S DECISION" or "RIGHT GROIN". Filled in even for players who played, so it only means something when DID_NOT_PLAY is true |
| MINUTES | Minutes played; empty when the player did not play |
| ACTIVE | **Not used.** Unreliable: Napheesa Collier started and played 44 minutes (game 401726992) with ACTIVE = false |
| POINTS, REBOUNDS, ASSISTS and other stats | Standard box score stats; not central to this project |

**Important:** a player who sits out does not always get a row. Clark had no row at all for 9 Fever games in 2025, all away games. So "was she available?" is answered by starting from every game her team played and looking for her row. No row means she did not play. A player who plays always has a row.

## WNBA_ELO

**What it is:** FiveThirtyEight's WNBA Elo ratings, a single number for each team's strength that goes up when they win and down when they lose.
**Covers:** 1997 to 2022 only. **Nothing for 2023, 2024 or 2025**, so this project calculates those seasons itself using FiveThirtyEight's method, starting from their final 2022 ratings.
**One row =** one game. **Key:** DATE + HOME_TEAM + AWAY_TEAM (there is no game ID). **Rows:** 5,841.

| Column | Meaning |
|---|---|
| SEASON | Season year |
| DATE | Game date, stored as text in YYYY-MM-DD format |
| PLAYOFF | 1 for playoff games |
| NEUTRAL | Neutral site flag (*unverified*) |
| HOME_TEAM, AWAY_TEAM | Team names in FiveThirtyEight's spelling. Active franchises appear under their current name even in early years (1997 shows "Las Vegas Aces"; *unverified* which franchise that is), while defunct teams keep their own names |
| HOME_TEAM_ABBR, AWAY_TEAM_ABBR | FiveThirtyEight's team codes |
| HOME_TEAM_PREGAME_RATING, AWAY_TEAM_PREGAME_RATING | Each team's Elo going into the game. This is what measures matchup quality |
| HOME_TEAM_WINPROB, AWAY_TEAM_WINPROB | Chance each team wins, based on the ratings |
| HOME_TEAM_SCORE, AWAY_TEAM_SCORE | Final scores |
| HOME_TEAM_POSTGAME_RATING, AWAY_TEAM_POSTGAME_RATING | Each team's Elo after the game |
| COMMISSIONERS_CUP_FINAL | Marks the Cup Championship game |
| STATUS | "post" (played) for every row |

## NFL_GAMES

**What it is:** NFL schedule and results from nflverse. 1999 to 2026.
**One row =** one game. **Key:** GAME_ID (nflverse format, unrelated to ESPN's WNBA IDs). **Rows:** 7,548.
**Used only to answer:** was an NFL game on at the same time as this WNBA game? The two seasons only overlap in September and October.

| Column | Meaning |
|---|---|
| GAME_ID | nflverse game ID |
| SEASON | NFL season. A season runs into the next calendar year (January playoffs belong to the previous season), so filter by date, not season |
| GAME_TYPE | REG = regular season; WC, DIV, CON, SB = playoff rounds through the Super Bowl. **No preseason** |
| GAMEDAY | Date, stored as text |
| WEEKDAY | Day of the week |
| GAMETIME | Kickoff time, stored as text. Empty in early seasons (1999 sample). Assumed Eastern (*unverified*; to be checked against a game with a known kickoff) |
| HOME_TEAM, AWAY_TEAM | NFL team codes |
| HOME_SCORE, AWAY_SCORE | Scores; empty for games not played yet (the 2026 season) |

## telecasts seed (not built yet)

**What it will be:** hand-built table of national WNBA telecasts with viewer counts, one source link per row.
**One row =** one national telecast.
**Columns:** game_date, home_team, away_team, network, start_time_et, viewers, source_url, notes.