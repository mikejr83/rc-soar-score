import 'package:test/test.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  group('MatrixDrawService - Validation and Error Handling', () {
    late MatrixDrawService service;

    setUp(() {
      service = MatrixDrawService(seed: 42);
    });

    test('throws for insufficient groups for team protection', () {
      expect(
        () => service.generate(
          pilotIds: ['p1', 'p2', 'p3', 'p4'],
          pilotTeams: {'p1': 1, 'p2': 1, 'p3': 2, 'p4': 2},
          groupsPerRound: 1,
          roundsRequested: 1,
          maxIterations: 1000,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('fewer pilots than groups produces some empty groups', () {
      final result = service.generate(
        pilotIds: ['p1', 'p2', 'p3'],
        pilotTeams: {},
        groupsPerRound: 5,
        roundsRequested: 1,
        maxIterations: 1000,
      );

      expect(result.rounds.length, 1);

      // With 3 pilots and baseGroupSize=0, only 3 groups get a pilot
      final occupiedGroups = result.rounds[0].groups
          .where((g) => g.length > 0)
          .length;
      expect(occupiedGroups, 3);

      // Total pilots assigned
      final allPilots = <String>{};
      for (final group in result.rounds[0].groups) {
        for (final a in group) {
          allPilots.add(a.pilotId);
        }
      }
      expect(allPilots.length, 3);
    });
  });
}
