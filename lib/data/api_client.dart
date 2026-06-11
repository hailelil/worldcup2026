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
class ApiClient {
  ApiClient(this.apiKey, {http.Client? client})
      : _client = client ?? http.Client();

  static const _base = 'https://api.football-data.org/v4/competitions/WC';

  final String apiKey;
  final http.Client _client;

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _client
        .get(Uri.parse('$_base$path'), headers: {'X-Auth-Token': apiKey})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return json.decode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;
  }

  Future<List<WcMatch>> fetchMatches() async {
    final body = await _getJson('/matches');
    return (body['matches'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(WcMatch.fromJson)
        .toList();
  }

  Future<List<GroupStanding>> fetchStandings() async {
    final body = await _getJson('/standings');
    return GroupStanding.listFromJson(body['standings'] as List<dynamic>);
  }

  Future<List<TeamRef>> fetchTeams() async {
    final body = await _getJson('/teams');
    return (body['teams'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(TeamRef.fromJson)
        .toList();
  }
}
