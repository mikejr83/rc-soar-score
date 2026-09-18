import 'package:test/test.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  group('MatrixDrawService - Determinism', () {
    test('same seed produces same draw', () {
      final service1 = MatrixDrawService(seed: 42);
      final service2 = MatrixDrawService(seed: 42);

      final result1 = service1.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
        pilotTeams: {},
        groupsPerRound: 3,
        roundsRequested: 2,
        maxIterations: 1000,
      );

      final result2 = service2.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
        pilotTeams: {},
        groupsPerRound: 3,
        roundsRequested: 2,
        maxIterations: 1000,
      );

      // Group assignments should be identical
      for (int r = 0; r < result1.rounds.length; r++) {
        for (int g = 0; g < result1.rounds[r].groups.length; g++) {
          final group1 = result1.rounds[r].groups[g].map((a) => a.pilotId).toSet();
          final group2 = result2.rounds[r].groups[g].map((a) => a.pilotId).toSet();
          expect(group1, group2);
        }
      }
    });

    test('different seeds produce different draws', () {
      final service1 = MatrixDrawService(seed: 42);
      final service2 = MatrixDrawService(seed: 99);

      final result1 = service1.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
        pilotTeams: {},
        groupsPerRound: 3,
        roundsRequested: 2,
        maxIterations: 1000,
      );

      final result2 = service2.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
        pilotTeams: {},
        groupsPerRound: 3,
        roundsRequested: 2,
        maxIterations: 1000,
      );

      // At least one group assignment should differ
      bool differs = false;
      for (int r = 0; r < result1.rounds.length && !differs; r++) {
        for (int g = 0; g < result1.rounds[r].groups.length && !differs; g++) {
          final group1 = result1.rounds[r].groups[g].map((a) => a.pilotId).toSet();
          final group2 = result2.rounds[r].groups[g].map((a) => a.pilotId).toSet();
          if (group1 != group2) differs = true;
        }
      }
      expect(differs, true);
    });

    test('both draws with different seeds are valid', () {
      final service1 = MatrixDrawService(seed: 42);
      final service2 = MatrixDrawService(seed: 99);

      for (final service in [service1, service2]) {
        final result = service.generate(
          pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
          pilotTeams: {},
          groupsPerRound: 3,
          roundsRequested: 2,
          maxIterations: 1000,
        );

        // Verify all pilots assigned in each round
        for (final round in result.rounds) {
          final allPilots = <String>{};
          for (final group in round.groups) {
            for (final a in group) {
              allPilots.add(a.pilotId);
            }
          }
          expect(allPilots.length, 6);
        }
      }
    });
  });
}
