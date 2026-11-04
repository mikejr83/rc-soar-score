import 'package:soar_score_core/soar_score_core.dart';

import '../workspace_facts.dart';
import 'checklist_item.dart';

/// The rows that are not needed to run the contest.
abstract final class OptionalChecklistRows {
  /// Participant numbers, which the draw assigns. `null` when the
  /// configuration turns participant numbers off, so the row is not shown.
  static ChecklistItem? participantNumbers(WorkspaceFacts facts) {
    final options = facts.options;
    if (options != null && !options.participantNumbersEnabled) {
      return null;
    }
    final range = facts.participantNumbers;
    if (range == null) {
      return const ChecklistItem(
        id: ChecklistItemId.participantNumbers,
        status: ChecklistStatus.todo,
        title: 'Participant numbers',
        detail: 'Assigned automatically when the matrix is drawn.',
        target: ChecklistTarget.participants,
      );
    }
    return ChecklistItem(
      id: ChecklistItemId.participantNumbers,
      status: ChecklistStatus.done,
      title: 'Participant numbers assigned',
      detail: '${range.lowest}–${range.highest}, assigned at the draw.',
      target: ChecklistTarget.participants,
    );
  }

  /// Publication. A failed read is "unknown", never "not published".
  static ChecklistItem publication(WorkspaceFacts facts) {
    final publication = facts.publication;
    if (publication.needsSignIn) {
      return const ChecklistItem(
        id: ChecklistItemId.publication,
        status: ChecklistStatus.unknown,
        title: 'Sign in to publish',
        detail:
            'Publishing goes through the hosted server and needs a sign-in.',
        target: ChecklistTarget.publicationControl,
      );
    }
    if (!publication.isKnown) {
      return const ChecklistItem(
        id: ChecklistItemId.publication,
        status: ChecklistStatus.unknown,
        title: 'Publication status unavailable',
        detail: 'It could not be read. Reload to try again.',
        target: ChecklistTarget.publicationControl,
      );
    }
    if (!publication.supported) {
      return const ChecklistItem(
        id: ChecklistItemId.publication,
        status: ChecklistStatus.done,
        title: 'Publication not supported',
        detail: 'This server does not publish contests.',
        target: ChecklistTarget.publicationControl,
      );
    }
    if (!publication.isPublished) {
      return const ChecklistItem(
        id: ChecklistItemId.publication,
        status: ChecklistStatus.todo,
        title: 'Not published',
        detail: 'You can publish before the contest or after it.',
        target: ChecklistTarget.publicationControl,
      );
    }
    final visibility = switch (publication.visibility) {
      PublicationVisibility.unlisted => 'Unlisted',
      PublicationVisibility.public => 'Public',
      PublicationVisibility.delisted => 'Delisted',
      null => 'Published',
    };
    return ChecklistItem(
      id: ChecklistItemId.publication,
      status: ChecklistStatus.done,
      title: 'Published',
      detail: '$visibility on the public site.',
      target: ChecklistTarget.publicationControl,
    );
  }

  /// Whether pilots and helpers can enter their own scores.
  static ChecklistItem scoringAccess(WorkspaceFacts facts) {
    if (facts.contest.scoringAccess == ScoringAccess.open) {
      return const ChecklistItem(
        id: ChecklistItemId.scoringAccess,
        status: ChecklistStatus.done,
        title: 'Participant scoring open',
        detail: 'Pilots and helpers can enter their own scores.',
        target: ChecklistTarget.scoringControl,
      );
    }
    return const ChecklistItem(
      id: ChecklistItemId.scoringAccess,
      status: ChecklistStatus.todo,
      title: 'Participant scoring closed',
      detail: 'Open it when pilots should enter their own scores.',
      target: ChecklistTarget.scoringControl,
    );
  }
}
