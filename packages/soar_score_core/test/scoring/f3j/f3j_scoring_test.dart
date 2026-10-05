import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('scored flights', () {
    test('flight points plus the landing bonus', () {
      final result = flight({'time_flown': 540.5}, landingBonus: 20);

      expect(result.outcome, FlightOutcome.scored);
      expect(result.flightPoints, 540.5);
      expect(result.landingBonus, 20);
      expect(result.latePenalty, 0);
      expect(result.rawScore, 560.5);
    });

    test('uses points per second', () {
      final result = flight(
        {'time_flown': 100},
        overrides: {'points_per_second': 2.0},
      );

      expect(result.flightPoints, 200);
    });

    test('contest overrides change the working time', () {
      final result = flight(
        {'time_flown': 899},
        overrides: {'working_time': 900},
      );

      expect(result.flightPoints, 899);
    });
  });

  group('late landing', () {
    test('keeps flight points, loses the bonus and takes 30 points', () {
      final result = flight({
        'time_flown': 599.9,
        'late_landing': true,
      }, landingBonus: 20);

      expect(result.lateLanding, isTrue);
      expect(result.flightPoints, closeTo(599.9, 1e-9));
      expect(result.landingBonus, 0);
      expect(result.latePenalty, 30);
      expect(result.rawScore, closeTo(569.9, 1e-9));
    });

    test('the penalty cannot make the raw score negative', () {
      final result = flight({'time_flown': 10, 'late_landing': true});

      expect(result.outcome, FlightOutcome.scored);
      expect(result.rawScore, 0);
    });

    test('the penalty stays with the round as a deduction', () {
      final round = flight({'time_flown': 500, 'late_landing': true})
          .toPilotRound('a');

      expect(round.deductions, 30);
      expect(round.rawScore, 470);
    });
  });

  group('forced zeros', () {
    test('out of bounds scores zero and ignores the other values', () {
      final result = flight({
        'out_of_bounds': true,
        'time_flown': 500,
      }, landingBonus: 20);

      expect(result.outcome, FlightOutcome.zero);
      expect(result.zeroReasons, [F3jZeroReason.outOfBounds]);
      expect(result.rawScore, 0);
      expect(result.landingBonus, 0);
    });

    test('late landing with out of bounds is just the zero', () {
      final result = flight({
        'out_of_bounds': true,
        'late_landing': true,
        'time_flown': 599,
      });

      expect(result.zeroReasons, [F3jZeroReason.outOfBounds]);
      expect(result.lateLanding, isFalse);
      expect(result.latePenalty, 0);
      expect(result.rawScore, 0);
    });

    test('a blank score is an ordinary zero without a reason', () {
      final result = flight({});

      expect(result.outcome, FlightOutcome.zero);
      expect(result.zeroReasons, isEmpty);
      expect(result.rawScore, 0);
    });
  });

  group('group score', () {
    test('Normalized, truncated to 1 decimal once at the end', () {
      final flights = {
        'a': flight({'time_flown': 500}, landingBonus: 20),
        'b': flight({'time_flown': 333.3}),
        'c': flight({'out_of_bounds': true}),
      };

      final scores = calculateGroupScores([
        for (final e in flights.entries) e.value.toPilotRound(e.key),
      ], f3j.options().groupScore);

      expect(scores.map((e) => e.rawScore), [520, 333.3, 0]);
      expect(scores.map((e) => e.groupScore), [1000, 640.9, 0]);
    });
  });
}
