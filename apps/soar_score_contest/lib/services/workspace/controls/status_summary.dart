import 'package:soar_score_core/soar_score_core.dart';

import '../publication_facts.dart';

/// One independent labelled value of the status summary.
class StatusValue {
  const StatusValue(this.id, this.label, this.value);

  /// Stable id for widget keys.
  final String id;
  final String label;
  final String value;
}

/// The contest's independent state values, each with its own label so none
/// is read from another: lifecycle, participant scoring, administration
/// lock, publication, public visibility (once published), results hiding and
/// local archive. There is no deletion status
/// (`plan/data-model/follow-ups.md`).
abstract final class StatusSummary {
  /// [now] decides whether results hiding has run its 24 hours.
  static List<StatusValue> of(
    Contest contest,
    PublicationFacts publication, {
    required DateTime now,
  }) {
    final visibility = publication.visibility;
    final hiddenThrough = contest.hidingExpiredAt(now)
        ? null
        : contest.resultsHiddenThroughRound;
    return [
      StatusValue(
        'lifecycle',
        'Lifecycle',
        _title(contest.lifecycleState.name),
      ),
      StatusValue(
        'scoring',
        'Participant scoring',
        contest.scoringAccess == ScoringAccess.open ? 'Open' : 'Closed',
      ),
      StatusValue(
        'administration',
        'Administration',
        contest.adminLock == AdminLock.locked ? 'Locked' : 'Unlocked',
      ),
      StatusValue(
        'publication',
        'Publication',
        !publication.isKnown
            ? 'Unknown'
            : publication.isPublished
            ? 'Published'
            : 'Unpublished',
      ),
      // Visibility belongs to the publication record, so it shows only once
      // there is one.
      if (publication.isKnown && publication.isPublished && visibility != null)
        StatusValue('visibility', 'Public visibility', _title(visibility.name)),
      StatusValue(
        'results',
        'Results hiding',
        hiddenThrough == null ? 'Off' : 'Hidden through round $hiddenThrough',
      ),
      StatusValue(
        'archive',
        'Local archive',
        contest.localArchive ? 'Archived' : 'Not archived',
      ),
    ];
  }

  static String _title(String name) =>
      '${name[0].toUpperCase()}${name.substring(1)}';
}
