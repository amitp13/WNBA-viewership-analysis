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

## Team mapping (Oct 30, 2026)

**One team key per franchise, defined in seeds/team_map.csv.** The key is the team nickname in lowercase (aces, sun), so it does not depend on any source's codes. Every model and the telecasts seed use it.

**wehoop maps on ESPN team_id, not abbreviation.** ESPN changed Connecticut's abbreviation from CONN (2023) to CON (2024 onward) while keeping team_id 18. Mapping on abbreviation would have split one franchise into two.

**FiveThirtyEight maps on its own codes or names.** Names match ESPN for all 12 teams in 2021 and 2022, but 5 codes differ (LVA/LV, LAS/LA, NYL/NY, PHO/PHX, WAS/WSH), so joining on codes without the map would silently drop those teams. FiveThirtyEight's older history (for example 1997 rows labeled "Las Vegas Aces") does not matter here, because the project uses 2021 onward.

**Golden State has no FiveThirtyEight row.** The team joined in 2025, after the Elo file ends, so its Elo starts fresh in 2025.

**NFL teams are not mapped.** NFL games are only matched to WNBA games by time overlap, never by team. This narrows the original plan, which said every source would use one team key.

**Tests:** team_key and espn_team_id are unique and not null; fivethirtyeight_abbr is unique (nulls allowed, for Golden State). Relationships tests confirm every home and away team in stg_wehoop__schedule exists in team_map.

## Elo staging (Nov 8, 2026)

**Kept 2021 and 2022 only.** 2021 seeds the 2022 backtest; end-of-2022 ratings seed the 2023-2025 extension.

**Row check:** 450 games. 408 regular season matches the arithmetic exactly (2021: 12 teams x 32 games / 2 = 192; 2022: 12 x 36 / 2 = 216), plus 2 Cup finals and 40 playoff games.

**PLAYOFF and COMMISSIONERS_CUP_FINAL are stored as 0/1 numbers.** Staging turns them into true/false (is_playoff, is_commissioners_cup_final) to match the schedule model.

**Dropped NEUTRAL.** It is 0 on all 450 games in 2021-2022, so it carries no information. If the extension needs neutral sites, it uses NEUTRAL_SITE from the schedule.

**Team codes stay as FiveThirtyEight's own.** Mapping to team_key happens in intermediate, the same way schedule staging keeps ESPN IDs. Relationships tests confirm every code exists in team_map.

## NFL staging (Nov 8, 2026)

**Kickoff times are Eastern (confirmed).** In September and October of 2024 and 2025, the most common Sunday kickoff is 13:00 (119 of 246 games), which is the standard 1:00 pm Eastern window. Other slots fit too: 16:05 and 16:25 Sunday afternoon, 20:15 Monday and Thursday nights, 20:20 Sunday night, and 09:30 Sunday for international games.

**No Saturday NFL games in September or October** of either season, so Saturday WNBA games never face NFL competition.

**Kept calendar years 2024 and 2025 only,** filtered on game date, not season, because an NFL season runs into the next calendar year. This also drops the unplayed 2026 games.

**Staging builds kickoff_et only.** Deciding when an NFL game "overlaps" a WNBA telecast needs an assumption about how long an NFL broadcast lasts, so that rule lives in intermediate.

## Viewership table rules (Nov 11, 2026)

These rules decide what goes into seeds/telecasts.csv. Each row is one national TV broadcast of one game.

