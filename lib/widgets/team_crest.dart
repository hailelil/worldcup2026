import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/team.dart';

/// Team crest/flag image with graceful fallbacks: SVG and PNG URLs are both
/// handled; missing crests (TBD knockout slots) show a TLA monogram.
class TeamCrest extends StatelessWidget {
  const TeamCrest({super.key, required this.team, this.size = 28});

  final TeamRef team;
  final double size;

  /// Widget tests set this to false: the test HTTP stub returns invalid
  /// bytes, and flutter_svg reports parse failures to FlutterError even
  /// though the errorBuilder fallback renders.
  static bool networkImagesEnabled = true;

  @override
  Widget build(BuildContext context) {
    final crest = team.crest;
    final Widget image;
    if (crest == null || !networkImagesEnabled) {
      image = _monogram(context);
    } else if (crest.toLowerCase().endsWith('.svg')) {
      image = SvgPicture.network(
        crest,
        width: size,
        height: size,
        placeholderBuilder: (_) => _monogram(context),
        errorBuilder: (_, _, _) => _monogram(context),
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: crest,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => _monogram(context),
        errorWidget: (_, _, _) => _monogram(context),
      );
    }
    return ClipOval(child: SizedBox(width: size, height: size, child: image));
  }

  Widget _monogram(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        team.tla?.substring(0, team.tla!.length.clamp(0, 2)) ?? '?',
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
