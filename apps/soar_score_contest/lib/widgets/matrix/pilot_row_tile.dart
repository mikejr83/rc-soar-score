import 'package:flutter/material.dart';

import '../../services/matrix/matrix_grid_model.dart';
import '../../services/matrix/team_marker.dart';
import 'matrix_colors.dart';
import 'team_badge.dart';

/// One pilot in a group of a round. Selecting it highlights the pilot in
/// every round. The highlight is an outline, a bold name, a filled number
/// badge and a marker icon, so it never relies on colour. A search match gets
/// an amber outline and a search icon.
class PilotRowTile extends StatelessWidget {
  const PilotRowTile({
    super.key,
    required this.slot,
    required this.marker,
    this.showTeam = true,
    required this.selected,
    required this.matched,
    required this.showLane,
    required this.round,
    required this.group,
    required this.textScale,
    required this.onTap,
  });

  final GridSlot slot;
  final TeamMarker? marker;
  final bool showTeam;
  final bool selected;
  final bool matched;
  final bool showLane;
  final int round;
  final String group;
  final double textScale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = MatrixColors.of(context);
    final pilot = slot.pilot;
    final label =
        StringBuffer(
            pilot.number == null
                ? pilot.name
                : 'Pilot ${pilot.numberText}, ${pilot.name}',
          )
          ..write(
            showTeam ? ', ${marker == null ? 'no team' : marker!.name}' : '',
          )
          ..write(showLane && slot.lane != null ? ', lane ${slot.lane}' : '')
          ..write(', round $round, group $group')
          ..write(selected ? ', highlighted' : '')
          ..write(matched ? ', search match' : '');
    final ring = selected
        ? Border.all(color: scheme.primary, width: 2)
        : matched
        ? Border.all(color: colors.warn, width: 2)
        : null;
    final background = selected
        ? scheme.primaryContainer
        : matched
        ? scheme.tertiaryContainer
        : Colors.transparent;
    return Semantics(
      button: true,
      selected: selected,
      label: label.toString(),
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: background,
            border: ring,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              if (selected || matched)
                Icon(
                  selected ? Icons.person_pin : Icons.search,
                  size: 18,
                  color: selected ? scheme.primary : colors.warn,
                ),
              if (pilot.number != null)
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 22,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.primary
                        : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pilot.numberText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected ? scheme.onPrimary : scheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              if (showTeam) TeamBadge(marker: marker, scale: textScale),
              Expanded(
                child: Text(
                  pilot.name,
                  maxLines: textScale > 1.15 ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (showLane && slot.lane != null)
                Container(
                  constraints: const BoxConstraints(minHeight: 22),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Text('L${slot.lane}', style: TextStyle(fontSize: 12)),
                ),
              if (selected)
                Tooltip(
                  message: 'Pilot actions (move, late add) · later release',
                  child: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: .38),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
