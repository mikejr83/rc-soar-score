import 'package:flutter/material.dart';

import '../../services/scoring/scoring_controller.dart';
import '../../services/scoring/scoring_row.dart';
import '../matrix/matrix_colors.dart';

/// One line above the grid: round status, lock state, unsaved count, and how
/// many pilots are entered and official.
class ScoringContextStrip extends StatelessWidget {
  const ScoringContextStrip({super.key, required this.controller});

  final ScoringController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = MatrixColors.of(context);
    final rows = controller.rows;
    final entered = rows.where((r) => r.isScored).length;
    final official = rows
        .where(
          (r) => r.status == RowStatus.official || r.isLocked && r.isScored,
        )
        .length;
    final dirty = controller.dirtyCount;
    final block = controller.block;
    final facts = <(IconData, String, Color?)>[
      (
        Icons.checklist,
        '$entered of ${rows.length} entered · $official official',
        null,
      ),
      if (dirty > 0)
        (
          Icons.edit_note,
          '$dirty unsaved ${dirty == 1 ? 'row' : 'rows'}',
          colors.warn,
        ),
      if (block != null) (Icons.lock, block.message, null),
    ];
    return Container(
      key: const ValueKey('scoring-context-strip'),
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 24,
        runSpacing: 6,
        children: [
          for (final (icon, text, color) in facts)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(color: color),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
