import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final rules = TargetTimeRules(
    pointsPerSecond: 2,
    targetTimeSeconds: 600,
    timeDecimals: 1,
  );

  group('TargetTimeRules.flightPoints', () {
    test('is points per second times time when under the target', () {
      expect(rules.flightPoints(0), 0);
      expect(rules.flightPoints(598), 1196);
      expect(rules.flightPoints(300.5), 601);
    });

    test('scores the target time in full', () {
      expect(rules.flightPoints(600), 1200);
    });

    test('scores an over-flight like the same time under the target', () {
      expect(rules.flightPoints(602), rules.flightPoints(598));
      expect(
        rules.flightPoints(602.5),
        closeTo(rules.flightPoints(597.5), 1e-9),
      );
    });

    test('scores 602 s on a 600 s target as 598 s at one point per second', () {
      final plain = TargetTimeRules(targetTimeSeconds: 600);

      expect(plain.flightPoints(602), 598);
    });

    test('never drops below zero', () {
      expect(rules.flightPoints(1200), 0);
      expect(rules.flightPoints(1500), 0);
    });

    test('rejects a negative or non-finite time', () {
      for (final bad in [-1.0, double.nan, double.infinity]) {
        expect(
          () => rules.flightPoints(bad),
          throwsA(isA<ScoringValidationError>()),
        );
      }
    });

    test('rejects more decimals than allowed', () {
      expect(
        () => rules.flightPoints(10.25),
        throwsA(isA<ScoringValidationError>()),
      );
    });
  });

  group('TargetTimeRules over-flight', () {
    test('measures the seconds past the target', () {
      expect(rules.overflightSeconds(590), 0);
      expect(rules.overflightSeconds(600), 0);
      expect(rules.overflightSeconds(612.5), 12.5);
    });

    test('is over the limit only beyond 60 s', () {
      expect(rules.isOverflightOverLimit(660), isFalse);
      expect(rules.isOverflightOverLimit(660.1), isTrue);
    });

    test('takes the limit as an option', () {
      final strict = TargetTimeRules(
        targetTimeSeconds: 600,
        overflightLimitSeconds: 30,
      );

      expect(strict.isOverflightOverLimit(631), isTrue);
    });
  });

  group('TargetTimeRules construction', () {
    test('rejects bad values', () {
      expect(() => TargetTimeRules(targetTimeSeconds: 0), throwsArgumentError);
      expect(
        () => TargetTimeRules(targetTimeSeconds: 600, pointsPerSecond: -1),
        throwsArgumentError,
      );
      expect(
        () => TargetTimeRules(targetTimeSeconds: 600, timeDecimals: 4),
        throwsArgumentError,
      );
      expect(
        () =>
            TargetTimeRules(targetTimeSeconds: 600, overflightLimitSeconds: -1),
        throwsArgumentError,
      );
    });

    test('compares by value', () {
      expect(
        TargetTimeRules(targetTimeSeconds: 600),
        TargetTimeRules(targetTimeSeconds: 600),
      );
    });
  });
}
