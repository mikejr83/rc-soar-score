import 'package:flutter/material.dart';

import '../../services/scoring/scoring_completeness.dart';
import '../../services/scoring/scoring_controller.dart';
import '../../services/scoring/scoring_row.dart';
import '../matrix/matrix_colors.dart';
import 'status_chips.dart';

/// The group's status line under the toolbar: chips for the round state and
/// the lock, a chip for unsaved rows, and the count of entered and official.
class ScoringContextStrip extends StatelessWidget {
  const ScoringContextStrip({super.key, required this.controller});

  final ScoringController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = MatrixColors.of(context);
    final data = controller.data!;
    final round = controller.currentRound;
    // A retired pilot's unscored flight is not missing, so it is not counted.
    final rows = controller.rows.where((r) => !r.isMissed).toList();
    final entered = rows.where((r) => r.isScored).length;
    final official = rows
        .where(
          (r) => r.status == RowStatus.official || r.isLocked && r.isScored,
        )
        .length;
    final dirty = controller.dirtyCount;
    final block = controller.block;
    final roundState = round == null
        ? CompletenessState.empty
        : data.roundCompleteness(round).state;
    final roundText = switch (roundState) {
      CompletenessState.empty => 'Round not flown',
      CompletenessState.partial => 'Round in progress',
      CompletenessState.entered ||
      CompletenessState.official ||
      CompletenessState.locked => 'Round scored',
    };
    final roundIcon = switch (roundState) {
      CompletenessState.empty => Icons.radio_button_unchecked,
      CompletenessState.partial => Icons.timelapse,
      _ => Icons.check_circle,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Wrap(
          key: const ValueKey('scoring-context-strip'),
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusChip(
              icon: roundIcon,
              label: roundText,
              background: roundState == CompletenessState.partial
                  ? scheme.tertiaryContainer
                  : null,
              foreground: roundState == CompletenessState.partial
                  ? scheme.onTertiaryContainer
                  : scheme.onSurface,
            ),
            if (block != null)
              StatusChip(
                icon: Icons.lock,
                label: block.chip,
                background: scheme.inverseSurface,
                foreground: scheme.onInverseSurface,
              )
            else
              StatusChip(
                icon: Icons.lock_open,
                label: 'Open for entry',
                foreground: scheme.onSurface,
              ),
            if (dirty > 0)
              StatusChip(
                icon: Icons.edit_note,
                label: '$dirty unsaved ${dirty == 1 ? 'row' : 'rows'}',
                background: scheme.tertiaryContainer,
                foreground: scheme.onTertiaryContainer,
              ),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '$entered of ${rows.length} entered · $official official',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: dirty > 0 ? colors.warn : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
