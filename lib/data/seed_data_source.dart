import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/match.dart';
import '../models/standing.dart';
import '../models/team.dart';
import '../models/venue.dart';

typedef AssetLoader = Future<String> Function(String key);

/// Read-only bundled data: the full 104-match schedule plus venues, so the
/// app is useful with no network and no API key.
class SeedDataSource {
  SeedDataSource({AssetLoader? loadAsset})
      : _loadAsset = loadAsset ?? rootBundle.loadString;

  final AssetLoader _loadAsset;

  Future<({List<WcMatch> matches, List<GroupStanding> standings, List<TeamRef> teams})>
      load() async {
    final raw = json.decode(await _loadAsset('assets/seed/wc2026_seed.json'))
        as Map<String, dynamic>;
    return (
      matches: (raw['matches'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(WcMatch.fromJson)
          .toList(),
      standings: GroupStanding.listFromJson(raw['standings'] as List<dynamic>),
      teams: (raw['teams'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(TeamRef.fromJson)
          .toList(),
    );
  }

  Future<List<Venue>> loadVenues() async {
    final raw = json.decode(await _loadAsset('assets/seed/venues.json'))
        as List<dynamic>;
    return raw.cast<Map<String, dynamic>>().map(Venue.fromJson).toList();
  }
}
