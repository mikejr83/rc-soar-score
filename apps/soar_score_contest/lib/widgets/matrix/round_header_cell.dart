import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/matrix/matrix_grid_model.dart';
import 'matrix_colors.dart';

/// The heading of a round column: its title, a dimmed placeholder for the
/// round actions of a later release, its status (icon plus text) and the
/// check that every scoring pilot flies exactly once.
class RoundHeaderCell extends StatelessWidget {
  const RoundHeaderCell({
    super.key,
    required this.round,
    required this.pilotCount,
    required this.textScale,
  });

  final GridRound round;

  /// The scoring pilots in the matrix, for the exactly-once check.
  final int pilotCount;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = MatrixColors.of(context);
    final scored = round.status == RoundStatus.locked;
    final (icon, text, background, foreground, outlined) = scored
        ? (
            Icons.check_circle,
            'Scored',
            colors.successContainer,
            colors.onSuccessContainer,
            false,
          )
        : (
            Icons.schedule,
            'Not flown',
            Colors.transparent,
            scheme.onSurfaceVariant,
            true,
          );
    final once =
        round.distinctPilots == pilotCount && round.pilotCount == pilotCount;
    final count = once
        ? '$pilotCount pilots, each once'
        : '${round.distinctPilots} of $pilotCount';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Round ${round.ordinal}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: null,
                tooltip: 'Round actions (redraw) · later release',
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                icon: const Icon(Icons.more_vert, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 24),
                padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(8),
                  border: outlined ? Border.all(color: scheme.outline) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    Icon(icon, size: 16, color: foreground),
                    Flexible(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message:
                    'Every scoring pilot appears exactly once in this '
                    'round',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    Icon(Icons.done_all, size: 16, color: colors.success),
                    Flexible(
                      child: Text(
                        count,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
