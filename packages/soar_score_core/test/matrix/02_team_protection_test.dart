import 'package:test/test.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  group('MatrixDrawService - Team Protection', () {
    late MatrixDrawService service;

    setUp(() {
      service = MatrixDrawService(seed: 42);
    });

    test('validation rejects insufficient groups for team protection', () {
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

    test('validation passes with sufficient groups', () {
      expect(
        () => service.generate(
          pilotIds: ['p1', 'p2', 'p3', 'p4'],
          pilotTeams: {'p1': 1, 'p2': 1, 'p3': 2, 'p4': 2},
          groupsPerRound: 2,
          roundsRequested: 1,
          maxIterations: 1000,
        ),
        returnsNormally,
      );
    });

    test('error message includes team size information', () {
      try {
        service.generate(
          pilotIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'],
          pilotTeams: {
            'p1': 1, 'p2': 1, 'p3': 1, 'p4': 1,
            'p5': 2, 'p6': 2, 'p7': 2, 'p8': 2,
          },
          groupsPerRound: 2,
          roundsRequested: 1,
          maxIterations: 1000,
        );
        fail('Expected StateError');
      } on StateError catch (e) {
        expect(e.message, contains('groupsPerRound'));
        expect(e.message, contains('4'));
      }
    });

    test('single large team - 4 pilots all on team 1, 4 groups', () {
      expect(
        () => service.generate(
          pilotIds: ['p1', 'p2', 'p3', 'p4'],
          pilotTeams: {'p1': 1, 'p2': 1, 'p3': 1, 'p4': 1},
          groupsPerRound: 4,
          roundsRequested: 1,
          maxIterations: 1000,
        ),
        returnsNormally,
      );
    });
  });
}
