import 'package:flutter/material.dart';

import '../../services/matrix/matrix_grid_model.dart';
import '../../services/matrix/round_progress_view.dart';
import 'matrix_colors.dart';

/// The heading of a round column: its title, its status (icon plus text) and
/// the check that every scoring pilot flies exactly once.
class RoundHeaderCell extends StatelessWidget {
  const RoundHeaderCell({
    super.key,
    required this.round,
    required this.pilotCount,
    required this.textScale,
    this.dropNumber = 0,
  });

  final GridRound round;

  /// The scoring pilots in the matrix, for the exactly-once check.
  final int pilotCount;
  final double textScale;

  /// 1 or 2 when the contest drops a round score once this round is
  /// complete (the first or second drop); 0 when no drop starts here.
  final int dropNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = MatrixColors.of(context);
    final progress = round.progress;
    final (icon, background, foreground, outlined) = switch (progress.state) {
      RoundProgressState.scored => (
        Icons.check_circle,
        colors.successContainer,
        colors.onSuccessContainer,
        false,
      ),
      RoundProgressState.inProgress => (
        Icons.timelapse,
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        false,
      ),
      RoundProgressState.cancelled => (
        Icons.cancel_outlined,
        scheme.errorContainer,
        scheme.onErrorContainer,
        false,
      ),
      RoundProgressState.notFlown => (
        Icons.schedule,
        Colors.transparent,
        scheme.onSurfaceVariant,
        true,
      ),
    };
    final text = progress.label;
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    Flexible(
                      child: Text(
                        'Round ${round.ordinal}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          // A line box as tall as the font keeps the text
                          // and the 16 px icons beside it on one centre.
                          height: 1,
                          leadingDistribution: TextLeadingDistribution.even,
                        ),
                      ),
                    ),
                    if (round.isLocked)
                      Tooltip(
                        message: 'Round locked',
                        child: Icon(
                          Icons.lock_outline,
                          size: 16,
                          semanticLabel: 'Round locked',
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    if (dropNumber > 0)
                      Tooltip(
                        message:
                            'Drop $dropNumber: the lowest round score is '
                            'dropped once this round is complete',
                        child: Icon(
                          Icons.arrow_circle_down_outlined,
                          size: 16,
                          semanticLabel:
                              'Drop $dropNumber starts after this round',
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
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
