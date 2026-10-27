import 'package:flutter/material.dart';

import '../../services/participants/participant_row.dart';

/// A short avatar for a team. The full name stays available as its tooltip
/// and accessible label.
class TeamAvatar extends StatelessWidget {
  const TeamAvatar({super.key, required this.team, this.size = 26});

  final String team;
  final double size;

  /// The container colors for [team], stable per name (ignoring case).
  static (Color, Color) colorsFor(ColorScheme scheme, String team) {
    var hash = 0;
    for (final unit in team.toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return switch (hash % 4) {
      0 => (scheme.primaryContainer, scheme.onPrimaryContainer),
      1 => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      2 => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      _ => (scheme.surfaceContainerHighest, scheme.onSurface),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = colorsFor(
      Theme.of(context).colorScheme,
      team,
    );
    return Tooltip(
      message: team,
      child: Semantics(
        label: 'Team $team',
        excludeSemantics: true,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Text(
            initials(team.replaceAll(RegExp(r'\s+RC$'), '')),
            style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
