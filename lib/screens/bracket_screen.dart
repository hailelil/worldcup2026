import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match.dart';
import '../state/providers.dart';
import '../widgets/match_card.dart';

/// Knockout rounds as a scrollable list of sections, Round of 32 → Final.
/// Unresolved slots show their qualification path ("Group A winners").
class BracketScreen extends ConsumerWidget {
  const BracketScreen({super.key});

  static const _rounds = [
    Stage.last32,
    Stage.last16,
    Stage.quarterFinals,
    Stage.semiFinals,
    Stage.thirdPlace,
    Stage.finalStage,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(worldCupDataProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Knockout stage')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load data\n$e')),
        data: (data) => RefreshIndicator(
          onRefresh: () =>
              ref.read(worldCupDataProvider.notifier).refresh(force: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              for (final round in _rounds) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
                  child: Text(round.label,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                for (final m in data.matches
                    .where((m) => m.stage == round)
                    .toList()
                  ..sort((a, b) => a.utcDate.compareTo(b.utcDate)))
                  MatchCard(match: m, showStageLabel: false),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
