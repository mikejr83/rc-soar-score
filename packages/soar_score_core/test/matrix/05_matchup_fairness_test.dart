import 'package:test/test.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  group('MatrixDrawService - Matchup Fairness', () {
    late MatrixDrawService service;

    setUp(() {
      service = MatrixDrawService(seed: 42);
    });

    test('generates matchup counts', () {
      final result = service.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
        pilotTeams: {},
        groupsPerRound: 3,
        roundsRequested: 2,
        maxIterations: 1000,
      );

      // Should have some matchups recorded
      expect(result.matchupCounts.length, greaterThan(0));
      expect(result.maxDuplicateMatchups, greaterThanOrEqualTo(1));
    });

    test('matchup histogram has correct length and sum', () {
      final result = service.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
        pilotTeams: {},
        groupsPerRound: 3,
        roundsRequested: 2,
        maxIterations: 1000,
      );

      expect(result.matchupHistogram.length, 4);

      final histogramSum = result.matchupHistogram.fold(0, (a, b) => a + b);
      expect(histogramSum, 15);
    });

    test('maxDuplicateMatchups is computed correctly', () {
      final result = service.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
        pilotTeams: {},
        groupsPerRound: 3,
        roundsRequested: 2,
        maxIterations: 1000,
      );

      if (result.matchupCounts.isEmpty) {
        expect(result.maxDuplicateMatchups, 0);
      } else {
        final actualMax = result.matchupCounts.values
            .reduce((a, b) => a > b ? a : b);
        expect(result.maxDuplicateMatchups, actualMax);
      }
    });

    test('matchup counts are accurate - manual verification', () {
      final result = service.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4'],
        pilotTeams: {},
        groupsPerRound: 2,
        roundsRequested: 2,
        maxIterations: 1000,
      );

      final manualCounts = <String, int>{};
      for (final round in result.rounds) {
        for (final group in round.groups) {
          for (int i = 0; i < group.length; i++) {
            for (int j = i + 1; j < group.length; j++) {
              final key = group[i].pilotId.compareTo(group[j].pilotId) < 0
                  ? '${group[i].pilotId}-${group[j].pilotId}'
                  : '${group[j].pilotId}-${group[i].pilotId}';
              manualCounts[key] = (manualCounts[key] ?? 0) + 1;
            }
          }
        }
      }

      expect(result.matchupCounts, manualCounts);
    });

    test('no pilot appears twice in same group same round', () {
      final result = service.generate(
        pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
        pilotTeams: {},
        groupsPerRound: 3,
        roundsRequested: 3,
        maxIterations: 1000,
      );

      for (final round in result.rounds) {
        for (final group in round.groups) {
          final pilotIds = group.map((a) => a.pilotId).toSet();
          expect(pilotIds.length, group.length);
        }
      }
    });
  });
}
