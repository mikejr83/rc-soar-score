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
}) => AuditEventDto(
  id: Id.create(),
  entityType: 'Contest',
  entityId: contestId,
  action: kind,
  transition: action,
  actorId: actor ?? _me,
  authority: Authority.director,
  serverTimestamp: at,
  outcome: outcome,
);

void main() {
  final t1 = DateTime.utc(2026, 10, 18, 9);
  final t2 = DateTime.utc(2026, 10, 18, 10);

  test('keeps the order and marks the acting account as you', () {
    final facts = ActivityFacts.of([
      _event(t2, action: ContestAction.lock),
      _event(t1, action: ContestAction.openScoring, actor: _other),
    ], actingAccountId: _me.value);

    expect(facts.failed, isFalse);
    expect(facts.entries, [
      ActivityEntry(kind: ActivityKind.lock, byYou: true, at: t2),
      ActivityEntry(kind: ActivityKind.openScoring, byYou: false, at: t1),
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

  test('orders events stored in the same instant by id, newest first', () {
    final save = _event(t1, kind: AuditAction.configurationSaved);
    final draw = _event(t1, kind: AuditAction.matrixDrawn);

    expect(
      ActivityFacts.of([save, draw]).entries.map((e) => e.kind),
      ActivityFacts.of([draw, save]).entries.map((e) => e.kind),
    );
  });
}
