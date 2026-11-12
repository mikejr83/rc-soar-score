import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/workspace/activity/activity_entry.dart';
import 'package:soar_score_contest/services/workspace/activity/activity_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/matrix_test_support.dart';

final _me = Id.parse('019c0000-0000-7000-8000-0000000000b1');
final _other = Id.parse('019c0000-0000-7000-8000-0000000000b2');

AuditEventDto _event(
  DateTime at, {
  ContestAction? action,
  AuditAction kind = AuditAction.stateTransition,
  AuditOutcome outcome = AuditOutcome.success,
  Id? actor,
  Id? id,
  String? reason,
}) => AuditEventDto(
  id: id ?? Id.create(),
  entityType: 'Contest',
  entityId: contestId,
  action: kind,
  transition: action,
  actorId: actor ?? _me,
  authority: Authority.director,
  serverTimestamp: at,
  outcome: outcome,
  reason: reason,
);

void main() {
  final t1 = DateTime.utc(2026, 10, 18, 9);
  final t2 = DateTime.utc(2026, 10, 18, 10);

  test('keeps the order and marks the acting account as you', () {
    final lock = _event(t2, action: ContestAction.lock);
    final open = _event(t1, action: ContestAction.openScoring, actor: _other);
    final facts = ActivityFacts.of([lock, open], actingAccountId: _me.value);

    expect(facts.failed, isFalse);
    expect(facts.entries, [
      ActivityEntry(
        id: lock.id.value,
        kind: ActivityKind.lock,
        byYou: true,
        at: t2,
        actorId: _me.value,
      ),
      ActivityEntry(
        id: open.id.value,
        kind: ActivityKind.openScoring,
        byYou: false,
        at: t1,
        actorId: _other.value,
      ),
    ]);
  });

  test('names no actor without an acting account', () {
    final facts = ActivityFacts.of([
      _event(t1, action: ContestAction.complete),
    ]);

    expect(facts.entries.single.byYou, isFalse);
  });

  test('skips rejected events, unknown transitions and other actions', () {
    final facts = ActivityFacts.of([
      _event(t2, action: ContestAction.lock, outcome: AuditOutcome.rejected),
      _event(t2),
      _event(t2, kind: AuditAction.scoreAttempt),
      _event(t1, kind: AuditAction.publicationAttempt),
    ]);

    expect(facts.entries.map((e) => e.kind), [ActivityKind.publication]);
  });

  test('shows only the newest few', () {
    final facts = ActivityFacts.of([
      for (var i = 0; i < 9; i++) _event(t1, action: ContestAction.unlock),
    ]);

    expect(facts.entries, hasLength(ActivityFacts.shown));
  });

  test('lists configuration saves and matrix draws', () {
    final facts = ActivityFacts.of([
      _event(t1, kind: AuditAction.configurationSaved),
      _event(t2, kind: AuditAction.matrixDrawn),
    ], actingAccountId: _me.value);

    expect(facts.entries.map((e) => e.kind), [
      ActivityKind.matrixDrawn,
      ActivityKind.configurationSaved,
    ]);
    expect(facts.entries.every((e) => e.byYou), isTrue);
  });

  test('lists score corrections and retirements with pilot and round', () {
    final facts = ActivityFacts.of([
      _event(
        t1,
        kind: AuditAction.scoreAttempt,
        reason:
            'correction: pilot 12; round 3; group 2; points 82.4 → 95.1; '
            'reason: Timer misread',
      ),
      _event(t2, reason: 'retire: pilot 7; from round 2 → 4'),
      _event(
        DateTime.utc(2026, 10, 18, 11),
        reason:
            'reinstate: pilot 7; '
            'was retired from round 4',
      ),
    ]);

    expect(facts.entries.map((e) => (e.kind, e.pilot, e.round)), [
      (ActivityKind.pilotReinstated, 7, 4),
      (ActivityKind.pilotRetired, 7, 4),
      (ActivityKind.scoreCorrected, 12, 3),
    ]);
  });

  test('skips events whose text is not a correction or a retirement', () {
    final facts = ActivityFacts.of([
      _event(t1, kind: AuditAction.scoreAttempt, reason: 'something else'),
      _event(t2, reason: 'lock: AdminLock Unlocked → Locked'),
    ]);

    expect(facts.entries, isEmpty);
  });

  test('orders events stored in the same instant by id, larger first', () {
    final older = _event(
      t1,
      kind: AuditAction.configurationSaved,
      id: Id.parse('019c0000-0000-7000-8000-0000000000c1'),
    );
    final newer = _event(
      t1,
      kind: AuditAction.matrixDrawn,
      id: Id.parse('019c0000-0000-7000-8000-0000000000c2'),
    );
    const expected = [
      ActivityKind.matrixDrawn,
      ActivityKind.configurationSaved,
    ];

    expect(
      ActivityFacts.of([older, newer]).entries.map((e) => e.kind),
      expected,
    );
    expect(
      ActivityFacts.of([newer, older]).entries.map((e) => e.kind),
      expected,
    );
  });
}
