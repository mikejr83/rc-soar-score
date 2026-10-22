import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/workspace/transition_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/matrix_test_support.dart';

final _director = Id.parse('019c0000-0000-7000-8000-0000000000b1');
final _other = Id.parse('019c0000-0000-7000-8000-0000000000b2');

AuditEventDto _event(ContestAction action, DateTime at, [Id? actor]) =>
    AuditEventDto(
      id: Id.create(),
      entityType: 'Contest',
      entityId: contestId,
      action: AuditAction.stateTransition,
      transition: action,
      actorId: actor ?? _director,
      authority: Authority.director,
      serverTimestamp: at,
      outcome: AuditOutcome.success,
    );

void main() {
  final t1 = DateTime.utc(2026, 10, 18, 9);
  final t2 = DateTime.utc(2026, 10, 18, 10);
  final t3 = DateTime.utc(2026, 10, 18, 11);

  test('reads the completion time of a completed contest', () {
    final facts = TransitionFacts.of(
      matrixContest(state: LifecycleState.completed),
      [_event(ContestAction.complete, t2), _event(ContestAction.lock, t1)],
    );

    expect(facts.completedAt, t2);
    expect(facts.lockedAt, isNull);
  });

  test('takes the newest lock while locked, and "you" for the actor', () {
    final contest = matrixContest(lock: AdminLock.locked);
    final events = [
      _event(ContestAction.lock, t3),
      _event(ContestAction.unlock, t2),
      _event(ContestAction.lock, t1, _other),
    ];

    final mine = TransitionFacts.of(
      contest,
      events,
      actingAccountId: _director.value,
    );
    final someoneElse = TransitionFacts.of(
      contest,
      events,
      actingAccountId: _other.value,
    );

    expect(mine.lockedAt, t3);
    expect(mine.lockedBy, 'you');
    expect(someoneElse.lockedAt, t3);
    expect(someoneElse.lockedBy, isNull);
  });

  test('ignores events that no longer describe the contest', () {
    final facts = TransitionFacts.of(matrixContest(), [
      _event(ContestAction.complete, t1),
      _event(ContestAction.lock, t2),
    ]);

    expect(facts, TransitionFacts.unknown);
  });

  test('a contest changed before the trail has no facts', () {
    final facts = TransitionFacts.of(
      matrixContest(state: LifecycleState.completed, lock: AdminLock.locked),
      const [],
    );

    expect(facts, TransitionFacts.unknown);
  });
}
