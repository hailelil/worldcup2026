import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/api_client.dart';
import '../data/local_cache.dart';
import '../data/seed_data_source.dart';
import '../data/world_cup_repository.dart';
import '../models/venue.dart';

/// Free key: https://www.football-data.org/client/register
/// Pass with: flutter run --dart-define=FOOTBALL_DATA_API_KEY=yourkey
const apiKey = String.fromEnvironment('FOOTBALL_DATA_API_KEY');

final seedDataSourceProvider = Provider((ref) => SeedDataSource());

final repositoryProvider = FutureProvider<WorldCupRepository>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return WorldCupRepository(
    api: apiKey.isEmpty ? null : ApiClient(apiKey),
    cache: LocalCache(dir),
    seed: ref.watch(seedDataSourceProvider),
  );
});

final venuesProvider = FutureProvider<List<Venue>>(
    (ref) => ref.watch(seedDataSourceProvider).loadVenues());

/// Whether live refresh is possible (an API key was provided at build time).
final hasApiKeyProvider = Provider((ref) => apiKey.isNotEmpty);

class WorldCupDataNotifier extends AsyncNotifier<WorldCupData> {
  @override
  Future<WorldCupData> build() async {
    final repo = await ref.watch(repositoryProvider.future);
    final local = await repo.loadLocal();
    // Serve local data instantly; fetch fresh data in the background.
    Future(() => _backgroundRefresh(repo, local));
    return local;
  }

  Future<void> _backgroundRefresh(
      WorldCupRepository repo, WorldCupData current) async {
    final fresh = await repo.refresh(state.value ?? current);
    if (fresh != null) state = AsyncData(fresh);
  }

  /// Pull-to-refresh, app resume, and the live-poll timer all land here;
  /// the repository's TTL/debounce decides whether the network is hit.
  Future<void> refresh({bool force = false}) async {
    final repo = await ref.read(repositoryProvider.future);
    final current = state.value ?? await repo.loadLocal();
    final fresh = await repo.refresh(current, force: force);
    if (fresh != null) state = AsyncData(fresh);
  }
}

final worldCupDataProvider =
    AsyncNotifierProvider<WorldCupDataNotifier, WorldCupData>(
        WorldCupDataNotifier.new);
