import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/match.dart';
import '../state/providers.dart';
import '../widgets/match_card.dart';
import '../widgets/offline_banner.dart';

/// The answer to "what time is the match?": today's fixtures with live
/// scores, a countdown to the next kickoff, and the latest results.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Poll once a minute; the repository's TTL/debounce decides whether the
    // network is actually hit (only near kickoff or while live).
    _pollTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      ref.read(worldCupDataProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  static String _timeAgo(DateTime t) {
    final mins = DateTime.now().toUtc().difference(t.toUtc()).inMinutes;
    if (mins < 1) return 'just now';
    if (mins == 1) return '1 min ago';
    if (mins < 60) return '$mins min ago';
    final hrs = mins ~/ 60;
    return hrs == 1 ? '1 hour ago' : '$hrs hours ago';
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(worldCupDataProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('World Cup 2026')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load data\n$e')),
        data: (data) {
          final now = DateTime.now();
          final today = data.matches
              .where((m) => DateUtils.isSameDay(m.localKickoff, now))
              .toList()
            ..sort((a, b) => a.utcDate.compareTo(b.utcDate));
          // Exclude matches already shown in "today" from "next kick-off".
          final todayIds = today.map((m) => m.id).toSet();
          final next = data.matches
              .where((m) =>
                  m.isUpcoming &&
                  m.utcDate.isAfter(now.toUtc()) &&
                  !todayIds.contains(m.id))
              .fold<WcMatch?>(null,
                  (a, b) => a == null || b.utcDate.isBefore(a.utcDate) ? b : a);
          final recent = data.matches.where((m) => m.isFinished).toList()
            ..sort((a, b) => b.utcDate.compareTo(a.utcDate));

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(worldCupDataProvider.notifier).refresh(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const OfflineBanner(),
                if (today.isNotEmpty) ...[
                  _header(theme,
                      'Today · ${DateFormat.MMMMEEEEd().format(now)}'),
                  for (final m in today) MatchCard(match: m),
                ] else
                  _header(theme, 'No matches today'),
                if (next != null) ...[
                  _header(theme, 'Next kick-off'),
                  _CountdownTile(match: next),
                  MatchCard(match: next),
                ],
                if (recent.isNotEmpty) ...[
                  _header(theme, 'Latest results'),
                  for (final m in recent.take(5)) MatchCard(match: m),
                ],
                if (data.fetchedAt != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      'Updated ${_timeAgo(data.fetchedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(text,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _CountdownTile extends StatefulWidget {
  const _CountdownTile({required this.match});

  final WcMatch match;

  @override
  State<_CountdownTile> createState() => _CountdownTileState();
}

class _CountdownTileState extends State<_CountdownTile> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.match.utcDate.difference(DateTime.now().toUtc());
    if (remaining.isNegative) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;
    final text = days > 0
        ? '${days}d ${hours}h ${minutes}m'
        : '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, color: scheme.onPrimaryContainer),
            const SizedBox(width: 10),
            Text(
              text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
