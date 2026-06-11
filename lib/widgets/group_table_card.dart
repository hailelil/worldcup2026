import 'package:flutter/material.dart';

import '../models/standing.dart';
import '../theme/app_theme.dart';
import 'team_crest.dart';

/// One group's table. The top 2 qualify directly (tinted green); 3rd place
/// may still advance among the 8 best thirds in the 2026 format.
class GroupTableCard extends StatelessWidget {
  const GroupTableCard({super.key, required this.standing});

  final GroupStanding standing;

  static const _headers = ['P', 'W', 'D', 'L', 'GD', 'Pts'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(standing.label,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Table(
              columnWidths: {
                0: const FixedColumnWidth(26),
                1: const FlexColumnWidth(),
                for (var i = 2; i < 8; i++) i: const FixedColumnWidth(30),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  children: [
                    Text('#', style: labelStyle),
                    Text('Team', style: labelStyle),
                    for (final h in _headers)
                      Text(h, style: labelStyle, textAlign: TextAlign.center),
                  ],
                ),
                for (final entry in standing.table) _row(theme, entry),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _row(ThemeData theme, TableEntry entry) {
    final qualifies = entry.position <= 2;
    final numberStyle = theme.textTheme.bodySmall;
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: qualifies
                ? BoxDecoration(
                    color: qualifiedColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  )
                : null,
            child: Text('${entry.position}',
                style: numberStyle?.copyWith(
                  fontWeight: qualifies ? FontWeight.w700 : null,
                  color: qualifies ? qualifiedColor : null,
                )),
          ),
        ),
        Row(
          children: [
            TeamCrest(team: entry.team, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(entry.team.tla ?? entry.team.displayName,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        for (final value in [
          entry.playedGames,
          entry.won,
          entry.draw,
          entry.lost,
          entry.goalDifference,
          entry.points,
        ])
          Text('$value',
              textAlign: TextAlign.center,
              style: numberStyle?.copyWith(
                fontWeight:
                    value == entry.points ? FontWeight.w700 : FontWeight.w400,
              )),
      ],
    );
  }
}
