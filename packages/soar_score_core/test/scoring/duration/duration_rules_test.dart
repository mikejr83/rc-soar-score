import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  group('DurationRules.flightPoints', () {
    final rules = DurationRules(
      pointsPerSecond: 2,
      workingTimeSeconds: 600,
      timeDecimals: 1,
    );

    test('is points per second times time flown', () {
      expect(rules.flightPoints(0), 0);
      expect(rules.flightPoints(300.5), 601);
    });

    test('keeps the points unrounded', () {
      final fine = DurationRules(
        pointsPerSecond: 0.5,
        workingTimeSeconds: 600,
        timeDecimals: 3,
      );

      expect(fine.flightPoints(10.001), closeTo(5.0005, 1e-12));
    });

    test('accepts the largest time below the working time', () {
      expect(rules.flightPoints(599.9), closeTo(1199.8, 1e-9));
    });

    test('rejects a time at or above the working time', () {
      expect(
        () => rules.flightPoints(600),
        throwsA(isA<ScoringValidationError>()),
      );
      expect(
        () => rules.flightPoints(700),
        throwsA(isA<ScoringValidationError>()),
      );
    });

    test('rejects a negative or non-finite time', () {
      expect(
        () => rules.flightPoints(-1),
        throwsA(isA<ScoringValidationError>()),
      );
      expect(
        () => rules.flightPoints(double.nan),
        throwsA(isA<ScoringValidationError>()),
      );
    });

    test('rejects more decimals than the configured precision', () {
      expect(
        () => rules.flightPoints(10.25),
        throwsA(
          isA<ScoringValidationError>().having(
            (e) => e.issues.single.code,
            'code',
            'too_precise',
          ),
        ),
      );
    });

    test('supports zero to three decimals', () {
      expect(
        DurationRules(workingTimeSeconds: 10, timeDecimals: 0).flightPoints(5),
        5,
      );
      expect(
        () => DurationRules(
          workingTimeSeconds: 10,
          timeDecimals: 0,
        ).flightPoints(5.5),
        throwsA(isA<ScoringValidationError>()),
      );
      expect(
        () => DurationRules(workingTimeSeconds: 10, timeDecimals: 4),
        throwsArgumentError,
      );
    });

    test('rejects invalid rules', () {
      expect(() => DurationRules(workingTimeSeconds: 0), throwsArgumentError);
      expect(
        () => DurationRules(pointsPerSecond: -1, workingTimeSeconds: 10),
        throwsArgumentError,
      );
    });
  });
}
