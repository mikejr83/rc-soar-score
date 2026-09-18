import 'package:test/test.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  group('MatrixDrawService - Lane Assignment', () {
    late MatrixDrawService service;

    setUp(() {
      service = MatrixDrawService(seed: 42);
    });

    test('lane uniqueness within group - 6 pilots, 3 groups', () {
      final result = service.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
        pilotTeams: {},
        groupsPerRound: 3,
        roundsRequested: 1,
        maxIterations: 1000,
      );

      for (final group in result.rounds[0].groups) {
        final lanes = group.map((a) => a.laneNumber).toSet();
        expect(lanes.length, group.length);
      }
    });

    test('lane numbers respect group size - 8 pilots, 3 groups', () {
      final result = service.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'],
        pilotTeams: {},
        groupsPerRound: 3,
        roundsRequested: 1,
        maxIterations: 1000,
      );

      for (final group in result.rounds[0].groups) {
        final lanes = group.map((a) => a.laneNumber).toList()..sort();
        // Lanes should be sequential starting at 1
        expect(lanes, List.generate(lanes.length, (i) => i + 1));
      }
    });

    test('lane fairness across rounds - 6 pilots, 3 groups, 4 rounds', () {
      final result = service.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
        pilotTeams: {},
        groupsPerRound: 3,
        roundsRequested: 4,
        maxIterations: 1000,
      );

      // Check that lane distribution is recorded
      for (final pilotId in ['p1', 'p2', 'p3', 'p4', 'p5', 'p6']) {
        expect(result.laneAssignments.containsKey(pilotId), true);
        final pilotLanes = result.laneAssignments[pilotId]!;
        final totalFlights = pilotLanes.values.fold(0, (a, b) => a + b);
        expect(totalFlights, 4);
      }
    });
  });
}
