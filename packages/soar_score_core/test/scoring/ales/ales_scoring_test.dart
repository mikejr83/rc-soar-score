import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final ales = AlesProfile();
  const target480 = {'target_time': 480};

  AlesFlightResult flight(
    Map<String, Object?> components, {
    Map<String, Object?> overrides = target480,
    double landingBonus = 0,
  }) => ales.calculate(
    components,
    overrides: overrides,
    landingBonus: landingBonus,
  );

  List<String> codes(void Function() run) {
    try {
      run();
    } on ScoringValidationError catch (e) {
      return [for (final i in e.issues) i.code];
    }
    return const [];
  }

  group('flight points', () {
    test('at or under the target score the time flown', () {
      expect(flight({'time_flown': 477}).flightPoints, 477);
      expect(flight({'time_flown': 480}).flightPoints, 480);
    });

    test('over the target scores like the same seconds under it', () {
      final result = flight({'time_flown': 483});
      expect(result.flightPoints, 477);
      expect(result.overflightSeconds, 3);
    });

    test('602 s on a 600 s target gives 598', () {
      expect(
        flight({'time_flown': 602}, overrides: const {}).flightPoints,
        598,
      );
    });

    test('fractional seconds over the target are charged in full', () {
      final result = flight(
        {'time_flown': 481.2},
        overrides: {'target_time': 480, 'fractional_seconds': 1},
      );
      expect(result.flightPoints, closeTo(478.8, 1e-9));
    });

    test('points per second scale the flight points', () {
      final result = flight(
        {'time_flown': 483},
        overrides: {'target_time': 480, 'points_per_second': 2},
      );
      expect(result.flightPoints, 954);
    });

    test('the landing bonus is kept for an in-window over-flight', () {
      final result = flight({'time_flown': 483}, landingBonus: 25);
      expect(result.landingBonus, 25);
      expect(result.rawScore, 502);
    });
  });

  group('the one-minute boundary', () {
    test('exactly one minute past the target is scorable', () {
      final result = flight({'time_flown': 540}, landingBonus: 10);
      expect(result.outcome, FlightOutcome.scored);
      expect(result.flightPoints, 420);
      expect(result.landingBonus, 10);
    });

    test('just over one minute needs the over-flight flag', () {
      expect(codes(() => flight({'time_flown': 541})), ['required']);
    });

    test('the flag with a time inside the window is rejected', () {
      expect(
        codes(() => flight({'time_flown': 540, 'overflight_gt_one_min': true})),
        ['not_allowed'],
      );
    });

    test('the flag zeroes the flight and the landing', () {
      final result = flight({
        'time_flown': 600,
        'overflight_gt_one_min': true,
      }, landingBonus: 50);
      expect(result.outcome, FlightOutcome.zero);
      expect(result.zeroReasons, [AlesZeroReason.overflightOverOneMinute]);
      expect(result.rawScore, 0);
    });

    test('the flag alone, without a time, is a forced zero', () {
      final result = flight({'overflight_gt_one_min': true});
      expect(result.zeroReasons, [AlesZeroReason.overflightOverOneMinute]);
    });
  });

  group('forced and blank zeros', () {
    test('motor restart zeroes the flight and the landing', () {
      final result = flight({
        'time_flown': 470,
        'motor_restart': true,
      }, landingBonus: 50);
      expect(result.outcome, FlightOutcome.zero);
      expect(result.zeroReasons, [AlesZeroReason.motorRestart]);
      expect(result.flightPoints, 0);
      expect(result.landingBonus, 0);
    });

    test('out of bounds zeroes the flight and the landing', () {
      final result = flight({
        'time_flown': 470,
        'out_of_bounds': true,
      }, landingBonus: 50);
      expect(result.zeroReasons, [AlesZeroReason.outOfBounds]);
      expect(result.rawScore, 0);
    });

    test('a time far past the target is ignored under a motor restart', () {
      final result = flight({'time_flown': 900, 'motor_restart': true});
      expect(result.zeroReasons, [AlesZeroReason.motorRestart]);
    });

    test('two zero flags are rejected', () {
      expect(
        codes(() => flight({'motor_restart': true, 'out_of_bounds': true})),
        ['exclusive_status'],
      );
    });

    test('a blank score is an ordinary zero with no reason', () {
      final result = flight(const {});
      expect(result.outcome, FlightOutcome.zero);
      expect(result.zeroReasons, isEmpty);
    });

    test('a negative landing bonus is rejected', () {
      expect(
        () => flight({'time_flown': 400}, landingBonus: -1),
        throwsArgumentError,
      );
    });

    test('too many decimals are rejected, not rounded', () {
      expect(codes(() => flight({'time_flown': 400.5})), ['too_precise']);
    });
  });

  group('the worked example end to end (target 480 s, 1 point/s)', () {
    final flights = {
      'A': flight({'time_flown': 477}, landingBonus: 30),
      'B': flight({'time_flown': 483}, landingBonus: 25),
      'C': flight({'time_flown': 470}, landingBonus: 50),
    };

    List<double> scores(GroupScoreMode mode) => [
      for (final e in calculateGroupScores([
        for (final f in flights.entries) f.value.toPilotRound(f.key),
      ], GroupScoreOptions(mode: mode, decimalPlaces: 0)))
        e.groupScore,
    ];

    test('A and B tie on 477 flight points', () {
      expect(flights['A']!.flightPoints, flights['B']!.flightPoints);
      expect(flights['C']!.flightPoints, 470);
    });

    test('Time mode: 1030, 1025, 1035', () {
      expect(scores(GroupScoreMode.time), [1030, 1025, 1035]);
    });

    test('Normalized mode: 975, 965, 1000', () {
      expect(scores(GroupScoreMode.normalized), [975, 965, 1000]);
    });
  });

  group('group edge cases', () {
    test('an over-flight zero among normal scores counts as raw 0', () {
      final scores = calculateGroupScores([
        flight({'time_flown': 470}, landingBonus: 10).toPilotRound('A'),
        flight({'time_flown': 600, 'overflight_gt_one_min': true})
            .toPilotRound('B'),
      ], GroupScoreOptions(mode: GroupScoreMode.time, decimalPlaces: 0));
      expect(scores.map((s) => s.groupScore), [1010, 0]);
    });

    test('an all-zero group scores zero without dividing', () {
      final scores = calculateGroupScores([
        flight(const {}).toPilotRound('A'),
        flight({'out_of_bounds': true}).toPilotRound('B'),
      ], GroupScoreOptions());
      expect(scores.map((s) => s.groupScore), [0, 0]);
    });

    test('a group where every pilot over-flies in the window', () {
      final scores = calculateGroupScores([
        flight({'time_flown': 483}, landingBonus: 30).toPilotRound('A'),
        flight({'time_flown': 486}, landingBonus: 20).toPilotRound('B'),
      ], GroupScoreOptions(mode: GroupScoreMode.time, decimalPlaces: 0));
      // 477 and 474 flight points; the bonus is added after normalizing.
      expect(scores.map((s) => s.groupScore), [1030, 1014]);
    });
  });
}
