import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football/data/api_client.dart';
import 'package:football/data/local_cache.dart';
import 'package:football/data/seed_data_source.dart';
import 'package:football/data/world_cup_repository.dart';
import 'package:football/models/match.dart';
import 'package:football/models/standing.dart';
import 'package:football/models/team.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super('fake-key');

  int fetchCount = 0;
  Exception? error;
  List<WcMatch> matches = [
    WcMatch(
      id: 1,
      utcDate: DateTime.utc(2026, 6, 11, 19),
      status: MatchStatus.finished,
      stage: Stage.groupStage,
      group: 'GROUP_A',
      homeTeam: const TeamRef(id: 1, name: 'Mexico', tla: 'MEX'),
      awayTeam: const TeamRef(id: 2, name: 'South Africa', tla: 'RSA'),
    ),
  ];

  @override
  Future<List<WcMatch>> fetchMatches() async {
    fetchCount++;
    if (error != null) throw error!;
    return matches;
  }

  @override
  Future<List<GroupStanding>> fetchStandings() async =>
      [const GroupStanding(group: 'GROUP_A', table: [])];

  @override
  Future<List<TeamRef>> fetchTeams() async =>
      [const TeamRef(id: 1, name: 'Mexico', tla: 'MEX')];
}

void main() {
  late Directory tempDir;
  late FakeApiClient api;
  late SeedDataSource seed;
  DateTime now = DateTime.utc(2026, 6, 11, 12);

  WorldCupRepository makeRepo({bool withApi = true}) => WorldCupRepository(
        api: withApi ? api : null,
        cache: LocalCache(tempDir),
        seed: seed,
        now: () => now,
      );

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('wc_cache_test');
    api = FakeApiClient();
    // The real bundled seed, loaded from disk instead of the asset bundle.
    seed = SeedDataSource(
        loadAsset: (key) => File(key).readAsString());
    now = DateTime.utc(2026, 6, 11, 12);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('loadLocal falls back to the bundled seed when no cache exists',
      () async {
    final repo = makeRepo();
    final data = await repo.loadLocal();
    expect(data.source, DataSource.seed);
    expect(data.matches, hasLength(104));
    expect(data.fetchedAt, isNull);
  });

  test('refresh is a no-op without an API key', () async {
    final repo = makeRepo(withApi: false);
    final data = await repo.loadLocal();
    expect(await repo.refresh(data, force: true), isNull);
  });

  test('refresh fetches, returns live data and writes the cache', () async {
    final repo = makeRepo();
    final fresh = await repo.refresh(await repo.loadLocal());
    expect(fresh, isNotNull);
    expect(fresh!.source, DataSource.live);
    expect(fresh.matches.single.homeTeam.name, 'Mexico');

    // A new repository instance now serves the cache, not the seed.
    final repo2 = makeRepo();
    final data = await repo2.loadLocal();
    expect(data.source, DataSource.cache);
    expect(data.matches, hasLength(1));
    expect(data.fetchedAt, now);
  });

  test('null venues from the API are backfilled from current data', () async {
    final repo = makeRepo();
    final seedData = await repo.loadLocal();
    final opener = seedData.matches.first;
    expect(opener.venue, isNotNull);

    // The live API serves venue: null for the same match id.
    api.matches = [
      WcMatch(
        id: opener.id,
        utcDate: opener.utcDate,
        status: MatchStatus.inPlay,
        stage: opener.stage,
        group: opener.group,
      ),
    ];
    final fresh = (await repo.refresh(seedData))!;
    expect(fresh.matches.single.venue, opener.venue);
  });

  test('fresh data is not refetched until the TTL expires', () async {
    final repo = makeRepo();
    final fresh = (await repo.refresh(await repo.loadLocal()))!;

    now = now.add(const Duration(minutes: 5));
    expect(await repo.refresh(fresh), isNull,
        reason: 'within the 30-minute idle TTL');

    now = now.add(const Duration(minutes: 31));
    expect(await repo.refresh(fresh), isNotNull,
        reason: 'TTL expired, must refetch');
  });

  test('a live match shortens the TTL to 90 seconds', () async {
    api.matches = [
      WcMatch(
        id: 1,
        utcDate: now,
        status: MatchStatus.inPlay,
        stage: Stage.groupStage,
      ),
    ];
    final repo = makeRepo();
    final fresh = (await repo.refresh(await repo.loadLocal()))!;
    expect(fresh.hasLiveMatch, isTrue);

    now = now.add(const Duration(seconds: 91));
    expect(await repo.refresh(fresh), isNotNull,
        reason: '90-second live TTL expired');
  });

  test('repeated calls are debounced even when forced', () async {
    final repo = makeRepo();
    final local = await repo.loadLocal();
    await repo.refresh(local, force: true);
    expect(api.fetchCount, 1);

    now = now.add(const Duration(seconds: 5));
    await repo.refresh(local, force: true);
    expect(api.fetchCount, 1, reason: 'second call inside 20 s debounce');

    now = now.add(const Duration(seconds: 21));
    await repo.refresh(local, force: true);
    expect(api.fetchCount, 2);
  });

  test('HTTP 429 triggers a backoff and the current data is kept', () async {
    api.error = ApiException(429, 'rate limited');
    final repo = makeRepo();
    final local = await repo.loadLocal();
    expect(await repo.refresh(local, force: true), isNull);

    api.error = null;
    now = now.add(const Duration(minutes: 1));
    expect(await repo.refresh(local, force: true), isNull,
        reason: 'still backing off after 429');

    now = now.add(const Duration(minutes: 2));
    expect(await repo.refresh(local, force: true), isNotNull,
        reason: 'backoff expired');
  });

  test('network errors are swallowed and current data is kept', () async {
    api.error = const SocketException('offline');
    final repo = makeRepo();
    expect(await repo.refresh(await repo.loadLocal(), force: true), isNull);
  });
}
