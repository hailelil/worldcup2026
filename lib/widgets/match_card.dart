import 'package:flutter/material.dart';

import '../models/match.dart';
import '../models/team.dart';
import '../screens/match_detail_screen.dart';
import 'status_chip.dart';
import 'team_crest.dart';

/// The match row used everywhere: teams, score (or kickoff time via
/// [StatusChip]) and the stage/group caption. Tapping opens the detail view.
class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, this.showStageLabel = true});

  final WcMatch match;
  final bool showStageLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = match.displayScore;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showStageLabel) ...[
                Text(
                  match.venue == null
                      ? match.stageOrGroupLabel
                      : '${match.stageOrGroupLabel} · ${match.venue}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _teamRow(theme, match.homeTeam,
                            score == null ? null : score.split(' – ')[0],
                            winner: match.score.winner == 'HOME_TEAM'),
                        const SizedBox(height: 8),
                        _teamRow(theme, match.awayTeam,
                            score == null ? null : score.split(' – ')[1],
                            winner: match.score.winner == 'AWAY_TEAM'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  StatusChip(match: match),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamRow(ThemeData theme, TeamRef team, String? goals,
      {required bool winner}) {
    final style = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: winner ? FontWeight.w700 : FontWeight.w500,
      color: team.isPlaceholder ? theme.colorScheme.onSurfaceVariant : null,
    );
    return Row(
      children: [
        TeamCrest(team: team, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(team.displayName,
              style: style, overflow: TextOverflow.ellipsis),
        ),
        if (goals != null) Text(goals, style: style),
      ],
    );
  }
}
