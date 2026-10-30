import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../l10n/app_localizations.dart';
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
    this.onMove,
    this.moveBlock,
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

  /// Moves this pilot; `null` when the grid cannot move pilots.
  final VoidCallback? onMove;

  /// Why moving is off for this contest, or `null` when it is on.
  final String? moveBlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = MatrixColors.of(context);
    final l10n = AppLocalizations.of(context);
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
          ..write(slot.moved ? ', ${l10n.matrixMovedLabel}' : '')
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
      customSemanticsActions: {
        if (selected && onMove != null && moveBlock == null)
          CustomSemanticsAction(label: l10n.matrixMoveMenu): onMove!,
      },
      // The tile gets its own Material so its ink and highlight paint inside
      // the grid's scroll views. On the page's Material they paint outside
      // the clipped viewport and show as blue lines beside the grid.
      child: Material(
        type: MaterialType.transparency,
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
                if (slot.moved) _MovedLabel(label: l10n.matrixMovedLabel),
                if (showLane && slot.lane != null)
                  Container(
                    constraints: const BoxConstraints(minHeight: 22),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: scheme.outline),
                    ),
                    child: Text(
                      'L${slot.lane}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                if (selected && onMove != null)
                  _PilotActions(onMove: onMove!, block: moveBlock),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The mark on a pilot whom a director moved: an icon and the word, so it
/// never relies on colour.
class _MovedLabel extends StatelessWidget {
  const _MovedLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      key: const ValueKey('moved-label'),
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Icon(Icons.swap_horiz, size: 14, color: scheme.onSurfaceVariant),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// The pilot actions menu on the highlighted pilot. Move is shown off, with
/// the reason beside it, when the contest does not allow it.
class _PilotActions extends StatelessWidget {
  const _PilotActions({required this.onMove, required this.block});

  final VoidCallback onMove;
  final String? block;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PopupMenuButton<void>(
      key: const ValueKey('pilot-actions'),
      tooltip: l10n.matrixPilotActions,
      padding: EdgeInsets.zero,
      iconSize: 18,
      style: IconButton.styleFrom(
        minimumSize: const Size(28, 28),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          key: const ValueKey('pilot-action-move'),
          enabled: block == null,
          onTap: onMove,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.matrixMoveMenu),
              if (block != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Text(
                    block!,
                    key: const ValueKey('pilot-action-move-reason'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
