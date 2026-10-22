import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/controls/status_summary.dart';
import 'package:soar_score_contest/services/workspace/publication_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

Contest _contest({
  LifecycleState state = LifecycleState.running,
  ScoringAccess access = ScoringAccess.open,
  AdminLock lock = AdminLock.locked,
  int? hiddenThrough,
  bool archived = false,
}) => Contest(
  id: Id.parse('019c0000-0000-7000-8000-000000000017'),
  name: 'Test',
  startDateTime: DateTime.utc(2026, 10, 17),
  endDateTime: DateTime.utc(2026, 10, 18),
  timezone: 'UTC',
  lifecycleState: state,
  scoringAccess: access,
  adminLock: lock,
  resultsHiddenThroughRound: hiddenThrough,
  resultsHiddenAt: hiddenThrough == null
      ? null
      : DateTime.utc(2026, 10, 17, 11),
  localArchive: archived,
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
);

final _now = DateTime.utc(2026, 10, 17, 12);

Map<String, String> _values(
  Contest contest,
  PublicationFacts publication, {
  DateTime? now,
}) => {
  for (final value in StatusSummary.of(contest, publication, now: now ?? _now))
    value.label: value.value,
};

void main() {
  test('has the independent labelled values, in order', () {
    final values = StatusSummary.of(
      _contest(),
      PublicationFacts.notPublished,
      now: _now,
    );
    expect(values.map((v) => v.label), [
      'Lifecycle',
      'Participant scoring',
      'Administration',
      'Publication',
      'Results hiding',
      'Local archive',
    ]);
  });

  test('has no deletion status', () {
    final labels = StatusSummary.of(
      _contest(),
      PublicationFacts.notPublished,
      now: _now,
    ).map((v) => v.label);
    expect(labels, isNot(contains('Deletion')));
  });

  test('reads each value from its own field', () {
    expect(_values(_contest(), PublicationFacts.notPublished), {
      'Lifecycle': 'Running',
      'Participant scoring': 'Open',
      'Administration': 'Locked',
      'Publication': 'Unpublished',
      'Results hiding': 'Off',
      'Local archive': 'Not archived',
    });
    expect(
      _values(
        _contest(
          state: LifecycleState.completed,
          access: ScoringAccess.closed,
          lock: AdminLock.unlocked,
          hiddenThrough: 3,
          archived: true,
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
        'Results hiding': 'Hidden through round 3',
        'Local archive': 'Archived',
      },
    );
  });

  test('an unreadable publication is unknown, not unpublished', () {
    final values = _values(_contest(), PublicationFacts.unknown);
    expect(values['Publication'], 'Unknown');
    expect(values.containsKey('Public visibility'), isFalse);
  });

  test('unsupported publishing is not available, not unknown', () {
    final values = _values(_contest(), PublicationFacts.unsupported);
    expect(values['Publication'], 'Not available');
    expect(values.containsKey('Public visibility'), isFalse);
  });

  test('results hiding that has run its 24 hours reads as off', () {
    final contest = _contest(hiddenThrough: 2);
    final hiddenAt = contest.resultsHiddenAt!;
    String hiding(DateTime now) => _values(
      contest,
      PublicationFacts.notPublished,
      now: now,
    )['Results hiding']!;

    expect(
      hiding(hiddenAt.add(const Duration(hours: 23, minutes: 59))),
      'Hidden through round 2',
    );
    expect(hiding(hiddenAt.add(const Duration(hours: 24))), 'Off');
    expect(hiding(hiddenAt.add(const Duration(days: 3))), 'Off');
  });
}
