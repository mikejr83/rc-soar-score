import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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
    this.dense = false,
  });

  final IconData icon;
  final String label;
  final Color? background;
  final Color? foreground;

  /// Draws an outline only, for a state that has no value yet.
  final bool dashed;

  /// A small chip for flags and indicators. Its text wraps in a narrow
  /// column instead of being cut off.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = foreground ?? scheme.onSurfaceVariant;
    return Container(
      constraints: BoxConstraints(minHeight: dense ? 22 : 28),
      padding: dense
          ? const EdgeInsets.fromLTRB(4, 1, 6, 1)
          : const EdgeInsets.fromLTRB(6, 2, 10, 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(dense ? 6 : 8),
        border: Border.all(
          color: background == null ? scheme.outline : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 14 : 18, color: fg),
          SizedBox(width: dense ? 4 : 6),
          Flexible(
            child: Text(
              label,
              overflow: dense ? null : TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: fg, fontSize: dense ? 12 : 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// The status of one row: Not entered, Unsaved, Submitted, Official, Locked, Retired.
class RowStatusChip extends StatelessWidget {
  const RowStatusChip({
    super.key,
    required this.status,
    this.unsaved = false,
    this.automatic = false,
  });

  final RowStatus status;

  /// Typed values that are not saved yet; shown over the saved status.
  final bool unsaved;

  /// An official score the contest accepted on its own that the director has
  /// not confirmed: shown as "Accepted automatically" instead of "Official".
  final bool automatic;

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
      RowStatus.official when automatic => StatusChip(
        icon: Icons.auto_mode,
        label: AppLocalizations.of(context).scoreAcceptedAutomatically,
        background: colors.successContainer,
        foreground: colors.onSuccessContainer,
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
      RowStatus.retired => StatusChip(
        icon: Icons.person_off_outlined,
        label: 'Retired',
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurface,
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
