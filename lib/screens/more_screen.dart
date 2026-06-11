import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/venue.dart';
import '../state/providers.dart';

/// Stadiums grouped by host country, plus tournament facts and attribution.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  static const _countryFlags = {
    'Canada': '🇨🇦',
    'Mexico': '🇲🇽',
    'United States': '🇺🇸',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(venuesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tournament info')),
      body: venuesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load venues\n$e')),
        data: (venues) {
          final byCountry = <String, List<Venue>>{};
          for (final v in venues) {
            byCountry.putIfAbsent(v.country, () => []).add(v);
          }
          return ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FIFA World Cup 2026',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        'June 11 – July 19, 2026 · Canada, Mexico and the '
                        'United States\n48 teams · 12 groups · 104 matches · '
                        '16 stadiums',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              for (final country in byCountry.keys) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
                  child: Text(
                    '${_countryFlags[country] ?? ''} $country',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                for (final v in byCountry[country]!)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.stadium_outlined),
                      title: Text(v.name),
                      subtitle: Text(
                          '${v.city} · ${NumberFormat.decimalPattern().format(v.capacity)} seats'),
                    ),
                  ),
              ],
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Football data provided by football-data.org.\n'
                  'Flags by flagcdn.com. Stadium capacities are approximate.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
