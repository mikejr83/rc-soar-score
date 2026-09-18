import 'package:test/test.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  group('ScoringEngine - Group Normalization', () {
    late ScoringEngine engine;
    late ContestScoringConfig config;

    setUp(() {
      engine = ScoringEngine();
      config = ContestScoringConfig(
        discipline: Discipline.ales,
        targetTimeSeconds: 480,
        pointsPerSecond: 1.0,
        groupScoreType: GroupScoreType.time,
      );
    });

    test('highest score gets 1000', () {
      final flights = [
        AlesFlight(id: 'f1', pilotId: 'p1', durationSeconds: 477),
        AlesFlight(id: 'f2', pilotId: 'p2', durationSeconds: 470),
        AlesFlight(id: 'f3', pilotId: 'p3', durationSeconds: 472),
      ];

      final results = engine.normalizeGroupScores(flights, config);
      expect(results.scores.length, 3);
      expect(results.scores[0].groupScore, 1000.0);
      expect(results.scores[1].groupScore, closeTo(985.32, 0.01));
      expect(results.scores[2].groupScore, closeTo(989.52, 0.01));
    });

    test('tied highest scores both get 1000', () {
      final flights = [
        AlesFlight(id: 'f1', pilotId: 'p1', durationSeconds: 477),
        AlesFlight(id: 'f2', pilotId: 'p2', durationSeconds: 477),
        AlesFlight(id: 'f3', pilotId: 'p3', durationSeconds: 470),
      ];

      final results = engine.normalizeGroupScores(flights, config);
      expect(results.scores[0].groupScore, 1000.0);
      expect(results.scores[1].groupScore, 1000.0);
      expect(results.scores[2].groupScore, closeTo(985.32, 0.01));
    });

    test('zero score in group stays at 0', () {
      final flights = [
        AlesFlight(id: 'f1', pilotId: 'p1', durationSeconds: 477),
        AlesFlight(
          id: 'f2',
          pilotId: 'p2',
          durationSeconds: 470,
          zeroReason: const OutOfBoundsLanding(),
        ),
        AlesFlight(id: 'f3', pilotId: 'p3', durationSeconds: 472),
      ];

      final results = engine.normalizeGroupScores(flights, config);
      expect(results.scores[0].groupScore, 1000.0);
      expect(results.scores[1].groupScore, 0);
      expect(results.scores[2].groupScore, closeTo(989.52, 0.01));
    });

    test('all zero scores result in all zeros', () {
      final flights = [
        AlesFlight(
          id: 'f1',
          pilotId: 'p1',
          durationSeconds: 477,
          zeroReason: const OutOfBoundsLanding(),
        ),
        AlesFlight(
          id: 'f2',
          pilotId: 'p2',
          durationSeconds: 470,
          zeroReason: const MotorRestart(),
        ),
      ];

      final results = engine.normalizeGroupScores(flights, config);
      expect(results.scores[0].groupScore, 0);
      expect(results.scores[1].groupScore, 0);
    });
  });
}