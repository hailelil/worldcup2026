# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Flutter app for following the FIFA World Cup 2026 (June 11 – July 19, 2026): kickoff times in the user's local timezone, live scores and results, group standings, knockout bracket, and venue info. iOS is the primary verified platform; the code is cross-platform.

## Commands

```sh
flutter run --dart-define=WC_DATA_URL=<url>              # run against the GitHub snapshot mirror (preferred)
flutter run --dart-define=FOOTBALL_DATA_API_KEY=<key>    # run against football-data.org directly (dev)
flutter run                                              # run offline (bundled schedule only)
flutter analyze                                          # must stay at zero issues
flutter test                                             # all unit tests
flutter test test/repository_test.dart                   # one test file
flutter test --plain-name 'parses a finished group match'  # one test by name
```

Two live-data modes, both read via `String.fromEnvironment` in `lib/state/providers.dart`:

- **Snapshot mirror (for released builds):** `.github/workflows/refresh-data.yml` runs every ~5 min, fetches football-data.org with the repo secret `FOOTBALL_DATA_API_KEY`, and force-pushes `matches.json`/`standings.json`/`teams.json` to a single-commit orphan `data` branch. The app reads it from `https://raw.githubusercontent.com/<user>/<repo>/data` — no key ships in the app and all users share one API quota. Once the GitHub repo exists, bake this URL in as the `defaultValue` of `dataUrl` in providers.dart.
- **Direct API (dev only):** a personal key from https://www.football-data.org/client/register. Never hardcode it.

Without either, the app still works fully from bundled seed data and shows a banner.

## Architecture

Offline-first repository pattern. UI reads one Riverpod 3 `AsyncNotifierProvider` (`worldCupDataProvider` in `lib/state/providers.dart`), which delegates to `WorldCupRepository` (`lib/data/world_cup_repository.dart`):

- `ApiClient` — football-data.org v4, endpoints `/competitions/WC/{matches,standings,teams}`, header `X-Auth-Token`. Null when no key.
- `LocalCache` — one `wc_cache.json` in the app documents dir, atomic writes, `fetchedAt` timestamp.
- `SeedDataSource` — bundled `assets/seed/wc2026_seed.json` (full 104-match schedule) + `venues.json` (16 stadiums, hand-authored).

Load order: cache → seed served instantly, then a background network refresh if stale. **Rate limit is 10 requests/minute on the free tier; a full refresh costs 3 requests.** The repository enforces this with TTLs (90 s when a match is live or kicks off within ±3 h, else 30 min), a 20 s debounce that applies even to forced refreshes, and a 2 min backoff on HTTP 429. Don't add refresh triggers that bypass the repository.

Models (`lib/models/`) mirror the v4 API JSON exactly, and the seed/cache files use the same shape, so one `fromJson` path parses everything. Everything is null-tolerant because knockout matches have TBD team slots (null id/name) until earlier rounds resolve. The match class is `WcMatch` (not `Match`, which would collide with Flutter's `Match`).

UI: `lib/app.dart` is a 5-tab `NavigationBar` shell (Today / Matches / Groups / Bracket / More) over an `IndexedStack`; `MatchDetailScreen` is the only pushed route. All kickoff times display via `utcDate.toLocal()` + `intl` — never render UTC. Team crests are flagcdn PNG flags; `TeamCrest` also handles SVG URLs and falls back to a TLA monogram for TBD slots (the live API serves SVG crests).

## Tests

`test/fixtures/` holds hand-written API-shaped JSON (finished, live, and TBD-knockout matches). `repository_test.dart` uses a `FakeApiClient` subclass and an injected `now()` clock — no mocking library. Tests read `assets/seed/wc2026_seed.json` straight from disk, which also validates the real seed file on every test run.

## Seed data

`assets/seed/wc2026_seed.json` ships the schedule so the app works with no key/network. Regenerate it occasionally during the tournament so fresh installs include recent results:

- With an API key: `FOOTBALL_DATA_API_KEY=<key> tool/fetch_seed.sh`
- Without: `curl -s https://fixturedownload.com/feed/json/fifa-world-cup-2026 -o tool/raw_feed.json && python3 tool/transform_seed.py` (converts the feed to the v4 API shape; also regenerates `venues.json`)
