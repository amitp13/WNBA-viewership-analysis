# WNBA Viewership Drivers

An analytics engineering and research project that models national WNBA telecast data in dbt and Snowflake to measure what actually brings viewers to a game. Is it the star players such A'ja Wilson & Caitlin Clark or is it the matchup quality? Does the broadcast placement matter? or does current competitative landscape of televised sports a major factor?

**Status:** In progress. Section 1 is complete; later sections will be added as the build moves forward.

---

## 1. Introduction

### Background

The WNBA's television audience has grown sharply over the last two seasons, and much of the public conversation credits a single player. The 2025 season opener between the Indiana Fever and Chicago Sky drew 2.7 million viewers on ABC making it the most watched WNBA game since Caitlin Clark and Angel Reese entered the league. When the same two teams met in July without either star, the game drew 1.5 million ([Front Office Sports](https://frontofficesports.com/?p=195040)). The growth was not only about one team, though. By mid 2025, games without the Fever were averaging 549,000 viewers which was a 37% jump from 2024 ([Just Women's Sports](https://justwomenssports.com/?p=28233)). ESPN saw the same lift across its schedule, finishing 2025 with its most watched WNBA season ever at 1.2 million viewers per game ([ESPN Press Room](https://espnpressroom.com/us/press-releases/2025/10/espns-monumental-wnba-season-sets-new-viewership-records/)). In 2026, the league began new 11 year media rights deals worth about $2.2 billion, adding NBC Sports alongside ESPN as a broadcast partner ([Just Women's Sports](https://justwomenssports.com/?p=28233)). Networks, advertisers and the league itself now need a clear answer to a simple question.

**Is this audience built on one star, one team, or something more durable?**

### Problem Statement

Viewership for a WNBA game is shaped by many factors at once. A game featuring a star is also more likely to be a strong matchup, to air on a bigger network, and to land in a better time slot. Headline numbers mix these effects together, so it is hard to say how much of an audience comes from the player, the game, or the broadcast decision. There is also no single public dataset that ties game level viewership to the game, player and schedule context needed to separate them.

### Research Questions

The primary question is: **what explains differences in viewership across nationally televised WNBA games?** It is broken into four parts.

1. **Star Power.** How much does a star player's availability change viewership, holding the matchup constant?
2. **Matchup quality.** Do games between stronger teams, measured by Elo rating, draw larger audiences regardless of who plays?
3. **Broadcast context.** How much do network, day and time slot, and direct competition from NFL games affect viewership?
4. **Durable growth.** After accounting for stars, matchups and broadcast context, has baseline viewership grown from 2024 to 2025?

### Scope

The project covers nationally televised WNBA regular season and playoff games from the 2024 and 2025 seasons in the United States. Local and streaming only broadcasts are excluded because their audiences are not reported consistently. The unit of analysis is a single national telecast. A methodological note shapes the scope: in 2025 Nielsen moved to a Big Data plus Panel measurement model, which raised reported audiences across all sports ([Front Office Sports](https://frontofficesports.com/article/wnba-finals-draws-1-5m-viewer-second-highest-series-on-espn/)). Year over year comparisons in this project account for that change rather than treating it as real growth.

### Audiences
**For the league,** the results inform which games to push for national windows and how to grow audiences that do not depend on a single player's health.
**For networks and advertisers,** they show which game characteristics justify premium placement and pricing under the new media agreements.
**For data teams,** the project demonstrates how scattered third party media data can be standardized into a tested, documented data model with one governed definition for each viewership metric, which is the foundation any reporting or AI tool on top of it depends on.

---

## 2. Literature Review

*Coming next.*

## 3. Methodology

*Coming soon.*

## 4. Results

*Coming soon.*

## 5. Discussion and Conclusion

*Coming soon.*

## 6. Deliverable

*Coming soon.*

---

## About

Built by Amit Phadke. [LinkedIn](https://www.linkedin.com/in/amit-phadke12/)
