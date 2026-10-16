import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/controls/status_summary.dart';
import 'package:soar_score_contest/services/workspace/publication_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

Contest _contest({
  LifecycleState state = LifecycleState.running,
  ScoringAccess access = ScoringAccess.open,
  AdminLock lock = AdminLock.locked,
}) => Contest(
  id: Id.parse('019c0000-0000-7000-8000-000000000017'),
  name: 'Test',
  startDateTime: DateTime.utc(2026, 10, 17),
  endDateTime: DateTime.utc(2026, 10, 18),
  timezone: 'UTC',
  lifecycleState: state,
  scoringAccess: access,
  adminLock: lock,
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
);

Map<String, String> _values(Contest contest, PublicationFacts publication) => {
  for (final value in StatusSummary.of(contest, publication))
    value.label: value.value,
};

void main() {
  test('has the six independent labelled values, in order', () {
    final values = StatusSummary.of(_contest(), PublicationFacts.notPublished);
    expect(values.map((v) => v.label), [
      'Lifecycle',
      'Participant scoring',
      'Administration',
      'Publication',
      'Public visibility',
      'Deletion',
    ]);
  });

  test('reads each value from its own field', () {
    expect(_values(_contest(), PublicationFacts.notPublished), {
      'Lifecycle': 'Running',
      'Participant scoring': 'Open',
      'Administration': 'Locked',
      'Publication': 'Not published',
      'Public visibility': 'Not public',
      'Deletion': 'Not scheduled',
    });
    expect(
      _values(
        _contest(
          state: LifecycleState.completed,
          access: ScoringAccess.closed,
          lock: AdminLock.unlocked,
        ),
        const PublicationFacts(
          isPublished: true,
          visibility: PublicationVisibility.unlisted,
        ),
      ),
      {
        'Lifecycle': 'Completed',
        'Participant scoring': 'Closed',
        'Administration': 'Unlocked',
        'Publication': 'Published',
        'Public visibility': 'Unlisted',
        'Deletion': 'Not scheduled',
      },
    );
  });

  test('an unreadable publication is unknown, not unpublished', () {
    final values = _values(_contest(), PublicationFacts.unknown);
    expect(values['Publication'], 'Unknown');
    expect(values['Public visibility'], 'Unknown');
  });
}
