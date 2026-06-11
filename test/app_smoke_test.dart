import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football/app.dart';
import 'package:football/data/local_cache.dart';
import 'package:football/data/seed_data_source.dart';
import 'package:football/data/world_cup_repository.dart';
import 'package:football/state/providers.dart';
import 'package:football/widgets/match_card.dart';
import 'package:football/widgets/team_crest.dart';

/// In-memory cache so the widget test never touches real file IO
/// (real async IO does not complete inside the fake-async test zone).
class MemoryCache extends LocalCache {
  MemoryCache() : super(Directory.systemTemp);

  CachedData? data;

  @override
  Future<CachedData?> read() async => data;

  @override
  Future<void> write(CachedData d) async => data = d;
}

void main() {
  // Read assets synchronously up front; serve them without real IO below.
  final preloaded = {
    'assets/seed/wc2026_seed.json':
        File('assets/seed/wc2026_seed.json').readAsStringSync(),
    'assets/seed/venues.json':
        File('assets/seed/venues.json').readAsStringSync(),
  };

  testWidgets('all five tabs and the match detail screen render',
      (tester) async {
    TeamCrest.networkImagesEnabled = false;
    addTearDown(() => TeamCrest.networkImagesEnabled = true);
    final seed = SeedDataSource(loadAsset: (key) async => preloaded[key]!);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seedDataSourceProvider.overrideWithValue(seed),
          repositoryProvider.overrideWith(
            (ref) async => WorldCupRepository(
              api: null, // offline path: seed only
              cache: MemoryCache(),
              seed: seed,
            ),
          ),
        ],
        child: const WorldCupApp(),
      ),
    );
    // Let the async providers resolve.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Today tab: opening match and the no-key banner.
    expect(find.text('World Cup 2026'), findsOneWidget);
    expect(find.textContaining('Configure a data source'), findsOneWidget);
    expect(find.text('Mexico'), findsWidgets);

    // Matches tab: full schedule with filters.
    await tester.tap(find.text('Matches'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.byType(MatchCard), findsWidgets);

    // Groups tab: 12 zeroed tables, A first.
    await tester.tap(find.text('Groups'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Group A'), findsOneWidget);

    // Bracket tab: rounds with TBD placeholders.
    await tester.tap(find.text('Bracket'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Round of 32'), findsOneWidget);
    // The first R32 card is "Group A runners-up vs Group B runners-up".
    expect(find.textContaining('runners-up'), findsWidgets);

    // More tab: venues grouped by country.
    await tester.tap(find.text('More'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(find.text('Estadio Azteca'), 200);
    expect(find.text('Estadio Azteca'), findsOneWidget);

    // Match detail: open the first card on the Matches tab.
    await tester.tap(find.text('Matches'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byType(MatchCard).first);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Kick-off'), findsOneWidget);
    expect(find.text('Venue'), findsOneWidget);
  });
}
