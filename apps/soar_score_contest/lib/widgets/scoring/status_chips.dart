import 'package:material_ui/material_ui.dart';

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
    this.wrap = false,
  });

  final IconData icon;
  final String label;
  final Color? background;
  final Color? foreground;

  /// Draws an outline only, for a state that has no value yet.
  final bool dashed;

  /// A small chip for flags and indicators (`Scoring Screen.dc.html`: 22 px
  /// tall, 11 px radius, 12 px text, 14 px icon). Its column is wide enough
  /// for the label at the default text size; a larger text size wraps the
  /// label and the chip grows taller instead of cutting it off.
  final bool dense;

  /// Wraps a long label inside its column instead of ending it with an
  /// ellipsis, for a label whose second word matters (Official · automatic).
  /// It uses the small chip's icon, padding and text so the longest word
  /// still fits the status column (132 px) at the Extra large text size; the
  /// chip keeps the regular height and radius.
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = foreground ?? scheme.onSurfaceVariant;
    final small = dense || wrap;
    return Container(
      constraints: BoxConstraints(minHeight: dense ? 22 : 28),
      padding: small
          ? const EdgeInsets.fromLTRB(4, 1, 6, 1)
          : const EdgeInsets.fromLTRB(6, 2, 10, 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(dense ? 11 : 8),
        border: dense && background != null
            ? null
            : Border.all(
                color: background == null ? scheme.outline : Colors.transparent,
                width: 1,
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 14 : 18, color: fg),
          SizedBox(width: small ? 4 : 6),
          Flexible(
            child: Text(
              label,
              overflow: small ? null : TextOverflow.ellipsis,
              style: small
                  ? Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    )
                  : Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: fg, fontSize: 13),
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
  /// not confirmed: shown as "Official · automatic" instead of plain "Official".
  final bool automatic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = MatrixColors.of(context);
    final words = AppLocalizations.of(context);
    if (unsaved) {
      return StatusChip(
        icon: Icons.edit_note,
        label: words.scoreStatusUnsaved,
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      );
    }
    return switch (status) {
      RowStatus.notEntered => StatusChip(
        icon: Icons.radio_button_unchecked,
        label: words.scoreStatusNotEntered,
        dashed: true,
      ),
      RowStatus.submitted => StatusChip(
        icon: Icons.inbox,
        label: words.scoreStatusSubmitted,
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurface,
      ),
      RowStatus.official when automatic => StatusChip(
        icon: Icons.auto_mode,
        label: words.scoreAcceptedAutomatically,
        wrap: true,
        background: colors.successContainer,
        foreground: colors.onSuccessContainer,
      ),
      RowStatus.official => StatusChip(
        icon: Icons.verified,
        label: words.scoreStatusOfficial,
        background: colors.successContainer,
        foreground: colors.onSuccessContainer,
      ),
      RowStatus.locked => StatusChip(
        icon: Icons.lock,
        label: words.scoreStatusLocked,
        background: scheme.inverseSurface,
        foreground: scheme.onInverseSurface,
      ),
      RowStatus.retired => StatusChip(
        icon: Icons.person_off_outlined,
        label: words.scoreStatusRetired,
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
