import 'package:flutter/material.dart';

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
/// - scoring pilots with no class (when classes are on).
List<Widget> participantBanners({
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
  final c = controller;
  final banners = <Widget>[];
  if (c.readOnly) {
    banners.add(
      const PageBanner(
        key: ValueKey('banner-read-only'),
        kind: PageBannerKind.neutral,
        icon: Icons.flag,
        shape: PageBannerShape.card,
        text: 'This contest is completed. Participants can’t be changed.',
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
        title: 'Administration is locked. Unlock to change.',
        text:
            'Role, class and team feed the matrix, so they’re off while '
            'locked. Adding and removing people are off too.',
        actionLabel: 'Unlock',
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
        text: 'Add at least 2 scoring pilots before the draw.',
        actionLabel: c.canEdit ? 'Add participant' : null,
        onAction: c.canEdit ? onAdd : null,
      ),
    );
  } else if (!c.drawn && !c.readOnly && pilots == 2) {
    banners.add(
      const PageBanner(
        key: ValueKey('banner-few-pilots'),
        kind: PageBannerKind.status,
        icon: Icons.warning,
        shape: PageBannerShape.card,
        text: 'With fewer than 3 pilots, use 1 group per round.',
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
        title: 'Couldn’t add ${failedAdd.firstName} ${failedAdd.lastName}',
        text:
            '${c.addFailure ?? ''} Nothing was added. Trying again won’t add '
                    'them twice.'
                .trim(),
        actionLabel: 'Try again',
        onAction: onRetryAdd,
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
            ? '${removal.removed.length} of '
                  '${removal.removed.length + removal.refused.length} removed'
            : 'Not removed',
        text: [
          if (removal.removed.isNotEmpty)
            '${ParticipantsController.andList(removal.removed)} '
                '${removal.removed.length == 1 ? 'was' : 'were'} removed from '
                'this contest.',
          for (final refused in removal.refused)
            '${refused.name} wasn’t: ${refused.reason}',
          'To take a pilot with scores out of the results, retire them in '
              'Scoring.',
        ].join(' '),
        actionLabel: 'Open Scoring',
        onAction: onOpenScoring,
        secondaryLabel: 'Dismiss',
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
        title: 'The draw needs redoing',
        text:
            '$names ${c.leftTheDraw.length == 1 ? 'was' : 'were'} in the '
            'draw and ${c.leftTheDraw.length == 1 ? 'has' : 'have'} no scores, '
            'so their places were '
            'removed from it. The groups are not balanced for the pilots '
            'who are left until the matrix is drawn again.',
        actionLabel: 'Redo the draw',
        onAction: onRedoDraw,
        secondaryLabel: 'Dismiss',
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
        title: 'Results are recalculated',
        text: [
          if (c.recalculated.isNotEmpty)
            '${ParticipantsController.andList(c.recalculated)} changed. All '
                'results will be recalculated.',
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
            ? '${placement.name} is in every round'
            : '${placement.name} is not in every round',
        text: [
          if (placement.result.placed.isNotEmpty)
            '${placement.name} was added to the last group that could take '
                'them in ${placement.result.placed.length} '
                'round${placement.result.placed.length == 1 ? '' : 's'}.',
          if (zeroed.isNotEmpty)
            '${_rounds(zeroed)} ${zeroed.length == 1 ? 'was' : 'were'} '
                'already scored, so they got a zero '
                '${zeroed.length == 1 ? 'there' : 'in them'}. Correct the '
                'scores in Scoring if needed.',
          for (final skip in skipped) 'Round ${skip.round}: ${skip.reason}.',
          if (skipped.isNotEmpty)
            'Place them in those rounds from the Matrix page.',
        ].join(' '),
        actionLabel: skipped.isEmpty ? 'Open Scoring' : 'Open Matrix',
        onAction: skipped.isEmpty ? onOpenScoring : onOpenMatrix,
        secondaryLabel: 'Dismiss',
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
        title: '$names ${unplaced.length == 1 ? 'isn’t' : 'aren’t'} placed yet',
        text:
            'Put them in the last group of every round, or place them from the '
            'Matrix page. A redraw is also possible.',
        actionLabel: 'Place in all rounds',
        onAction: onPlaceUnplaced,
        secondaryLabel: 'Open Matrix',
        onSecondary: onOpenMatrix,
      ),
    );
  }
  final missing = c.missingClass;
  if (missing.isNotEmpty && !c.readOnly) {
    banners.add(
      PageBanner(
        key: const ValueKey('banner-missing-class'),
        kind: PageBannerKind.alert,
        icon: Icons.error,
        shape: PageBannerShape.card,
        title:
            '${missing.length} participant${missing.length == 1 ? ' needs' : 's need'} a class',
        text: 'Every scoring pilot needs a class in this contest.',
        child: Wrap(
          spacing: 8,
          children: [
            for (final row in missing.take(5))
              TextButton(
                onPressed: () => onShowClass(row),
                child: Text('${row.name}: enter a class'),
              ),
          ],
        ),
      ),
    );
  }
  return banners;
}

/// `[1, 2]` → `Rounds 1 and 2`; `[3]` → `Round 3`.
String _rounds(List<int> rounds) => rounds.length == 1
    ? 'Round ${rounds.single}'
    : 'Rounds ${ParticipantsController.andList([for (final r in rounds) '$r'])}';
