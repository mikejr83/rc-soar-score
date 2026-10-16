import 'package:flutter/material.dart';

import '../../services/scoring/scoring_completeness.dart';
import '../../services/scoring/scoring_row.dart';
import '../matrix/matrix_colors.dart';

/// A status chip: an icon and a word, so the state is never colour alone.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.icon,
    required this.label,
    this.background,
    this.foreground,
    this.dashed = false,
  });

  final IconData icon;
  final String label;
  final Color? background;
  final Color? foreground;

  /// Draws an outline only, for a state that has no value yet.
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = foreground ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: background == null ? scheme.outline : Colors.transparent,
          width: dashed ? 1 : 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

/// The status of one row: Not entered, Unsaved, Submitted, Official, Locked.
class RowStatusChip extends StatelessWidget {
  const RowStatusChip({super.key, required this.status, this.unsaved = false});

  final RowStatus status;

  /// Typed values that are not saved yet; shown over the saved status.
  final bool unsaved;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = MatrixColors.of(context);
    if (unsaved) {
      return StatusChip(
        icon: Icons.edit_note,
        label: 'Unsaved',
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      );
    }
    return switch (status) {
      RowStatus.notEntered => const StatusChip(
        icon: Icons.radio_button_unchecked,
        label: 'Not entered',
        dashed: true,
      ),
      RowStatus.submitted => StatusChip(
        icon: Icons.inbox,
        label: 'Submitted',
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurface,
      ),
      RowStatus.official => StatusChip(
        icon: Icons.verified,
        label: 'Official',
        background: colors.successContainer,
        foreground: colors.onSuccessContainer,
      ),
      RowStatus.locked => StatusChip(
        icon: Icons.lock,
        label: 'Locked',
        background: scheme.inverseSurface,
        foreground: scheme.onInverseSurface,
      ),
    };
  }
}

IconData completenessIcon(CompletenessState state) => switch (state) {
  CompletenessState.empty => Icons.radio_button_unchecked,
  CompletenessState.partial => Icons.timelapse,
  CompletenessState.entered => Icons.check_circle_outline,
  CompletenessState.official => Icons.verified,
  CompletenessState.locked => Icons.lock,
};
