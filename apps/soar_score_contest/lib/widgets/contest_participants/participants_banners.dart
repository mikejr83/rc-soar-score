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
            'Place them in a group from the Matrix page. A redraw is also '
            'possible.',
        actionLabel: 'Open Matrix',
        onAction: onOpenMatrix,
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
