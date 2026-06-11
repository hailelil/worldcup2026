import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/match.dart';
import '../state/providers.dart';
import '../widgets/match_card.dart';

/// Knockout rounds as a scrollable list of sections, Round of 32 -> Final.
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
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 2),
                  child: Text(round.label,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Builder(builder: (context) {
                  final roundMatches = data.matches
                      .where((m) => m.stage == round)
                      .toList()
                    ..sort((a, b) => a.utcDate.compareTo(b.utcDate));
                  final allTbd = roundMatches.isNotEmpty &&
                      roundMatches.every((m) => m.homeTeam.isPlaceholder);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (allTbd)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                          child: Text(
                            'Starts ${DateFormat.MMMd().format(roundMatches.first.localKickoff)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        )
                      else
                        const SizedBox(height: 6),
                      for (final m in roundMatches)
                        MatchCard(match: m, showStageLabel: false),
                    ],
                  );
                }),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
