import 'package:test/test.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  group('ScoringEngine - F5J', () {
    late ScoringEngine engine;
    late ContestScoringConfig config;

    setUp(() {
      engine = ScoringEngine();
      config = ContestScoringConfig(
        discipline: Discipline.f5j,
        targetTimeSeconds: 600,
        f5jWorkingTimeSeconds: 600,
        pointsPerSecond: 1.0,
        groupScoreType: GroupScoreType.normalized,
        totalScoreRounding: TotalScoreRounding.round1,
        f5jMotorRestart: MotorRestartMode.allowed,
      );
    });

    test('basic scoring', () {
      final flight = F5JFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 590,
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 630.0); // 590 + 40 landing bonus
    });

    test('time stops at working time end', () {
      final flight = F5JFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 650,
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 640.0); // 600 + 40 landing bonus
    });

    test('motor restart results in 0', () {
      final flight = F5JFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 590,
        zeroReason: const MotorRestart(),
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 0);
      expect(result.isZeroScore, true);
    });

    test('out of bounds results in 0', () {
      final flight = F5JFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 590,
        zeroReason: const OutOfBoundsLanding(),
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 0);
      expect(result.isZeroScore, true);
    });
  });
}