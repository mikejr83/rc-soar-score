import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('height penalty', () {
    double penalty(num altitude) => f5jHeightPenalty(
      altitude: altitude,
      referenceHeight: 200,
      minorPerMeter: 0.5,
      majorPerMeter: 3,
    );

    test('uses the minor rate below the reference height', () {
      expect(penalty(100), 50);
    });

    test('uses the minor rate exactly at the reference height', () {
      expect(penalty(200), 100);
    });

    test('adds the major rate for meters above the reference height', () {
      expect(penalty(250), 100 + 50 * 3);
      expect(penalty(201), 100 + 3);
    });
  });

  group('scored flights', () {
    test('flight points plus bonus less the height penalty', () {
      final result = flight({
        'time_flown': 500,
        'launch_height': 100,
      }, landingBonus: 50);

      expect(result.outcome, FlightOutcome.scored);
      expect(result.flightPoints, 500);
      expect(result.heightPenalty, 50);
      expect(result.landingBonus, 50);
      expect(result.rawScore, 500);
    });

    test('above the reference height', () {
      final result = flight({
        'time_flown': 500,
        'launch_height': 250,
      }, landingBonus: 30);

      expect(result.heightPenalty, 250);
      expect(result.rawScore, 500 + 30 - 250);
    });

    test('uses points per second', () {
      final result = flight(
        {'time_flown': 100, 'launch_height': 10},
        overrides: {'points_per_second': 2.0},
      );

      expect(result.flightPoints, 200);
    });

    test('fractional seconds follow the configured precision', () {
      final result = flight(
        {'time_flown': 100.25, 'launch_height': 10},
        overrides: {'fractional_seconds': 2},
      );

      expect(result.flightPoints, 100.25);
      expect(
        issueCodes(() => flight({'time_flown': 100.25, 'launch_height': 10})),
        ['too_precise'],
      );
    });

    test('a height penalty above the points floors the raw score at zero', () {
      final result = flight({
        'time_flown': 100,
        'launch_height': 300,
      }, landingBonus: 20);

      expect(result.heightPenalty, 100 + 300);
      expect(result.outcome, FlightOutcome.scored);
      expect(result.rawScore, 0);
    });

    test('a flight penalty is deducted and cannot make the score negative', () {
      final base = {'time_flown': 500, 'launch_height': 100};

      expect(flight({...base, 'flight_penalty': 30}).rawScore, 500 - 50 - 30);
      expect(flight({...base, 'flight_penalty': 900}).rawScore, 0);
    });

    test('contest overrides change the reference height', () {
      final result = flight(
        {'time_flown': 500, 'launch_height': 150},
        overrides: {'reference_launch_height': 100},
      );

      expect(result.heightPenalty, 100 * 0.5 + 50 * 3);
    });
  });

  group('late landing', () {
    test('keeps the flight points and loses the landing bonus', () {
      final result = flight({
        'time_flown': 599,
        'launch_height': 100,
        'late_landing': true,
      }, landingBonus: 50);

      expect(result.lateLanding, isTrue);
      expect(result.flightPoints, 599);
      expect(result.landingBonus, 0);
      expect(result.rawScore, 599 - 50);
    });
  });

  group('forced zeros', () {
    test('a motor restart scores zero and ignores the other values', () {
      final result = flight({
        'motor_restart': true,
        'time_flown': 600,
        'launch_height': 100,
      }, landingBonus: 50);

      expect(result.outcome, FlightOutcome.zero);
      expect(result.zeroReasons, [F5jZeroReason.motorRestart]);
      expect(result.rawScore, 0);
      expect(result.landingBonus, 0);
      expect(result.nonDroppable, isFalse);
    });

    test('Non-Droppable 0 marks the restart zero as non-droppable', () {
      final result = flight(
        {'motor_restart': true},
        overrides: {'motor_restart_mode': 'non_droppable'},
      );

      expect(result.nonDroppable, isTrue);
      expect(result.motorRestartMode, F5jMotorRestartMode.nonDroppable);
    });

    test('out of bounds scores zero and stays droppable', () {
      final result = flight(
        {'out_of_bounds': true},
        overrides: {'motor_restart_mode': 'non_droppable'},
      );

      expect(result.zeroReasons, [F5jZeroReason.outOfBounds]);
      expect(result.nonDroppable, isFalse);
    });

    test('no altitude recorded scores zero', () {
      final result = flight({'no_altitude_recorded': true, 'time_flown': 500});

      expect(result.outcome, FlightOutcome.zero);
      expect(result.zeroReasons, [F5jZeroReason.noAltitudeRecorded]);
    });

    test('a blank score is an ordinary zero without a reason', () {
      final result = flight({});

      expect(result.outcome, FlightOutcome.zero);
      expect(result.zeroReasons, isEmpty);
      expect(result.rawScore, 0);
    });
  });

  group('group score', () {
    test('a group of F5J flights normalizes to 1000 and rounds once', () {
      final flights = {
        'a': flight({
          'time_flown': 500,
          'launch_height': 100,
        }, landingBonus: 50),
        'b': flight({'time_flown': 400, 'launch_height': 200}),
        'c': flight({'out_of_bounds': true}),
      };

      final scores = calculateGroupScores([
        for (final e in flights.entries) e.value.toPilotRound(e.key),
      ], f5j.options().groupScore);

      expect(scores.map((e) => e.rawScore), [500, 300, 0]);
      expect(scores.map((e) => e.groupScore), [1000, 600, 0]);
    });

    test('a group where every pilot scored zero gives zero', () {
      final scores = calculateGroupScores([
        flight({'motor_restart': true}).toPilotRound('a'),
        flight({'no_altitude_recorded': true}).toPilotRound('b'),
      ], f5j.options().groupScore);

      expect(scores.map((e) => e.groupScore), [0, 0]);
    });
  });
}