1. **Which games count.** Every 2024 or 2025 regular season or playoff game on a national TV network: ABC, CBS, ESPN, ESPN2, ION, NBA TV, and CBS Sports Network if it appears in the schedule. ESPN and ESPN2 are separate network values. Streaming-only games (for example Prime Video) are left out. If a TV game was also streamed, the row uses the TV network. Step 4.2 confirms the exact network names from the schedule.
2. **Teams.** home_team and away_team use team_key from team_map (fever, sky).
3. **Viewers.** Whole number (2700000, not 2.7M). If the source only gives a rounded figure, notes = "rounded".
4. **Measurement.** Column measurement = panel or big_data_panel. Record the number exactly as the source reports it, never adjusted. Nielsen made Big Data + Panel the official number on Sept 1, 2025 ([Nielsen](https://www.nielsen.com/news-center/2025/nielsen-begins-updated-era-of-tv-ratings-with-big-data-panel-for-this-falls-tv-season)), and most 2025 regular season figures are panel only ([Sports Media Watch](https://www.sportsmediawatch.com/2025/10/wnba-playoff-ratings-aces-fever-game-five-viewership/)). The switch happened partway through 2025, not between seasons, so the regression needs a measurement flag on top of the season fixed effect. If a source gives both numbers, use big_data_panel and put the panel number in notes.
5. **Sources, in order.** The network's own press room (ESPN Press Room for ABC, ESPN and ESPN2), then Sports Media Watch, then Front Office Sports. One link per row, to the article that gives that game's number.
6. **No published number.** The game stays. viewers, measurement and source_url are blank, notes = "not published". This keeps coverage measurable ("X of Y national games had a published audience").

## National game list (Nov 11, 2026)

**Network names kept (7):** ABC, CBS, CBSSN (CBS Sports Network), ESPN, ESPN2, ION, NBA TV. Filtered on BROADCAST_NAME, not BROADCAST_MARKET, because "national" also includes streaming.

**Dropped:** WNBA League Pass, Prime Video and ESPN3 (streaming); MNMT, WWOR-TV and KFAA-TV (local channels). Each game has exactly one broadcast name, so a national game listed under a local or streaming name would be missed; rechecked in step 4.9.

**Result:** 303 national TV games, no duplicates. 2024: 145. 2025: 158.

| Network | 2024 | 2025 |
|---|---|---|
| ABC | 12 | 16 |
| CBS | 8 | 9 |
| CBSSN | 12 | 11 |
| ESPN | 27 | 27 |
| ESPN2 | 7 | 6 |
| ION | 43 | 50 |
| NBA TV | 36 | 39 |

**Checked against ESPN's published 2025 counts:** 25 regular season games on ABC, ESPN and ESPN2, 12 of them on ABC, and 24 postseason games ([ESPN Press Room](https://espnpressroom.com/press-release/espn-networks-deliver-most-watched-wnba-regular-season-ever/), [ESPN Press Room](https://espnpressroom.com/press-release/espns-monumental-wnba-season-sets-new-viewership-records/)). All three match. The 2025 Finals networks match game by game ([Front Office Sports](https://frontofficesports.com/?p=205896)).

## Elo method (Nov 11, 2026)

Source: FiveThirtyEight, "How Our WNBA Predictions Work" ([archived copy](WAYBACK_LINK_HERE)). The live page now redirects to ABC News, so the archived copy is the reference.

| Part | Rule |
|---|---|
| Starting rating | League average is 1500; every team started at 1500 in 1997 |
| Win probability | Pr(A) = 1 / (10^(-EloDiff / 400) + 1), where EloDiff = A's pregame Elo minus B's, after adjustments |
| Home court | +80 to the home team's side of EloDiff |
| Playoffs | EloDiff (after home court) x 1.25 |
| K-factor | 28 |
| Margin of victory multiplier | (winning margin + 3)^0.8 / (7.5 + 0.006 x EloDiff), EloDiff from the winner's side (negative when the underdog wins) |
| Update | shift = 28 x margin multiplier x (1 - winner's pregame win probability). Winner gains the shift, loser loses it |
| Between seasons | New preseason rating = 0.5 x last postgame rating + 0.5 x 1500 |
| New team | Not stated on the page. FiveThirtyEight's own file starts all 10 expansion teams (1998 to 2008) at 1300 in their first game, so Golden State starts 2025 at 1300 |

**Home court and the playoff factor change the rating update, not only the prediction.** Both adjust EloDiff, and EloDiff feeds the win probability and the margin multiplier.

**Team codes in the file follow the current franchise.** For example, LVA appears in 1997, so expansion was identified by first appearance, not by code.

## Open items

| # | Item | Status |
|---|---|---|
| A | 2023 has 241 regular season games vs 240 in 2024 | Open; resolve during the Elo extension (2023 feeds Elo) |
| B | Clark has 45 rows but only 44 in Fever games | **Closed Oct 27:** the extra row is the 2025 All-Star game (TEAM CLARK) |
| C | Missing box score rows cluster in away games; cause unverified | Logged only; does not affect the design |
| D | 2025 = 13 teams x 44 games; 286 matches the arithmetic but is not verified from a league source | Partly confirmed Oct 30: the schedule has 12 teams in 2023 and 2024 and 13 in 2025. Games per team still unchecked |
| E | Include All-Star and the Cup Championship in scope? | **Closed Oct 27:** see Schedule scope |
| F | Convert GAME_DATE_TIME (TIMESTAMP_LTZ) to Eastern | **Closed Oct 27:** start_time_et in stg_wehoop__schedule. ESPN's game_date equals the Eastern date on every game, so it is safe to match on. Early (11:00 to 11:30 am, July weekdays) and late (10:30 to 11 pm, West Coast home games) starts checked and look real |
| H | Verify FiveThirtyEight's Elo method (K = 28, half-rating carryover) from their own source | Open; Elo extension |