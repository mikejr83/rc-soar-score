import 'package:test/test.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  group('MatrixDrawService - Basic Draw Generation', () {
    late MatrixDrawService service;

    setUp(() {
      service = MatrixDrawService(seed: 42);
    });

    test('minimum viable draw - 4 pilots, 2 groups, 1 round', () {
      final result = service.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4'],
        pilotTeams: {},
        groupsPerRound: 2,
        roundsRequested: 1,
        maxIterations: 1000,
      );

      expect(result.rounds.length, 1);
      expect(result.rounds[0].groups.length, 2);

      // Each group should have 2 pilots (balanced)
      expect(result.rounds[0].groups[0].length, 2);
      expect(result.rounds[0].groups[1].length, 2);

      // All 4 pilots should be assigned exactly once
      final allPilots = <String>{};
      for (final group in result.rounds[0].groups) {
        for (final assignment in group) {
          allPilots.add(assignment.pilotId);
        }
      }
      expect(allPilots.length, 4);
      expect(allPilots.contains('p1'), true);
      expect(allPilots.contains('p2'), true);
      expect(allPilots.contains('p3'), true);
      expect(allPilots.contains('p4'), true);

      // Lane numbers should be 1 and 2 within each group
      for (final group in result.rounds[0].groups) {
        final lanes = group.map((a) => a.laneNumber).toSet();
        expect(lanes.length, 2);
        expect(lanes.contains(1), true);
        expect(lanes.contains(2), true);
      }
    });

    test('multi-round draw - 6 pilots, 3 groups, 4 rounds', () {
      final result = service.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
        pilotTeams: {},
        groupsPerRound: 3,
        roundsRequested: 4,
        maxIterations: 1000,
      );

      expect(result.rounds.length, 4);

      for (final round in result.rounds) {
        expect(round.groups.length, 3);
        expect(round.groups[0].length, 2);
        expect(round.groups[1].length, 2);
        expect(round.groups[2].length, 2);

        // All 6 pilots assigned in this round
        final allPilots = <String>{};
        for (final group in round.groups) {
          for (final assignment in group) {
            allPilots.add(assignment.pilotId);
          }
        }
        expect(allPilots.length, 6);
      }
    });

    test('uneven division - 7 pilots, 3 groups, 1 round', () {
      final result = service.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7'],
        pilotTeams: {},
        groupsPerRound: 3,
        roundsRequested: 1,
        maxIterations: 1000,
      );

      expect(result.rounds.length, 1);
      expect(result.rounds[0].groups.length, 3);

      // Group sizes should be 3, 2, 2 (or equivalent)
      final groupSizes = result.rounds[0].groups
          .map((g) => g.length)
          .toList()
        ..sort();
      expect(groupSizes, [2, 2, 3]);

      // All 7 pilots assigned
      final allPilots = <String>{};
      for (final group in result.rounds[0].groups) {
        for (final assignment in group) {
          allPilots.add(assignment.pilotId);
        }
      }
      expect(allPilots.length, 7);

      // Lane numbers within each group are unique
      for (final group in result.rounds[0].groups) {
        final lanes = group.map((a) => a.laneNumber).toList()..sort();
        expect(lanes.length, lanes.toSet().length);
        // Lane numbers should start at 1 and be sequential
        expect(lanes, List.generate(lanes.length, (i) => i + 1));
      }
    });

    test('single group - 5 pilots, 1 group, 1 round', () {
      final result = service.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5'],
        pilotTeams: {},
        groupsPerRound: 1,
        roundsRequested: 1,
        maxIterations: 1000,
      );

      expect(result.rounds.length, 1);
      expect(result.rounds[0].groups.length, 1);
      expect(result.rounds[0].groups[0].length, 5);

      // Lane numbers should be 1-5
      final lanes = result.rounds[0].groups[0]
          .map((a) => a.laneNumber)
          .toList()
        ..sort();
      expect(lanes, [1, 2, 3, 4, 5]);
    });
  });
}
