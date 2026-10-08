import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/matrix/matrix_grid_model.dart';
import 'package:soar_score_contest/services/matrix/matrix_pilot.dart';
import 'package:soar_score_core/soar_score_core.dart';

final _contest = Id.parse('019c0000-0000-7000-8000-000000000017');
final _revision = Id.parse('019c0000-0000-7000-8000-0000000000e1');
final _actor = Id.parse('019c0000-0000-7000-8000-0000000000b1');

Id _id(String kind, int n) =>
    Id.parse('019c0000-0000-7000-8000-$kind${n.toString().padLeft(8, '0')}');

MatrixPilot _pilot(int n) => MatrixPilot(
  participationId: _id('0001', n),
  number: n,
  name: 'Pilot $n',
  role: 'Pilot',
  teamId: null,
);

/// Four pilots, two rounds, two groups: round 1 is {1,2} {3,4}; round 2 is
/// {1,3} {2,4}.
CurrentMatrix _matrix({bool lanes = true}) {
  final rounds = [
    for (var r = 1; r <= 2; r++)
      Round(
        id: _id('0002', r),
        contestId: _contest,
        matrixRevisionId: _revision,
        ordinal: r,
        groupCount: 2,
      ),
  ];
  final groups = [
    for (var r = 1; r <= 2; r++)
      for (var g = 1; g <= 2; g++)
        RoundGroup(
          id: _id('0003', r * 10 + g),
          contestId: _contest,
          roundId: _id('0002', r),
          groupNumber: g,
        ),
  ];
  MatrixAssignment assignment(int round, int group, int pilot, int lane) =>
      MatrixAssignment(
        id: _id('0004', round * 100 + pilot),
        contestId: _contest,
        matrixRevisionId: _revision,
        contestParticipationId: _id('0001', pilot),
        scheduledRoundId: _id('0002', round),
        creditedRoundId: _id('0002', round),
        group: group,
        lane: lanes ? lane : null,
        assignmentType: AssignmentType.original,
        actorId: _actor,
        createdAt: DateTime.utc(2026, 10),
      );
  return CurrentMatrix(
    rounds: rounds,
    groups: groups,
    assignments: [
      assignment(1, 1, 1, 2),
      assignment(1, 1, 2, 1),
      assignment(1, 2, 3, 1),
      assignment(1, 2, 4, 2),
      assignment(2, 1, 1, 1),
      assignment(2, 1, 3, 2),
      assignment(2, 2, 2, 1),
      assignment(2, 2, 4, 2),
    ],
  );
}

void main() {
  final pilots = {for (var n = 1; n <= 4; n++) _id('0001', n): _pilot(n)};

  test('arranges rounds by groups and orders by lane', () {
    final model = MatrixGridModel.of(_matrix(), pilots);
    expect(model.rounds.map((r) => r.ordinal), [1, 2]);
    expect(model.groupCount, 2);
    expect(model.hasLanes, isTrue);
    expect(model.rounds.first.groups.first.map((s) => s.pilot.number), [2, 1]);
  });

  test('without lanes pilots are in number order', () {
    final model = MatrixGridModel.of(_matrix(lanes: false), pilots);
    expect(model.hasLanes, isFalse);
    expect(model.rounds.first.groups.first.map((s) => s.pilot.number), [1, 2]);
  });

  test('every pilot appears exactly once in each round', () {
    final model = MatrixGridModel.of(_matrix(), pilots);
    for (final round in model.rounds) {
      expect(round.pilotCount, 4);
      expect(round.distinctPilots, 4);
    }
  });

  test('counts how often pilots meet', () {
    final model = MatrixGridModel.of(_matrix(), pilots);
    final one = _id('0001', 1);
    expect(model.meetingsBetween(one, _id('0001', 2)), 1);
    expect(model.meetingsBetween(one, _id('0001', 3)), 1);
    expect(model.meetingsBetween(one, _id('0001', 4)), 0);
    final opponents = model.opponentsOf(one);
    expect(opponents.map((o) => o.$1.number), [2, 3, 4]);
    expect(opponents.last.$2, 0);
  });

  test('finds where a pilot flies', () {
    final model = MatrixGridModel.of(_matrix(), pilots);
    expect(model.placeOf(_id('0001', 4), model.rounds.first), (1, 2));
  });

  test('pilot search matches name or number', () {
    final pilot = MatrixPilot(
      participationId: _id('0001', 12),
      number: 12,
      name: 'Ann Lee',
      role: 'Pilot',
      teamId: null,
    );
    expect(pilot.matches('lee'), isTrue);
    expect(pilot.matches('12'), isTrue);
    expect(pilot.matches('1'), isFalse);
    expect(pilot.matches(''), isFalse);
  });
}
