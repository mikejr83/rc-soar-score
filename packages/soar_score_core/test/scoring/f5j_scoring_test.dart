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
        durationSeconds: 595,
        landingBonus: 50,
        launchAltitudeMeters: 163
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 563.5); // 595 + 50 landing bonus - 81.5 altitude penalty
    });

    test('over reference altitude', () {
      final flight = F5JFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 598,
        landingBonus: 50,
        launchAltitudeMeters: 213
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 509.0); // 598 + 50 landing bonus - 139.0 altitude penalty
    });

    test('motor restart results in 0', () {
      final flight = F5JFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 590,
        zeroReason: const MotorRestart(),
        landingBonus: null,
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
        landingBonus: null,
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 0);
      expect(result.isZeroScore, true);
    });
  });
}
