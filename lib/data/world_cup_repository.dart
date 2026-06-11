import '../models/match.dart';
import '../models/standing.dart';
import '../models/team.dart';
import 'api_client.dart';
import 'local_cache.dart';
import 'seed_data_source.dart';

enum DataSource { seed, cache, live }

class WorldCupData {
  const WorldCupData({
    required this.matches,
    required this.standings,
    required this.teams,
    required this.source,
    this.fetchedAt,
  });

  final List<WcMatch> matches;
  final List<GroupStanding> standings;
  final List<TeamRef> teams;
  final DataSource source;

  /// When the data was last fetched from the network (null for seed data).
  final DateTime? fetchedAt;

  bool get hasLiveMatch => matches.any((m) => m.isLive);
}

/// Single source of truth. Offline-first: serves cache (else bundled seed)
/// immediately, and refreshes from the network within the free-tier rate
/// limit (10 requests/minute; a full refresh costs 3).
class WorldCupRepository {
  WorldCupRepository({
    this.api,
    required this.cache,
    required this.seed,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ApiClient? api; // null when no API key was provided
  final LocalCache cache;
  final SeedDataSource seed;
  final DateTime Function() _now;

  static const liveTtl = Duration(seconds: 90);
  static const idleTtl = Duration(minutes: 30);
  static const debounce = Duration(seconds: 20);
  static const rateLimitBackoff = Duration(minutes: 2);

  DateTime? _lastAttempt;
  DateTime? _backoffUntil;

  bool get hasApiKey => api != null;

  /// Cache if present, else bundled seed. Never touches the network.
  Future<WorldCupData> loadLocal() async {
    final cached = await cache.read();
    if (cached != null) {
      var matches = cached.matches;
      // Caches written before venue backfill existed hold venue-less API
      // data; heal them from the bundled seed (same match ids).
      if (matches.any((m) => m.venue == null)) {
        final seeded = await seed.load();
        final venueById = {
          for (final m in seeded.matches)
            if (m.venue != null) m.id: m.venue!,
        };
        matches = [
          for (final m in matches)
            m.venue == null && venueById.containsKey(m.id)
                ? m.withVenue(venueById[m.id]!)
                : m,
        ];
      }
      return WorldCupData(
        matches: matches,
        standings: cached.standings,
        teams: cached.teams,
        source: DataSource.cache,
        fetchedAt: cached.fetchedAt,
      );
    }
    final seeded = await seed.load();
    return WorldCupData(
      matches: seeded.matches,
      standings: seeded.standings,
      teams: seeded.teams,
      source: DataSource.seed,
    );
  }

  /// Short TTL while a match is live or kicks off within ±3 hours;
  /// long TTL otherwise.
  Duration ttlFor(WorldCupData data) {
    final now = _now().toUtc();
    final nearKickoff = data.matches.any((m) =>
        m.isLive ||
        (m.isUpcoming && m.utcDate.difference(now).abs() <= const Duration(hours: 3)));
    return nearKickoff ? liveTtl : idleTtl;
  }

  bool isStale(WorldCupData data) {
    final fetchedAt = data.fetchedAt;
    if (fetchedAt == null) return true; // seed data is always refreshable
    return _now().toUtc().difference(fetchedAt.toUtc()) > ttlFor(data);
  }

  /// Fetches fresh data if allowed. Returns null when nothing was fetched
  /// (no key, fresh enough, debounced, backing off, or network error —
  /// callers keep serving [current]).
  Future<WorldCupData?> refresh(WorldCupData current,
      {bool force = false}) async {
    final client = api;
    if (client == null) return null;
    final now = _now().toUtc();
    if (!force && !isStale(current)) return null;
    final backoffUntil = _backoffUntil;
    if (backoffUntil != null && now.isBefore(backoffUntil)) return null;
    final lastAttempt = _lastAttempt;
    if (lastAttempt != null && now.difference(lastAttempt) < debounce) {
      return null;
    }
    _lastAttempt = now;

    try {
      var matches = await client.fetchMatches();
      // The live API serves venue: null for WC 2026; keep the stadium names
      // we already have (the bundled seed shares the API's match ids).
      final venueById = {
        for (final m in current.matches)
          if (m.venue != null) m.id: m.venue!,
      };
      matches = [
        for (final m in matches)
          m.venue == null && venueById.containsKey(m.id)
              ? m.withVenue(venueById[m.id]!)
              : m,
      ];
      final standings = await client.fetchStandings();
      // Teams change never during the tournament; reuse them once we have any.
      final teams =
          current.teams.isNotEmpty ? current.teams : await client.fetchTeams();
      final data = WorldCupData(
        matches: matches,
        standings: standings,
        teams: teams,
        source: DataSource.live,
        fetchedAt: now,
      );
      await cache.write(CachedData(
        matches: matches,
        standings: standings,
        teams: teams,
        fetchedAt: now,
      ));
      return data;
    } on ApiException catch (e) {
      if (e.isRateLimit) _backoffUntil = now.add(rateLimitBackoff);
      return null;
    } catch (_) {
      return null; // offline etc. — keep serving current data
    }
  }
}
