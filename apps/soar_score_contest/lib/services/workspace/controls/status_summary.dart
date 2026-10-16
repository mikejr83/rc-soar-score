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

/// The six independent values of a contest's state, each with its own label
/// so none is read from another: lifecycle, participant scoring,
/// administration lock, publication, public visibility and deletion.
abstract final class StatusSummary {
  static List<StatusValue> of(Contest contest, PublicationFacts publication) {
    final visibility = publication.visibility;
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
            : 'Not published',
      ),
      StatusValue(
        'visibility',
        'Public visibility',
        !publication.isKnown
            ? 'Unknown'
            : visibility == null
            ? 'Not public'
            : _title(visibility.name),
      ),
      // The contest has no pending-delete state yet (#236), so a contest
      // that opens is never scheduled for deletion.
      const StatusValue('deletion', 'Deletion', 'Not scheduled'),
    ];
  }

  static String _title(String name) =>
      '${name[0].toUpperCase()}${name.substring(1)}';
}
