import 'dart:convert';
import 'dart:io';

import '../models/match.dart';
import '../models/standing.dart';
import '../models/team.dart';

class CachedData {
  CachedData({
    required this.matches,
    required this.standings,
    required this.teams,
    required this.fetchedAt,
  });

  final List<WcMatch> matches;
  final List<GroupStanding> standings;
  final List<TeamRef> teams;
  final DateTime fetchedAt;
}

/// Persists the last successful API fetch as a single JSON file in the app
/// documents directory. Small enough (<1 MB) that a database is overkill.
class LocalCache {
  LocalCache(this.directory);

  final Directory directory;

  File get _file => File('${directory.path}/wc_cache.json');

  Future<CachedData?> read() async {
    try {
      if (!await _file.exists()) return null;
      final raw =
          json.decode(await _file.readAsString()) as Map<String, dynamic>;
      return CachedData(
        matches: (raw['matches'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(WcMatch.fromJson)
            .toList(),
        standings:
            GroupStanding.listFromJson(raw['standings'] as List<dynamic>),
        teams: (raw['teams'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(TeamRef.fromJson)
            .toList(),
        fetchedAt: DateTime.parse(raw['fetchedAt'] as String),
      );
    } catch (_) {
      // Corrupt cache: ignore it; the seed remains as fallback.
      return null;
    }
  }

  Future<void> write(CachedData data) async {
    final payload = json.encode({
      'matches': data.matches.map((m) => m.toJson()).toList(),
      'standings': data.standings.map((s) => s.toJson()).toList(),
      'teams': data.teams.map((t) => t.toJson()).toList(),
      'fetchedAt': data.fetchedAt.toUtc().toIso8601String(),
    });
    // Atomic write: never leave a half-written cache behind.
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(payload, flush: true);
    await tmp.rename(_file.path);
  }
}
