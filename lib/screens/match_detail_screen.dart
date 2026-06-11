import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/match.dart';
import '../models/team.dart';
import '../state/providers.dart';
import '../widgets/status_chip.dart';
import '../widgets/team_crest.dart';

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.match});

  final WcMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-read the match from the provider so live refreshes update this
    // screen too; fall back to the value we were pushed with.
    final data = ref.watch(worldCupDataProvider).value;
    final current = data?.matches
            .where((m) => m.id == match.id)
            .firstOrNull ??
        match;
    final theme = Theme.of(context);
    final kickoff = current.localKickoff;
    final tzName = kickoff.timeZoneName;

    return Scaffold(
      appBar: AppBar(title: Text(current.stageOrGroupLabel)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  StatusChip(match: current),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _team(theme, current.homeTeam)),
                      _ScoreDisplay(match: current),
                      Expanded(child: _team(theme, current.awayTeam)),
                    ],
                  ),
                  if (current.score.halfTimeHome != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Half-time: ${current.score.halfTimeHome} – ${current.score.halfTimeAway}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                  if (current.score.duration == 'PENALTY_SHOOTOUT')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Decided on penalties',
                          style: theme.textTheme.bodySmall),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _infoTile(
            Icons.schedule,
            'Kick-off',
            '${DateFormat.yMMMMEEEEd().format(kickoff)}\n'
                '${DateFormat.jm().format(kickoff)} $tzName',
          ),
          if (current.venue != null)
            _infoTile(Icons.stadium_outlined, 'Venue', current.venue!),
          _infoTile(Icons.emoji_events_outlined, 'Stage',
              '${current.stage.label}${current.matchday != null && current.stage == Stage.groupStage ? ' · Matchday ${current.matchday}' : ''}'),
          if (current.lastUpdated != null)
            _infoTile(Icons.update, 'Last updated',
                DateFormat.MMMd().add_jm().format(current.lastUpdated!.toLocal())),
        ],
      ),
    );
  }

  Widget _team(ThemeData theme, TeamRef team) {
    return Column(
      children: [
        TeamCrest(team: team, size: 56),
        const SizedBox(height: 8),
        Text(
          team.displayName,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: team.isPlaceholder ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  const _ScoreDisplay({required this.match});
  final WcMatch match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final home = match.score.fullTimeHome;
    final away = match.score.fullTimeAway;
    final big = theme.textTheme.displaySmall
        ?.copyWith(fontWeight: FontWeight.w900, height: 1);
    final sep = theme.textTheme.headlineSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant, height: 1);

    if (home != null && away != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$home',
              style: big?.copyWith(
                color: match.score.winner == 'HOME_TEAM'
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('–', style: sep),
            ),
            Text(
              '$away',
              style: big?.copyWith(
                color: match.score.winner == 'AWAY_TEAM'
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        DateFormat.jm().format(match.localKickoff),
        style:
            theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
