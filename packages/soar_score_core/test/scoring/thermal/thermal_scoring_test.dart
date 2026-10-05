import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('scored flights', () {
    test('flight points plus the landing bonus', () {
      final result = flight({'time_flown': 550}, landingBonus: 20);

      expect(result.outcome, FlightOutcome.scored);
      expect(result.flightPoints, 550);
      expect(result.landingBonus, 20);
      expect(result.rawScore, 570);
      expect(result.overflightSeconds, 0);
    });

    test('the target time scores in full', () {
      expect(flight({'time_flown': 600}).flightPoints, 600);
    });

    test('flying over the target scores like flying under it', () {
      final result = flight({'time_flown': 602});

      expect(result.flightPoints, 598);
      expect(result.overflightSeconds, 2);
      expect(result.rawScore, flight({'time_flown': 598}).rawScore);
    });

    test('an over-flight of exactly a minute is still scored', () {
      final result = flight({'time_flown': 660}, landingBonus: 10);

      expect(result.outcome, FlightOutcome.scored);
      expect(result.flightPoints, 540);
      expect(result.rawScore, 550);
    });

    test('uses points per second and fractional seconds', () {
      final result = flight(
        {'time_flown': 601.5},
        overrides: {'points_per_second': 2.0, 'fractional_seconds': 1},
      );

      expect(result.flightPoints, 2 * 598.5);
    });

    test('uses a contest target time', () {
      final result = flight(
        {'time_flown': 305},
        overrides: {'target_time': 300},
      );

      expect(result.flightPoints, 295);
    });
  });

  group('zero flights', () {
    test('out of bounds is a forced zero that ignores time and landing', () {
      final result = flight({
        'time_flown': 500,
        'out_of_bounds': true,
      }, landingBonus: 20);

      expect(result.outcome, FlightOutcome.zero);
      expect(result.zeroReasons, [ThermalZeroReason.outOfBounds]);
      expect(result.rawScore, 0);
    });

    test('an over-flight of more than a minute is a forced zero', () {
      final result = flight({
        'time_flown': 661,
        'overflight_gt_one_min': true,
      }, landingBonus: 20);

      expect(result.outcome, FlightOutcome.zero);
      expect(result.zeroReasons, [ThermalZeroReason.overflightOverOneMinute]);
      expect(result.rawScore, 0);
    });

    test('a blank score is an ordinary zero without a reason', () {
      final result = flight({});

      expect(result.outcome, FlightOutcome.zero);
      expect(result.zeroReasons, isEmpty);
      expect(result.rawScore, 0);
    });
  });

  group('pilot round', () {
    test('carries flight points and the landing bonus', () {
      final round = flight({
        'time_flown': 602,
      }, landingBonus: 5).toPilotRound('p1');

      expect(round.pilotId, 'p1');
      expect(round.flightPoints, 598);
      expect(round.landingBonus, 5);
    });
  });

  group('defaults', () {
    test('are Normalized, whole seconds and rounding to 1 decimal', () {
      final options = thermal.options();

      expect(options.targetTime.targetTimeSeconds, 600);
      expect(options.targetTime.timeDecimals, 0);
      expect(options.groupScore.mode, GroupScoreMode.normalized);
      expect(options.groupScore.roundingMode, RoundingMode.round);
      expect(options.groupScore.decimalPlaces, 1);
    });

    test('have no motor restart option', () {
      expect(
        thermal.defaultOptions.keys,
        isNot(contains('motor_restart_mode')),
      );
      expect(thermal.field('motor_restart'), isNull);
    });

    test('belong to rules version 1 of Thermal Duration', () {
      expect(thermal.discipline, DisciplineType.thermalDuration);
      expect(thermal.rulesVersion, 1);
    });
  });
}
