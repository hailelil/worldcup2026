#!/usr/bin/env bash
# Regenerate assets/seed/wc2026_seed.json from the live football-data.org API,
# enriched with venue names and knockout labels from the fixturedownload feed.
# Requires FOOTBALL_DATA_API_KEY in the environment (free key:
# https://www.football-data.org/client/register).
# Run occasionally during the tournament so fresh installs ship with current results.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${FOOTBALL_DATA_API_KEY:?set FOOTBALL_DATA_API_KEY first}"
BASE="https://api.football-data.org/v4/competitions/WC"
H="X-Auth-Token: $FOOTBALL_DATA_API_KEY"

matches=$(curl -fsS -H "$H" "$BASE/matches")
sleep 7 # free tier: 10 requests/minute
standings=$(curl -fsS -H "$H" "$BASE/standings")
sleep 7
teams=$(curl -fsS -H "$H" "$BASE/teams")

python3 - "$matches" "$standings" "$teams" <<'EOF'
import json, sys
api = {
    "matches": json.loads(sys.argv[1])["matches"],
    "standings": json.loads(sys.argv[2])["standings"],
    "teams": json.loads(sys.argv[3])["teams"],
}
with open("tool/api_seed.json", "w") as f:
    json.dump(api, f, ensure_ascii=False, indent=1)
print(f"wrote tool/api_seed.json: {len(api['matches'])} matches")
EOF

curl -fsS "https://fixturedownload.com/feed/json/fifa-world-cup-2026" -o tool/raw_feed.json \
  || echo "feed refresh failed; reusing the committed tool/raw_feed.json"
python3 tool/transform_seed.py
