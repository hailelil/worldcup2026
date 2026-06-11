import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/match.dart';
import '../state/providers.dart';
import '../widgets/match_card.dart';

enum _Filter { all, upcoming, results, live }

/// Full 104-match schedule grouped by (local) date, with quick filters.
class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  _Filter _filter = _Filter.all;
  Stage? _stage;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(worldCupDataProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load data\n$e')),
        data: (data) {
          final matches = data.matches.where(_matchesFilter).toList()
            ..sort((a, b) => a.utcDate.compareTo(b.utcDate));

          // Group by local calendar day.
          final byDay = <DateTime, List<WcMatch>>{};
          for (final m in matches) {
            final k = DateUtils.dateOnly(m.localKickoff);
            byDay.putIfAbsent(k, () => []).add(m);
          }
          final days = byDay.keys.toList();
          final today = DateUtils.dateOnly(DateTime.now());

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(worldCupDataProvider.notifier).refresh(force: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _filterBar(theme)),
                SliverList.builder(
                  itemCount: days.length,
                  itemBuilder: (context, i) {
                    final day = days[i];
                    final isToday = DateUtils.isSameDay(day, today);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                          child: Text(
                            isToday
                                ? 'Today · ${DateFormat.MMMd().format(day)}'
                                : DateFormat.MMMMEEEEd().format(day),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isToday ? theme.colorScheme.primary : null,
                            ),
                          ),
                        ),
                        for (final m in byDay[day]!) MatchCard(match: m),
                      ],
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _matchesFilter(WcMatch m) {
    if (_stage != null && m.stage != _stage) return false;
    return switch (_filter) {
      _Filter.all => true,
      _Filter.upcoming => m.isUpcoming,
      _Filter.results => m.isFinished,
      _Filter.live => m.isLive,
    };
  }

  Widget _filterBar(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          for (final f in _Filter.values) ...[
            FilterChip(
              label: Text(switch (f) {
                _Filter.all => 'All',
                _Filter.upcoming => 'Upcoming',
                _Filter.results => 'Results',
                _Filter.live => 'Live',
              }),
              selected: _filter == f,
              onSelected: (_) => setState(() => _filter = f),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            width: 1,
            height: 24,
            color: theme.dividerColor,
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          const SizedBox(width: 8),
          for (final s in [
            Stage.groupStage,
            Stage.last32,
            Stage.last16,
            Stage.quarterFinals,
            Stage.semiFinals,
            Stage.finalStage,
          ]) ...[
            FilterChip(
              label: Text(s.label),
              selected: _stage == s,
              onSelected: (sel) => setState(() => _stage = sel ? s : null),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
