import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football/data/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _matchesBody = '''
{"matches": [{
  "id": 1, "utcDate": "2026-06-11T19:00:00Z", "status": "TIMED",
  "stage": "GROUP_STAGE", "group": "GROUP_A",
  "homeTeam": {"id": 1, "name": "Mexico", "tla": "MEX"},
  "awayTeam": {"id": 2, "name": "South Africa", "tla": "RSA"},
  "score": null
}]}
''';

void main() {
  test('footballData mode hits the v4 API with the auth header', () async {
    late http.Request seen;
    final client = ApiClient.footballData(
      'secret-key',
      client: MockClient((request) async {
        seen = request;
        return http.Response(_matchesBody, 200);
      }),
    );

    final matches = await client.fetchMatches();
    expect(matches.single.homeTeam.name, 'Mexico');
    expect(seen.url.toString(),
        'https://api.football-data.org/v4/competitions/WC/matches');
    expect(seen.headers['X-Auth-Token'], 'secret-key');
  });

  test('snapshot mode hits <baseUrl>/<name>.json with no auth header',
      () async {
    late http.Request seen;
    final client = ApiClient.snapshot(
      'https://raw.githubusercontent.com/user/repo/data/', // trailing slash ok
      client: MockClient((request) async {
        seen = request;
        return http.Response(_matchesBody, 200);
      }),
    );

    final matches = await client.fetchMatches();
    expect(matches.single.id, 1);
    expect(seen.url.toString(),
        'https://raw.githubusercontent.com/user/repo/data/matches.json');
    expect(seen.headers.containsKey('X-Auth-Token'), isFalse);
  });

  test('non-200 responses raise ApiException with the status code', () async {
    final client = ApiClient.snapshot(
      'https://example.com/data',
      client: MockClient(
          (request) async => http.Response('rate limited', 429)),
    );
    await expectLater(
      client.fetchMatches(),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 429)
          .having((e) => e.isRateLimit, 'isRateLimit', isTrue)),
    );
  });

  test('parses UTF-8 bodies correctly', () async {
    final body = json.encode({
      'matches': [
        {
          'id': 2,
          'utcDate': '2026-06-25T20:00:00Z',
          'status': 'TIMED',
          'stage': 'GROUP_STAGE',
          'group': 'GROUP_E',
          'homeTeam': {'id': 3, 'name': 'Curaçao', 'tla': 'CUR'},
          'awayTeam': {'id': 4, 'name': "Côte d'Ivoire", 'tla': 'CIV'},
          'score': null,
        }
      ]
    });
    final client = ApiClient.snapshot(
      'https://example.com/data',
      client: MockClient((request) async => http.Response.bytes(
          utf8.encode(body), 200,
          headers: {'content-type': 'application/json'})),
    );
    final matches = await client.fetchMatches();
    expect(matches.single.homeTeam.name, 'Curaçao');
    expect(matches.single.awayTeam.name, "Côte d'Ivoire");
  });
}
