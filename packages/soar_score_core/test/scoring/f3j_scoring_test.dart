import 'package:test/test.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  group('ScoringEngine - F3J', () {
    late ScoringEngine engine;
    late ContestScoringConfig config;

    setUp(() {
      engine = ScoringEngine();
      config = ContestScoringConfig(
        discipline: Discipline.f3j,
        targetTimeSeconds: 300,
        f3jWorkingTimeSeconds: 300,
        pointsPerSecond: 1.0,
        fractionalSeconds: 1,
        groupScoreType: GroupScoreType.normalized,
        totalScoreRounding: TotalScoreRounding.truncate1,
      );
    });

    test('basic scoring', () {
      final flight = F3JFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 295.5,
        landingBonus: 0,
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 295.5);
    });

    test('time stops at working time end', () {
      final flight = F3JFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 310,
        landingBonus: 0,
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 300.0);
    });

    test('out of bounds results in 0', () {
      final flight = F3JFlight(
        id: 'flight-1',
        pilotId: 'pilot-1',
        durationSeconds: 295,
        landingBonus: 0,
        zeroReason: const OutOfBoundsLanding(),
      );

      final result = engine.computeRawScore(flight, config);
      expect(result.rawScore, 0);
      expect(result.isZeroScore, true);
    });
  });
}
