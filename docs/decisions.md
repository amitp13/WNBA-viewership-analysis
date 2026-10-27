# Decisions log

## Raw data exploration (Oct 26, 2026)

### Grain of each raw table

| Table | Grain | Key | Proof |
|---|---|---|---|
| WNBA_SCHEDULE | One row per game | GAME_ID | 839 rows = 839 distinct GAME_IDs |
| PLAYER_BOX | One row per player per game | GAME_ID + ATHLETE_ID | 13,069 rows = 13,069 distinct pairs; no null athlete IDs; every schedule game has a box score |
| WNBA_ELO | One row per game | DATE + HOME_TEAM + AWAY_TEAM (no game ID) | Rows = distinct combinations in every season |
| NFL_GAMES | One row per game | GAME_ID | Rows = distinct IDs, 2023 to 2026 |

### Findings and decisions

1. **Filter game types on TYPE_ID, not SEASON_TYPE.** SEASON_TYPE 2 mixes regular season (TYPE_ID 1), All-Star (4) and the Commissioner's Cup Championship (39). Each TYPE_ID belongs to exactly one SEASON_TYPE. SEASON_TYPE 3 is the postseason. The first round abbreviation is RD16, so round labels get written in staging.
2. **Drop ID from the schedule.** It equals GAME_ID on every row.
3. **Commissioner's Cup.** TYPE_ID 39 is only the championship game, one per season. Group-stage Cup games are ordinary regular season games marked only by NOTES_HEADLINE = "WNBA Commissioner's Cup". Staging keeps an is_commissioners_cup flag.
4. **Star availability starts from team games, not box scores.** A player who sits out sometimes has a DID_NOT_PLAY row and sometimes no row at all. Caitlin Clark, 2025: 9 Fever games with no row, all away games. Availability = every game the team played, left joined to player rows; no row counts as unavailable. This is safe because a player who plays always has a row.
5. **FiveThirtyEight Elo ends with the 2022 season** (last game 2022-09-18). The extension covers 2023, 2024 and 2025, seeded from end-of-2022 ratings, so the 2023 schedule stays. With no overlap years, validation becomes a backtest: replay 2022 from end-of-2021 ratings and match their published 2022 ratings.
6. **NFL file has no preseason** (REG, WC, DIV, CON, SB only). August WNBA games always show no NFL competition, and NFL overlap only exists for September and October games. The file includes the 2026 season with unplayed games. Filter NFL by date, not season, because an NFL season runs into the next calendar year.
7. **Sample rows:** PLAYER_BOX.ACTIVE is unreliable (a starter who played 44 minutes had ACTIVE = false), so it is not used. REASON is filled even for players who played, so it only counts when DID_NOT_PLAY is true. BROADCAST_MARKET = "national" includes streaming, so it cannot define a national telecast.

## Schedule scope (Oct 27, 2026)

**All-Star games are dropped in staging.** The teams are not franchises (2024: Team WNBA vs Team USA; 2025: Team Clark vs Team Collier, with their own team IDs), so there is no Elo and star availability has no meaning. This also explains Clark's extra box score row: the 2025 All-Star game, listed under TEAM CLARK.

**Cup Championship games stay.** FiveThirtyEight rated them (2021 and 2022 Cup finals both change the home team's rating), so the Elo extension must include them. Both in-scope Cup finals were on Prime Video per ESPN, so they will likely fall outside the viewership analysis, which excludes streaming-only broadcasts. Whether either was also on TV is unverified.

**Staging drops only what is never valid.** The schedule feeds two things: Elo needs every rated game (regular season, Cup finals, playoffs, 2023 included), while viewership needs only national telecasts. Which games count as national telecasts is decided by matching the telecasts seed to games, not by a filter in staging.

| Game type | Staging | Elo | Viewership |
|---|---|---|---|
| Regular season (incl. Cup group games) | Keep | Yes | Only if in telecasts seed |
| Cup Championship | Keep, flagged | Yes | Only if in telecasts seed |
| Playoffs | Keep | Yes | Only if in telecasts seed |
| All-Star | Drop | No | No |

## Open items

| # | Item | Status |
|---|---|---|
| A | 2023 has 241 regular season games vs 240 in 2024 | Open; resolve during the Elo extension (2023 feeds Elo) |
| B | Clark has 45 rows but only 44 in Fever games | **Closed Oct 27:** the extra row is the 2025 All-Star game (TEAM CLARK) |
| C | Missing box score rows cluster in away games; cause unverified | Logged only; does not affect the design |
| D | 2025 = 13 teams x 44 games; 286 matches the arithmetic but is not verified from a league source | Open; verify before the README cites it |
| E | Include All-Star and the Cup Championship in scope? | **Closed Oct 27:** see Schedule scope |
| F | Convert GAME_DATE_TIME (TIMESTAMP_LTZ) to Eastern | **Closed Oct 27:** start_time_et in stg_wehoop__schedule. ESPN's game_date equals the Eastern date on every game, so it is safe to match on. Early (11:00 to 11:30 am, July weekdays) and late (10:30 to 11 pm, West Coast home games) starts checked and look real |
| H | Verify FiveThirtyEight's Elo method (K = 28, half-rating carryover) from their own source | Open; Elo extension |