import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/match.dart';
import '../theme/app_theme.dart';

/// Compact status indicator: kickoff time for upcoming matches, a red LIVE
/// badge while in play, "FT" when finished.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.match});

  final WcMatch match;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (match.isLive) {
      return _pill(
        match.status == MatchStatus.paused ? 'HT' : 'LIVE',
        background: liveColor,
        foreground: Colors.white,
      );
    }
    if (match.isFinished) {
      return _pill('FT',
          background: scheme.surfaceContainerHighest,
          foreground: scheme.onSurfaceVariant);
    }
    if (match.status == MatchStatus.postponed ||
        match.status == MatchStatus.cancelled ||
        match.status == MatchStatus.suspended) {
      return _pill(match.status.toApi(),
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer);
    }
    return _pill(DateFormat.jm().format(match.localKickoff),
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer);
  }

  Widget _pill(String label,
      {required Color background, required Color foreground}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
