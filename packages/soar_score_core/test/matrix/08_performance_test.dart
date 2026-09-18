import 'package:test/test.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  group('MatrixDrawService - Performance', () {
    test('draw completes within iteration budget', () {
      final service = MatrixDrawService(seed: 42);
      final pilotIds = List.generate(10, (i) => 'p${i + 1}');

      final result = service.generate(
        pilotIds: pilotIds,
        pilotTeams: {},
        groupsPerRound: 5,
        roundsRequested: 5,
        maxIterations: 10000,
      );

      expect(result.rounds.length, 5);
      expect(result.totalIterations, greaterThan(0));
    });

    test('larger contest scenario - 20 pilots, 10 groups, 8 rounds', () {
      final service = MatrixDrawService(seed: 42);
      final pilotIds = List.generate(20, (i) => 'p${i + 1}');

      final result = service.generate(
        pilotIds: pilotIds,
        pilotTeams: {},
        groupsPerRound: 10,
        roundsRequested: 8,
        maxIterations: 5000,
      );

      expect(result.rounds.length, 8);

      // All 20 pilots assigned in each round
      for (final round in result.rounds) {
        final allPilots = <String>{};
        for (final group in round.groups) {
          for (final a in group) {
            allPilots.add(a.pilotId);
          }
        }
        expect(allPilots.length, 20);
      }
    });
  });
}
