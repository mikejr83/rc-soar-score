import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/matrix/move_plan.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/matrix_test_support.dart';

/// The fixture: round 1 is {1,2} {3,4}, round 2 is {1,3} {2,4}; pilots 1 and
/// 3 are teammates.
MovePlan? _plan({
  CurrentMatrix? matrix,
  Id? assignment,
  Set<(int, int)> scored = const {},
  bool teams = true,
  bool protection = false,
  bool retired = false,
  Set<(int, int)> locked = const {},
  RoundStatus round2 = RoundStatus.open,
}) {
  final server = MatrixServer(
    matrix: matrix ?? drawnMatrix(lockedGroups: locked, round2Status: round2),
  );
  server.scoredAssignments.addAll(scored);
  return MovePlan.of(
    matrix: server.matrix!,
    scores: server.matrix!.rounds.isEmpty
        ? ContestScores()
        : server.scoresForTest(),
    assignmentId: assignment ?? assignmentId(1, 1),
    teamOf: {
      participationId(1): Id.parse('019c0000-0000-7000-8000-000600000001'),
      participationId(3): Id.parse('019c0000-0000-7000-8000-000600000001'),
      participationId(2): Id.parse('019c0000-0000-7000-8000-000600000002'),
      participationId(4): Id.parse('019c0000-0000-7000-8000-000600000002'),
    },
    teamsEnabled: teams,
    teamProtection: protection,
    pilotRetired: retired,
  );
}

MoveTarget _target(MovePlan plan, int round, int group) => plan.targets
    .singleWhere((t) => t.round.ordinal == round && t.group == group);

void main() {
  test('no plan when the assignment is not in the matrix', () {
    expect(_plan(assignment: Id.create()), isNull);
  });

  test('no plan when there is no current round', () {
    final matrix = drawnMatrix();
    final empty = CurrentMatrix(
      revision: matrix.revision,
      assignments: matrix.assignments,
      groups: matrix.groups,
    );
    expect(_plan(matrix: empty), isNull);
  });

  test('lists every group of every current round', () {
    final plan = _plan()!;
    expect(plan.rounds.map((r) => r.ordinal), [1, 2]);
    expect(plan.targets, hasLength(4));
    expect(plan.scored, isFalse);
    expect(plan.sourceBlock, isNull);
  });

  test('the current group and a group held in another round are blocked', () {
    final plan = _plan()!;
    expect(_target(plan, 1, 1).block, MoveBlockKind.currentGroup);
    expect(_target(plan, 2, 1).block, MoveBlockKind.alreadyInGroup);
    expect(_target(plan, 1, 2).block, isNull);
    expect(_target(plan, 2, 2).block, isNull);
  });

  test('a teammate makes a group not ideal, or blocked under protection', () {
    expect(_target(_plan()!, 1, 2).notIdeal, [NotIdealReason.teammate]);
    expect(_target(_plan()!, 2, 2).recommended, isTrue);
    expect(
      _target(_plan(protection: true)!, 1, 2).block,
      MoveBlockKind.teamProtection,
    );
    expect(_target(_plan(teams: false)!, 1, 2).recommended, isTrue);
  });

  test('scores make a group not ideal and a full round completed', () {
    final plan = _plan(scored: {(2, 2), (2, 4)})!;
    expect(_target(plan, 2, 2).notIdeal, [NotIdealReason.hasScores]);
    final full = _plan(scored: {(2, 1), (2, 2), (2, 3), (2, 4)})!;
    expect(_target(full, 2, 2).notIdeal, [
      NotIdealReason.hasScores,
      NotIdealReason.roundCompleted,
    ]);
  });

  test('locked groups and rounds are blocked', () {
    final plan = _plan(locked: {(1, 2)}, round2: RoundStatus.locked)!;
    expect(_target(plan, 1, 2).block, MoveBlockKind.groupLocked);
    expect(_target(plan, 2, 2).block, MoveBlockKind.roundLocked);
  });

  test('a locked group or score of the pilot, or a retired pilot, blocks', () {
    expect(_plan(locked: {(1, 1)})!.sourceBlock, SourceBlockKind.groupLocked);
    expect(_plan(retired: true)!.sourceBlock, SourceBlockKind.pilotRetired);
  });

  test('a scored source is flagged', () {
    expect(_plan(scored: {(1, 1)})!.scored, isTrue);
  });
}
