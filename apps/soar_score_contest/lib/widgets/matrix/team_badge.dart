import 'package:flutter/material.dart';

import '../../services/matrix/team_marker.dart';
import 'matrix_colors.dart';

/// A team's code in a coloured box. Teams 13 and up are outlined with no
/// fill; a pilot without a team gets a dashed-looking "–". The team's full
/// name is in the tooltip and in the row's accessible label.
class TeamBadge extends StatelessWidget {
  const TeamBadge({super.key, required this.marker, this.scale = 1});

  /// `null` for a pilot without a team.
  final TeamMarker? marker;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marker = this.marker;
    final colors = MatrixColors.of(context);
    final (fill, ink) = marker == null
        ? (Colors.transparent, theme.colorScheme.onSurfaceVariant)
        : marker.outlined
        ? (Colors.transparent, colors.team(marker.paletteIndex).$2)
        : colors.team(marker.paletteIndex);
    final border = marker == null
        ? theme.colorScheme.outlineVariant
        : marker.outlined
        ? colors.team(marker.paletteIndex).$2
        : Colors.transparent;
    final badge = Container(
      constraints: BoxConstraints(minWidth: 26, minHeight: 22 * scale),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        marker?.code ?? '–',
        style: TextStyle(
          fontSize: 11 * scale,
          fontWeight: FontWeight.w700,
          letterSpacing: .3,
          color: ink,
        ),
      ),
    );
    return ExcludeSemantics(
      child: Tooltip(message: marker?.name ?? 'No team', child: badge),
    );
  }
}
