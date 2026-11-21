import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../services/contest_participants/participants_controller.dart';
import '../../services/contest_participants/stored_participant.dart';
import '../page_states/page_banner.dart';

/// The banners above the Participants list, each with an icon and words.
///
/// - the contest is read-only, or administration is locked;
/// - fewer than 2 scoring pilots before the draw (error), or exactly 2
///   (warning);
/// - an add or a removal that did not go through;
/// - people who left the draw (removed, or made non-flying, with no scores):
///   the draw needs redoing;
/// - results recalculated after a change in a running contest;
/// - people added since the draw who are not in a group yet;
/// - scoring pilots with no class (when classes are on), as a notice only.
List<Widget> participantBanners({
  required BuildContext context,
  required ParticipantsController controller,
  required VoidCallback onAdd,
  required VoidCallback onRetryAdd,
  required VoidCallback onUnlock,
  required VoidCallback onOpenMatrix,
  required VoidCallback onOpenScoring,
  required VoidCallback onRedoDraw,
  required VoidCallback onPlaceUnplaced,
  required ValueChanged<StoredParticipant> onShowClass,
}) {
  final l10n = AppLocalizations.of(context);
  final c = controller;
  final banners = <Widget>[];
  if (c.readOnly) {
    banners.add(
      PageBanner(
        key: const ValueKey('banner-read-only'),
        kind: PageBannerKind.neutral,
        icon: Icons.flag,
        shape: PageBannerShape.card,
        text: l10n.contestParticipantsReadOnlyText,
      ),
    );
  }
  if (c.adminLocked) {
    banners.add(
      PageBanner(
        key: const ValueKey('banner-locked'),
        kind: PageBannerKind.neutral,
        icon: Icons.lock,
        shape: PageBannerShape.card,
        title: l10n.contestParticipantsLockedTitle,
        text: l10n.contestParticipantsLockedText,
        actionLabel: l10n.contestParticipantsUnlock,
        onAction: onUnlock,
      ),
    );
  }
  final pilots = c.scoringPilots;
  if (!c.drawn && !c.readOnly && pilots < 2) {
    banners.add(
      PageBanner(
        key: const ValueKey('banner-min-pilots'),
        kind: PageBannerKind.alert,
        icon: Icons.error,
        shape: PageBannerShape.card,
        text: l10n.contestParticipantsMinPilots,
        actionLabel: c.canEdit ? l10n.shellAddParticipant : null,
        onAction: c.canEdit ? onAdd : null,
      ),
    );
  } else if (!c.drawn && !c.readOnly && pilots == 2) {
    banners.add(
      PageBanner(
        key: const ValueKey('banner-few-pilots'),
        kind: PageBannerKind.status,
        icon: Icons.warning,
        shape: PageBannerShape.card,
        text: l10n.contestParticipantsFewPilots,
      ),
    );
  }
  final failedAdd = c.failedAdd;
  if (failedAdd != null) {
    banners.add(
      PageBanner(
        key: const ValueKey('banner-add-failed'),
        kind: PageBannerKind.alert,
        icon: Icons.error,
        shape: PageBannerShape.card,
        title: l10n.contestParticipantsAddFailedTitle(
          '${failedAdd.firstName} ${failedAdd.lastName}',
        ),
        text: c.addNeedsRoom
            ? l10n.contestParticipantsAddFailedRoom(c.addFailure ?? '').trim()
            : l10n.contestParticipantsAddFailedRetry(c.addFailure ?? '').trim(),
        actionLabel: c.addNeedsRoom
            ? l10n.contestParticipantsOpenMatrix
            : l10n.contestParticipantsTryAgain,
        onAction: c.addNeedsRoom ? onOpenMatrix : onRetryAdd,
      ),
    );
  }
  final removal = c.lastRemoval;
  if (removal != null && removal.refused.isNotEmpty) {
    banners.add(
      PageBanner(
        key: const ValueKey('banner-removal'),
        kind: PageBannerKind.status,
        icon: Icons.person_remove,
        shape: PageBannerShape.card,
        title: removal.isPartial
            ? l10n.contestParticipantsPartialRemoved(
                removal.removed.length,
                removal.removed.length + removal.refused.length,
              )
            : l10n.contestParticipantsNotRemoved,
        text: [
          if (removal.removed.isNotEmpty)
            l10n.contestParticipantsRemovedFrom(
              ParticipantsController.andList(removal.removed),
              removal.removed.length == 1 ? 'was' : 'were',
            ),
          for (final refused in removal.refused)
            l10n.contestParticipantsRefused(refused.name, refused.reason),
          l10n.contestParticipantsRetireNote,
        ].join(' '),
        actionLabel: l10n.contestParticipantsOpenScoring,
        onAction: onOpenScoring,
        secondaryLabel: l10n.contestParticipantsDismiss,
        onSecondary: c.dismissRemoval,
      ),
    );
  }
  if (c.leftTheDraw.isNotEmpty) {
    final names = ParticipantsController.andList(c.leftTheDraw);
    banners.add(
      PageBanner(
        key: const ValueKey('banner-redo-draw'),
        kind: PageBannerKind.status,
        icon: Icons.grid_view,
        shape: PageBannerShape.card,
        title: l10n.contestParticipantsRedoDrawTitle,
        text: l10n.contestParticipantsRedoDrawText(
          names,
          c.leftTheDraw.length == 1 ? 'was' : 'were',
          c.leftTheDraw.length == 1 ? 'has' : 'have',
        ),
        actionLabel: l10n.contestParticipantsRedoDraw,
        onAction: onRedoDraw,
        secondaryLabel: l10n.contestParticipantsDismiss,
        onSecondary: c.dismissLeftTheDraw,
      ),
    );
  }
  if (c.recalculated.isNotEmpty || c.recalculationWarning != null) {
    banners.add(
      PageBanner(
        key: const ValueKey('banner-recalculated'),
        kind: PageBannerKind.status,
        icon: Icons.calculate,
        shape: PageBannerShape.card,
        title: l10n.contestParticipantsRecalculatedTitle,
        text: [
          if (c.recalculated.isNotEmpty)
            l10n.contestParticipantsRecalculatedText(
              ParticipantsController.andList(c.recalculated),
            ),
          ?c.recalculationWarning,
        ].join(' '),
      ),
    );
  }
  final placement = c.lastPlacement;
  if (placement != null) {
    final zeroed = placement.zeroedRounds;
    final skipped = placement.skipped;
    banners.add(
      PageBanner(
        key: const ValueKey('banner-placement'),
        kind: skipped.isEmpty ? PageBannerKind.info : PageBannerKind.status,
        icon: skipped.isEmpty ? Icons.grid_view : Icons.warning,
        shape: PageBannerShape.card,
        title: skipped.isEmpty
            ? l10n.contestParticipantsPlacedEverywhere(placement.name)
            : l10n.contestParticipantsNotPlacedEverywhere(placement.name),
        text: [
          if (placement.result.placed.isNotEmpty)
            l10n.contestParticipantsPlacedInRounds(
              placement.name,
              placement.result.placed.length,
              placement.result.placed.length == 1 ? 'round' : 'rounds',
            ),
          if (zeroed.isNotEmpty)
            l10n.contestParticipantsZeroedRounds(
              _rounds(l10n, zeroed),
              zeroed.length == 1 ? 'was' : 'were',
              zeroed.length == 1 ? 'there' : 'in them',
            ),
          for (final skip in skipped)
            l10n.contestParticipantsRoundReason(skip.round, skip.reason),
          if (skipped.isNotEmpty) l10n.contestParticipantsPlaceFromMatrix,
        ].join(' '),
        actionLabel: skipped.isEmpty
            ? l10n.contestParticipantsOpenScoring
            : l10n.contestParticipantsOpenMatrix,
        onAction: skipped.isEmpty ? onOpenScoring : onOpenMatrix,
        secondaryLabel: l10n.contestParticipantsDismiss,
        onSecondary: c.dismissPlacement,
      ),
    );
  }
  final unplaced = c.unplaced;
  if (unplaced.isNotEmpty && !c.readOnly) {
    final names = ParticipantsController.andList([
      for (final row in unplaced) row.name,
    ]);
    banners.add(
      PageBanner(
        key: const ValueKey('banner-unplaced'),
        kind: PageBannerKind.neutral,
        icon: Icons.pending,
        shape: PageBannerShape.card,
        title: l10n.contestParticipantsUnplacedTitle(
          names,
          unplaced.length == 1 ? 'isn’t' : 'aren’t',
        ),
        text: l10n.contestParticipantsUnplacedText,
        actionLabel: l10n.contestParticipantsPlaceAllRounds,
        onAction: onPlaceUnplaced,
        secondaryLabel: l10n.contestParticipantsOpenMatrix,
        onSecondary: onOpenMatrix,
      ),
    );
  }
  final missing = c.missingClass;
  if (missing.isNotEmpty && !c.readOnly) {
    banners.add(
      PageBanner(
        key: const ValueKey('banner-missing-class'),
        kind: PageBannerKind.info,
        icon: Icons.info,
        shape: PageBannerShape.card,
        title: l10n.contestParticipantsMissingClassTitle(missing.length),
        text: l10n.contestParticipantsMissingClassText,
        child: Wrap(
          spacing: 8,
          children: [
            for (final row in missing.take(5))
              TextButton(
                onPressed: () => onShowClass(row),
                child: Text(l10n.contestParticipantsMissingClass(row.name)),
              ),
          ],
        ),
      ),
    );
  }
  return banners;
}

/// `[1, 2]` → `Rounds 1 and 2`; `[3]` → `Round 3`.
String _rounds(AppLocalizations l10n, List<int> rounds) => rounds.length == 1
    ? l10n.contestParticipantsRound('${rounds.single}')
    : l10n.contestParticipantsRounds(
        ParticipantsController.andList([for (final r in rounds) '$r']),
      );
