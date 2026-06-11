#!/usr/bin/env bash
# Regenerate assets/seed/wc2026_seed.json from the live football-data.org API.
# Requires FOOTBALL_DATA_API_KEY in the environment (free key: https://www.football-data.org/client/register).
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
seed = {
    "matches": json.loads(sys.argv[1])["matches"],
    "standings": json.loads(sys.argv[2])["standings"],
    "teams": json.loads(sys.argv[3])["teams"],
}
with open("assets/seed/wc2026_seed.json", "w") as f:
    json.dump(seed, f, ensure_ascii=False, indent=1)
print(f"wrote assets/seed/wc2026_seed.json: {len(seed['matches'])} matches")
EOF
