import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

MatrixAssignment make({
  AssignmentType type = AssignmentType.original,
  Id? credited,
  int sequence = 1,
  Id? source,
  Id? reFlight,
  String? reason,
  ExistingScoreHandling handling = ExistingScoreHandling.none,
  int? resetRevision,
  int group = 1,
  int? lane,
}) => MatrixAssignment(
  id: exampleId(1),
  contestId: exampleId(2),
  matrixRevisionId: exampleId(3),
  contestParticipationId: exampleId(4),
  scheduledRoundId: exampleId(5),
  creditedRoundId: credited ?? exampleId(5),
  group: group,
  lane: lane,
  flightSequence: sequence,
  assignmentType: type,
  sourceAssignmentId: source,
  reFlightId: reFlight,
  actorId: exampleId(6),
  reason: reason,
  existingScoreHandling: handling,
  resetScoreRevision: resetRevision,
  createdAt: t0,
);

void main() {
  group('MatrixAssignment', () {
    test('round trips and is contest data without a revision', () {
      final a = make();
      final json = a.toJson();
      expect(json['assignment_type'], 'Original');
      expect(json['existing_score_handling'], 'None');
      expect(json.containsKey('revision'), isFalse);
      expect(MatrixAssignment.fromJson(json), a);
      expect(a.syncScope, SyncScope.contest);
    });

    test('an Original row has no source, re-flight or other credit', () {
      expect(() => make(source: exampleId(9)), throwsArgumentError);
      expect(() => make(reFlight: exampleId(9)), throwsArgumentError);
      expect(() => make(credited: exampleId(9)), throwsArgumentError);
      expect(() => make(sequence: 2), throwsArgumentError);
    });

    test('a LateAdd can be credited to another round but needs a reason', () {
      final a = make(
        type: AssignmentType.lateAdd,
        credited: exampleId(9),
        reason: 'Joined after the draw',
      );
      expect(a.toJson()['assignment_type'], 'LateAdd');
      expect(
        () => make(type: AssignmentType.lateAdd, reason: ' '),
        throwsArgumentError,
      );
      expect(
        () => make(
          type: AssignmentType.lateAdd,
          reason: 'x',
          source: exampleId(9),
        ),
        throwsArgumentError,
      );
    });

    test('a Moved row has a source and a reason, no re-flight', () {
      final a = make(
        type: AssignmentType.moved,
        source: exampleId(9),
        reason: 'Frequency clash',
      );
      expect(MatrixAssignment.fromJson(a.toJson()), a);
      expect(
        () => make(type: AssignmentType.moved, reason: 'x'),
        throwsArgumentError,
      );
      expect(
        () => make(
          type: AssignmentType.moved,
          source: exampleId(9),
          reFlight: exampleId(8),
          reason: 'x',
        ),
        throwsArgumentError,
      );
    });

    test('a Reflight row has a source, a re-flight and a reason', () {
      final a = make(
        type: AssignmentType.reflight,
        source: exampleId(9),
        reFlight: exampleId(8),
        sequence: 2,
        reason: 'Obstructed landing area',
      );
      expect(a.flightSequence, 2);
      expect(
        () => make(
          type: AssignmentType.reflight,
          source: exampleId(9),
          reason: 'x',
        ),
        throwsArgumentError,
      );
    });

    test('a reset needs the replaced score revision and a Moved row', () {
      final moved = make(
        type: AssignmentType.moved,
        source: exampleId(9),
        reason: 'x',
        handling: ExistingScoreHandling.reset,
        resetRevision: 2,
      );
      expect(moved.toJson()['existing_score_handling'], 'Reset');
      expect(
        () => make(handling: ExistingScoreHandling.reset, resetRevision: 1),
        throwsArgumentError,
      );
      expect(() => make(resetRevision: 1), throwsArgumentError);
    });

    test('group, lane and sequence start at 1', () {
      expect(() => make(group: 0), throwsArgumentError);
      expect(() => make(lane: 0), throwsArgumentError);
      expect(make(lane: 3).lane, 3);
    });
  });
}
