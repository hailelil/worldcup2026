import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../widgets/group_table_card.dart';

/// The 12 group tables (A–L).
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(worldCupDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load data\n$e')),
        data: (data) => RefreshIndicator(
          onRefresh: () =>
              ref.read(worldCupDataProvider.notifier).refresh(force: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final standing in data.standings)
                GroupTableCard(standing: standing),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Top 2 from each group qualify directly. The 8 best '
                  'third-placed teams (out of 12 groups) also advance to '
                  'the Round of 32.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
