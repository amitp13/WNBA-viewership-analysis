# Elo ratings for every WNBA game from 2022 to 2025, using FiveThirtyEight's method.
# Method and sources: docs/decisions.md, "Elo method", "Where Elo runs",
# "Elo backtest" and "Elo extension".
#
# 2022: FiveThirtyEight's own games, seeded from their end-of-2021 ratings.
#       tests/assert_elo_matches_fivethirtyeight_2022.sql checks this season.
# 2023-2025: games from the wehoop schedule, continuing the same ratings.

from snowflake.snowpark.types import (
    StructType, StructField, LongType, DateType, BooleanType, StringType, DoubleType,
)

K = 28                     # how far one game moves a rating
HOME_ADVANTAGE = 80        # Elo points added to the home team
PLAYOFF_MULTIPLIER = 1.25  # playoff games: rating gap counts 25% more
LEAGUE_AVERAGE = 1500
CARRYOVER = 0.5            # share of last season's rating a team keeps
NEW_TEAM_RATING = 1300     # FiveThirtyEight started every expansion team here

# Games with no home team. ESPN's neutral-site flag is not used directly: it also
# marks a 2024 Mystics home game moved to another Washington arena.
# 401736325 = Storm vs Dream, Aug 15, 2025, Vancouver.
NEUTRAL_SITE_GAME_IDS = {401736325}


def play_game(home_elo, away_elo, home_score, away_score, is_playoff, home_advantage):
    """Return the home win probability and both teams' ratings after the game."""
    elo_diff = home_elo + home_advantage - away_elo
    if is_playoff:
        elo_diff = elo_diff * PLAYOFF_MULTIPLIER

    home_win_prob = 1 / (10 ** (-elo_diff / 400) + 1)

    if home_score > away_score:
        margin = home_score - away_score
        winner_elo_diff = elo_diff
        winner_win_prob = home_win_prob
        home_sign = 1
    else:
        margin = away_score - home_score
        winner_elo_diff = -elo_diff
        winner_win_prob = 1 - home_win_prob
        home_sign = -1

    margin_multiplier = (margin + 3) ** 0.8 / (7.5 + 0.006 * winner_elo_diff)
    shift = K * margin_multiplier * (1 - winner_win_prob)

    return home_win_prob, home_elo + home_sign * shift, away_elo - home_sign * shift


def model(dbt, session):
    dbt.config(materialized="table")

    team_map = dbt.ref("team_map").collect()
    key_from_538 = {r["FIVETHIRTYEIGHT_ABBR"]: r["TEAM_KEY"] for r in team_map
                    if r["FIVETHIRTYEIGHT_ABBR"] is not None}
    key_from_espn = {int(r["ESPN_TEAM_ID"]): r["TEAM_KEY"] for r in team_map}

    # --- Games, oldest first, in one common shape ---------------------------
    games_538 = (dbt.ref("stg_fivethirtyeight__elo")
                 .sort("GAME_DATE", "HOME_TEAM_ABBR").collect())

    end_of_2021 = {}
    games = []
    for g in games_538:
        home = key_from_538[g["HOME_TEAM_ABBR"]]
        away = key_from_538[g["AWAY_TEAM_ABBR"]]
        if g["SEASON"] == 2021:
            end_of_2021[home] = g["HOME_ELO_POST"]
            end_of_2021[away] = g["AWAY_ELO_POST"]
        elif g["SEASON"] == 2022:
            games.append({
                "game_id": None, "season": 2022, "game_date": g["GAME_DATE"],
                "is_playoff": g["IS_PLAYOFF"], "is_neutral_site": False,
                "home": home, "away": away,
                "home_score": g["HOME_TEAM_SCORE"], "away_score": g["AWAY_TEAM_SCORE"],
            })

    schedule = (dbt.ref("stg_wehoop__schedule")
                .filter("SEASON >= 2023")
                .sort("GAME_DATE", "START_TIME_ET", "GAME_ID").collect())
    for g in schedule:
        games.append({
            "game_id": int(g["GAME_ID"]), "season": g["SEASON"], "game_date": g["GAME_DATE"],
            "is_playoff": g["IS_PLAYOFF"],
            "is_neutral_site": int(g["GAME_ID"]) in NEUTRAL_SITE_GAME_IDS,
            "home": key_from_espn[int(g["HOME_TEAM_ID"])],
            "away": key_from_espn[int(g["AWAY_TEAM_ID"])],
            "home_score": g["HOME_SCORE"], "away_score": g["AWAY_SCORE"],
        })

    # --- Play every game in order --------------------------------------------
    ratings = dict(end_of_2021)
    current_season = 2021
    rows = []
    for g in games:
        # New season: every existing team keeps half, moves half toward 1500
        if g["season"] != current_season:
            ratings = {team: CARRYOVER * elo + (1 - CARRYOVER) * LEAGUE_AVERAGE
                       for team, elo in ratings.items()}
            current_season = g["season"]

        home, away = g["home"], g["away"]
        # A team's first game ever (Golden State, 2025) starts at 1300
        for team in (home, away):
            if team not in ratings:
                ratings[team] = NEW_TEAM_RATING

        home_pre, away_pre = ratings[home], ratings[away]
        home_advantage = 0 if g["is_neutral_site"] else HOME_ADVANTAGE

        home_win_prob, home_post, away_post = play_game(
            home_pre, away_pre, g["home_score"], g["away_score"],
            g["is_playoff"], home_advantage,
        )
        ratings[home], ratings[away] = home_post, away_post

        rows.append([
            g["game_id"], g["season"], g["game_date"], g["is_playoff"], g["is_neutral_site"],
            home, away, home_pre, away_pre, home_post, away_post, home_win_prob,
        ])

    schema = StructType([
        StructField("game_id", LongType()),
        StructField("season", LongType()),
        StructField("game_date", DateType()),
        StructField("is_playoff", BooleanType()),
        StructField("is_neutral_site", BooleanType()),
        StructField("home_team", StringType()),
        StructField("away_team", StringType()),
        StructField("home_elo_pre", DoubleType()),
        StructField("away_elo_pre", DoubleType()),
        StructField("home_elo_post", DoubleType()),
        StructField("away_elo_post", DoubleType()),
        StructField("home_win_prob", DoubleType()),
    ])
    return session.create_dataframe(rows, schema=schema)