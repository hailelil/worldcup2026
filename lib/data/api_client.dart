import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/match.dart';
import '../models/standing.dart';
import '../models/team.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  bool get isRateLimit => statusCode == 429;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin client for the football-data.org v4 World Cup endpoints.
/// Methods are overridable so tests can substitute a fake.
///
/// Two modes:
/// - [ApiClient.footballData]: football-data.org v4 directly, authenticated
///   with a personal key (10 requests/minute free tier).
/// - [ApiClient.snapshot]: a public, unauthenticated JSON mirror refreshed by
///   the GitHub Actions workflow (.github/workflows/refresh-data.yml). Same
///   response shapes — no key in the app, no per-user API quota.
class ApiClient {
  ApiClient.footballData(String apiKey, {http.Client? client})
      : _base = 'https://api.football-data.org/v4/competitions/WC',
        _suffix = '',
        _headers = {'X-Auth-Token': apiKey},
        _client = client ?? http.Client();

  /// [baseUrl] is the directory holding matches.json, standings.json and
  /// teams.json, e.g. https://raw.githubusercontent.com/USER/REPO/data
  ApiClient.snapshot(String baseUrl, {http.Client? client})
      : _base = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _suffix = '.json',
        _headers = const {},
        _client = client ?? http.Client();

  final String _base;
  final String _suffix;
  final Map<String, String> _headers;
  final http.Client _client;

  Future<Map<String, dynamic>> _getJson(String name) async {
    final response = await _client
        .get(Uri.parse('$_base/$name$_suffix'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return json.decode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;
  }

  Future<List<WcMatch>> fetchMatches() async {
    final body = await _getJson('matches');
    return (body['matches'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(WcMatch.fromJson)
        .toList();
  }

  Future<List<GroupStanding>> fetchStandings() async {
    final body = await _getJson('standings');
    return GroupStanding.listFromJson(body['standings'] as List<dynamic>);
  }

  Future<List<TeamRef>> fetchTeams() async {
    final body = await _getJson('teams');
    return (body['teams'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(TeamRef.fromJson)
        .toList();
  }
}
