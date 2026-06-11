import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/world_cup_repository.dart';
import '../state/providers.dart';

/// Discreet banner explaining data freshness: shown when running without an
/// API key (seed schedule only) or when serving cached data.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(worldCupDataProvider).value;
    final hasKey = ref.watch(hasApiKeyProvider);
    if (data == null) return const SizedBox.shrink();

    String? message;
    final fetchedAt = data.fetchedAt;
    if (!hasKey) {
      message = 'Showing the official schedule. '
          'Add a football-data.org API key for live scores.';
    } else if (data.source != DataSource.live &&
        fetchedAt != null &&
        DateTime.now().toUtc().difference(fetchedAt.toUtc()) >
            const Duration(hours: 1)) {
      // Recent cache is normal operation (TTL not yet expired) — only flag
      // genuinely stale data.
      message =
          'Offline — last updated ${DateFormat.MMMd().add_jm().format(fetchedAt.toLocal())}';
    }
    if (message == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: scheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
