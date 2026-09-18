import 'package:test/test.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  group('ScoringEngine - ALES', () {
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

    test('pilot flies under target time', () {
      final flight = AlesFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 477,
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 477.0);
      expect(result.isZeroScore, false);
    });

    test('pilot flies exactly target time', () {
      final flight = AlesFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 480,
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 480.0);
    });

    test('pilot over-flies by 3 seconds', () {
      final flight = AlesFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 483,
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 477.0);
    });

    test('out of bounds landing results in 0', () {
      final flight = AlesFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 477,
        zeroReason: const OutOfBoundsLanding(),
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 0);
      expect(result.isZeroScore, true);
      expect(result.zeroReason, 'Out of bounds landing');
    });

    test('motor restart results in 0', () {
      final flight = AlesFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 477,
        zeroReason: const MotorRestart(),
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 0);
      expect(result.isZeroScore, true);
    });

    test('over-flight over 1 minute results in 0', () {
      final flight = AlesFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 477,
        zeroReason: const OverFlightOverOneMinute(),
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 0);
      expect(result.isZeroScore, true);
    });

    test('different points per second', () {
      final config2 = ContestScoringConfig(
        discipline: Discipline.ales,
        targetTimeSeconds: 480,
        pointsPerSecond: 2.0,
      );

      final flight = AlesFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 477,
      );

      final result = engine.computeRawScore(flight, config2);
      expect(result.rawScore, 954.0);
    });
  });
}