# Elo ratings for every game, using FiveThirtyEight's WNBA method.
# Method and sources: docs/decisions.md, "Elo method" and "Where Elo runs".
# Step 7.4: 2022 only, seeded from FiveThirtyEight's end-of-2021 ratings,
# so the output can be checked against their published 2022 ratings.

K = 28                    # how far one game moves a rating
HOME_ADVANTAGE = 80       # Elo points added to the home team
PLAYOFF_MULTIPLIER = 1.25 # playoff games: rating gap counts 25% more
LEAGUE_AVERAGE = 1500
CARRYOVER = 0.5           # share of last season's rating a team keeps


def play_game(home_elo, away_elo, home_score, away_score, is_playoff):
    """Return the home win probability and both teams' ratings after the game."""
    elo_diff = home_elo + HOME_ADVANTAGE - away_elo
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

    # FiveThirtyEight code -> our team_key
    team_key = {
        row["FIVETHIRTYEIGHT_ABBR"]: row["TEAM_KEY"]
        for row in dbt.ref("team_map").collect()
        if row["FIVETHIRTYEIGHT_ABBR"] is not None
    }

    games = (
        dbt.ref("stg_fivethirtyeight__elo")
        .sort("GAME_DATE", "HOME_TEAM_ABBR")
        .collect()
    )

    # Starting point: each team's last 2021 rating from FiveThirtyEight
    end_of_2021 = {}
    for g in games:
        if g["SEASON"] == 2021:
            end_of_2021[team_key[g["HOME_TEAM_ABBR"]]] = g["HOME_ELO_POST"]
            end_of_2021[team_key[g["AWAY_TEAM_ABBR"]]] = g["AWAY_ELO_POST"]

    # Between seasons: keep half, move half toward 1500
    ratings = {
        team: CARRYOVER * elo + (1 - CARRYOVER) * LEAGUE_AVERAGE
        for team, elo in end_of_2021.items()
    }

    rows = []
    for g in games:
        if g["SEASON"] != 2022:
            continue
        home = team_key[g["HOME_TEAM_ABBR"]]
        away = team_key[g["AWAY_TEAM_ABBR"]]
        home_pre, away_pre = ratings[home], ratings[away]

        home_win_prob, home_post, away_post = play_game(
            home_pre, away_pre,
            g["HOME_TEAM_SCORE"], g["AWAY_TEAM_SCORE"],
            g["IS_PLAYOFF"],
        )
        ratings[home], ratings[away] = home_post, away_post

        rows.append([
            g["SEASON"], g["GAME_DATE"], g["IS_PLAYOFF"],
            home, away,
            home_pre, away_pre, home_post, away_post, home_win_prob,
        ])

    return session.create_dataframe(rows, schema=[
        "season", "game_date", "is_playoff",
        "home_team", "away_team",
        "home_elo_pre", "away_elo_pre", "home_elo_post", "away_elo_post",
        "home_win_prob",
    ])