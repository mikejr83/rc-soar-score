import 'package:test/test.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  group('ScoringEngine - Thermal Duration', () {
    late ScoringEngine engine;
    late ContestScoringConfig config;

    setUp(() {
      engine = ScoringEngine();
      config = ContestScoringConfig(
        discipline: Discipline.thermalDuration,
        targetTimeSeconds: 600,
        pointsPerSecond: 1.0,
        groupScoreType: GroupScoreType.normalized,
      );
    });

    test('basic scoring under target time', () {
      final flight = ThermalDurationFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 595,
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 595.0);
    });

    test('over-flight penalty', () {
      final flight = ThermalDurationFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 605,
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 595.0);
    });

    test('out of bounds results in 0', () {
      final flight = ThermalDurationFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 595,
        zeroReason: const OutOfBoundsLanding(),
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 0);
      expect(result.isZeroScore, true);
    });
  });
}