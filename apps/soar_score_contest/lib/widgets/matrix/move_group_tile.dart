import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/matrix/draw_form_check.dart';
import '../../services/matrix/move_plan.dart';
import 'matrix_colors.dart';

/// One group of the move dialog: its mark (Recommended or Not ideal) and the
/// reasons, or why it cannot be chosen.
class MoveGroupTile extends StatelessWidget {
  const MoveGroupTile({
    super.key,
    required this.target,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final MoveTarget target;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  static String _blockText(AppLocalizations l10n, MoveTarget target) =>
      switch (target.block!) {
        MoveBlockKind.currentGroup => l10n.matrixMoveBlockCurrent,
        MoveBlockKind.alreadyInGroup => l10n.matrixMoveBlockAlready(
          target.round.ordinal,
        ),
        MoveBlockKind.groupLocked => l10n.matrixMoveBlockGroupLocked,
        MoveBlockKind.roundLocked => l10n.matrixMoveBlockRoundLocked,
        MoveBlockKind.teamProtection => l10n.matrixMoveBlockTeam,
      };

  static String _notIdealText(AppLocalizations l10n, NotIdealReason reason) =>
      switch (reason) {
        NotIdealReason.hasScores => l10n.matrixMoveReasonHasScores,
        NotIdealReason.roundCompleted => l10n.matrixMoveReasonRoundCompleted,
        NotIdealReason.teammate => l10n.matrixMoveReasonTeammate,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final colors = MatrixColors.of(context);
    final letter = DrawFormCheck.groupLetter(target.group - 1);
    final lines = target.allowed
        ? [for (final reason in target.notIdeal) _notIdealText(l10n, reason)]
        : [_blockText(l10n, target)];
    final mark = !target.allowed
        ? null
        : target.recommended
        ? (Icons.thumb_up_outlined, l10n.matrixMoveRecommended, scheme.primary)
        : (Icons.warning_amber, l10n.matrixMoveNotIdeal, colors.warn);
    return Semantics(
      selected: selected,
      child: ListTile(
        key: ValueKey('move-group-$letter'),
        enabled: enabled,
        selected: selected,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: selected
              ? BorderSide(color: scheme.primary, width: 2)
              : BorderSide.none,
        ),
        leading: Icon(
          !target.allowed
              ? Icons.block
              : selected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
        ),
        title: Row(
          spacing: 8,
          children: [
            Text(l10n.matrixMoveGroupLabel(letter)),
            if (mark != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Icon(mark.$1, size: 16, color: mark.$3),
                  Text(
                    mark.$2,
                    key: ValueKey('move-mark-$letter'),
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: mark.$3, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
          ],
        ),
        subtitle: lines.isEmpty
            ? null
            : Text(lines.join(' '), key: ValueKey('move-note-$letter')),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
