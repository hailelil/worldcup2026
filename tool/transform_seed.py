#!/usr/bin/env python3
"""Transform the fixturedownload.com WC2026 feed (tool/raw_feed.json) into
assets/seed/wc2026_seed.json shaped like football-data.org v4 responses,
so the app parses seed and live API data with the same models.

Usage: python3 tool/transform_seed.py
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

# name -> (TLA, flagcdn code, friendly short name)
TEAMS = {
    "Algeria": ("ALG", "dz", "Algeria"),
    "Argentina": ("ARG", "ar", "Argentina"),
    "Australia": ("AUS", "au", "Australia"),
    "Austria": ("AUT", "at", "Austria"),
    "Belgium": ("BEL", "be", "Belgium"),
    "Bosnia and Herzegovina": ("BIH", "ba", "Bosnia"),
    "Brazil": ("BRA", "br", "Brazil"),
    "Cabo Verde": ("CPV", "cv", "Cabo Verde"),
    "Canada": ("CAN", "ca", "Canada"),
    "Colombia": ("COL", "co", "Colombia"),
    "Congo DR": ("COD", "cd", "DR Congo"),
    "Croatia": ("CRO", "hr", "Croatia"),
    "Curaçao": ("CUW", "cw", "Curaçao"),
    "Czechia": ("CZE", "cz", "Czechia"),
    "Côte d'Ivoire": ("CIV", "ci", "Côte d'Ivoire"),
    "Ecuador": ("ECU", "ec", "Ecuador"),
    "Egypt": ("EGY", "eg", "Egypt"),
    "England": ("ENG", "gb-eng", "England"),
    "France": ("FRA", "fr", "France"),
    "Germany": ("GER", "de", "Germany"),
    "Ghana": ("GHA", "gh", "Ghana"),
    "Haiti": ("HAI", "ht", "Haiti"),
    "IR Iran": ("IRN", "ir", "Iran"),
    "Iraq": ("IRQ", "iq", "Iraq"),
    "Japan": ("JPN", "jp", "Japan"),
    "Jordan": ("JOR", "jo", "Jordan"),
    "Korea Republic": ("KOR", "kr", "South Korea"),
    "Mexico": ("MEX", "mx", "Mexico"),
    "Morocco": ("MAR", "ma", "Morocco"),
    "Netherlands": ("NED", "nl", "Netherlands"),
    "New Zealand": ("NZL", "nz", "New Zealand"),
    "Norway": ("NOR", "no", "Norway"),
    "Panama": ("PAN", "pa", "Panama"),
    "Paraguay": ("PAR", "py", "Paraguay"),
    "Portugal": ("POR", "pt", "Portugal"),
    "Qatar": ("QAT", "qa", "Qatar"),
    "Saudi Arabia": ("KSA", "sa", "Saudi Arabia"),
    "Scotland": ("SCO", "gb-sct", "Scotland"),
    "Senegal": ("SEN", "sn", "Senegal"),
    "South Africa": ("RSA", "za", "South Africa"),
    "Spain": ("ESP", "es", "Spain"),
    "Sweden": ("SWE", "se", "Sweden"),
    "Switzerland": ("SUI", "ch", "Switzerland"),
    "Tunisia": ("TUN", "tn", "Tunisia"),
    "Türkiye": ("TUR", "tr", "Türkiye"),
    "USA": ("USA", "us", "USA"),
    "Uruguay": ("URU", "uy", "Uruguay"),
    "Uzbekistan": ("UZB", "uz", "Uzbekistan"),
}

# FIFA generic venue name -> (common name, city, country)
VENUES = {
    "Mexico City Stadium": ("Estadio Azteca", "Mexico City", "Mexico"),
    "Guadalajara Stadium": ("Estadio Akron", "Guadalajara", "Mexico"),
    "Monterrey Stadium": ("Estadio BBVA", "Monterrey", "Mexico"),
    "Toronto Stadium": ("BMO Field", "Toronto", "Canada"),
    "BC Place Vancouver": ("BC Place", "Vancouver", "Canada"),
    "Atlanta Stadium": ("Mercedes-Benz Stadium", "Atlanta", "United States"),
    "Boston Stadium": ("Gillette Stadium", "Boston (Foxborough)", "United States"),
    "Dallas Stadium": ("AT&T Stadium", "Dallas (Arlington)", "United States"),
    "Houston Stadium": ("NRG Stadium", "Houston", "United States"),
    "Kansas City Stadium": ("Arrowhead Stadium", "Kansas City", "United States"),
    "Los Angeles Stadium": ("SoFi Stadium", "Los Angeles (Inglewood)", "United States"),
    "Miami Stadium": ("Hard Rock Stadium", "Miami Gardens", "United States"),
    "New York/New Jersey Stadium": ("MetLife Stadium", "New York/New Jersey", "United States"),
    "Philadelphia Stadium": ("Lincoln Financial Field", "Philadelphia", "United States"),
    "San Francisco Bay Area Stadium": ("Levi's Stadium", "San Francisco Bay Area", "United States"),
    "Seattle Stadium": ("Lumen Field", "Seattle", "United States"),
}

STAGE_BY_ROUND = {1: "GROUP_STAGE", 2: "GROUP_STAGE", 3: "GROUP_STAGE",
                  4: "LAST_32", 5: "LAST_16", 6: "QUARTER_FINALS", 7: "SEMI_FINALS"}

team_ids = {name: 1000 + i for i, name in enumerate(sorted(TEAMS))}


def team_ref(feed_name):
    if feed_name in TEAMS:
        tla, flag, short = TEAMS[feed_name]
        return {
            "id": team_ids[feed_name],
            "name": feed_name,
            "shortName": short,
            "tla": tla,
            "crest": f"https://flagcdn.com/w80/{flag}.png",
        }
    if feed_name == "To be announced":
        return {"id": None, "name": None, "shortName": None, "tla": None, "crest": None}
    # Knockout placeholders: 1A / 2B / 3ABCDF
    label = None
    if len(feed_name) == 2 and feed_name[0] in "12":
        place = "winners" if feed_name[0] == "1" else "runners-up"
        label = f"Group {feed_name[1]} {place}"
    elif feed_name.startswith("3"):
        label = "3rd " + "/".join(feed_name[1:])
    return {"id": None, "name": label, "shortName": label,
            "tla": feed_name if len(feed_name) <= 3 else "3RD", "crest": None}


def stage_for(match):
    if match["RoundNumber"] <= 7:
        return STAGE_BY_ROUND[match["RoundNumber"]]
    return "THIRD_PLACE" if match["MatchNumber"] == 103 else "FINAL"


def main():
    feed = json.load(open(os.path.join(HERE, "raw_feed.json")))
    feed.sort(key=lambda m: m["MatchNumber"])

    matches = []
    group_members = {}  # GROUP_A -> set of feed names
    for m in feed:
        group = m["Group"].replace("Group ", "GROUP_") if m["Group"] else None
        finished = m["HomeTeamScore"] is not None and m["AwayTeamScore"] is not None
        if finished:
            hs, as_ = m["HomeTeamScore"], m["AwayTeamScore"]
            winner = ("HOME_TEAM" if hs > as_ else "AWAY_TEAM" if as_ > hs else "DRAW")
        else:
            hs = as_ = winner = None
        utc = m["DateUtc"].replace(" ", "T")
        matches.append({
            "id": m["MatchNumber"],
            "utcDate": utc,
            "status": "FINISHED" if finished else "TIMED",
            "matchday": m["RoundNumber"],
            "stage": stage_for(m),
            "group": group,
            "homeTeam": team_ref(m["HomeTeam"]),
            "awayTeam": team_ref(m["AwayTeam"]),
            "score": {
                "winner": winner,
                "duration": "REGULAR",
                "fullTime": {"home": hs, "away": as_},
                "halfTime": {"home": None, "away": None},
            },
            "venue": VENUES[m["Location"]][0],
            "lastUpdated": utc,
        })
        if group and m["HomeTeam"] in TEAMS:
            group_members.setdefault(group, set()).update([m["HomeTeam"], m["AwayTeam"]])

    # Zeroed group tables in v4 standings shape (live API replaces these).
    standings = []
    for group in sorted(group_members):
        table = [{
            "position": i + 1,
            "team": team_ref(name),
            "playedGames": 0, "won": 0, "draw": 0, "lost": 0,
            "points": 0, "goalsFor": 0, "goalsAgainst": 0, "goalDifference": 0,
        } for i, name in enumerate(sorted(group_members[group]))]
        standings.append({"stage": "GROUP_STAGE", "type": "TOTAL",
                          "group": group, "table": table})

    teams = [team_ref(name) for name in sorted(TEAMS)]

    seed = {"matches": matches, "standings": standings, "teams": teams}
    out = os.path.join(ROOT, "assets", "seed", "wc2026_seed.json")
    json.dump(seed, open(out, "w"), ensure_ascii=False, indent=1)
    print(f"wrote {out}: {len(matches)} matches, {len(standings)} groups, {len(teams)} teams")

    venues = [{"fifaName": k, "name": v[0], "city": v[1], "country": v[2]}
              for k, v in VENUES.items()]
    cap = {"Estadio Azteca": 87523, "Estadio Akron": 49850, "Estadio BBVA": 53500,
           "BMO Field": 45736, "BC Place": 54500, "Mercedes-Benz Stadium": 75000,
           "Gillette Stadium": 65878, "AT&T Stadium": 92967, "NRG Stadium": 72220,
           "Arrowhead Stadium": 76416, "SoFi Stadium": 70240, "Hard Rock Stadium": 67518,
           "MetLife Stadium": 82500, "Lincoln Financial Field": 69328,
           "Levi's Stadium": 70909, "Lumen Field": 69000}
    for v in venues:
        v["capacity"] = cap[v["name"]]
    venues.sort(key=lambda v: (v["country"], v["city"]))
    out2 = os.path.join(ROOT, "assets", "seed", "venues.json")
    json.dump(venues, open(out2, "w"), ensure_ascii=False, indent=1)
    print(f"wrote {out2}: {len(venues)} venues")


if __name__ == "__main__":
    main()
