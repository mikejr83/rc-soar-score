import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('F5jProfile', () {
    test('is registered by discipline and rules version', () {
      final registry = ScoringProfileRegistry([f5j]);

      expect(registry.resolve(DisciplineType.f5j, 1), same(f5j));
    });

    test('has the F5J defaults', () {
      final options = f5j.options();

      expect(options.duration.workingTimeSeconds, 900);
      expect(options.duration.pointsPerSecond, 1);
      expect(options.duration.timeDecimals, 0);
      expect(options.referenceLaunchHeight, 200);
      expect(options.minorPenaltyPerMeter, 0.5);
      expect(options.majorPenaltyPerMeter, 3);
      expect(options.motorRestartMode, F5jMotorRestartMode.allowed);
      expect(options.groupScore.mode, GroupScoreMode.normalized);
      expect(options.groupScore.roundingMode, RoundingMode.round);
      expect(options.groupScore.decimalPlaces, 1);
    });

    test('exposes status flags, inputs and the derived raw score', () {
      expect(f5j.field('late_landing')!.kind, ScoreFieldKind.statusFlag);
      expect(f5j.field('time_flown')!.kind, ScoreFieldKind.input);
      expect(f5j.field('raw_score')!.acceptedInSubmission, isFalse);
    });
  });

  group('invalid submissions', () {
    test('time at the working time is rejected', () {
      expect(
        issueCodes(() => flight({'time_flown': 900, 'launch_height': 100})),
        ['out_of_range'],
      );
    });

    test('the largest time below the working time is accepted', () {
      final result = flight(
        {'time_flown': 899.999, 'launch_height': 100, 'late_landing': true},
        overrides: {'fractional_seconds': 3},
      );

      expect(result.flightPoints, closeTo(899.999, 1e-9));
    });

    test('a negative time is rejected', () {
      expect(
        issueCodes(() => flight({'time_flown': -1, 'launch_height': 100})),
        ['out_of_range'],
      );
    });

    test('an altitude of zero is rejected', () {
      expect(
        issueCodes(() => flight({'time_flown': 100, 'launch_height': 0})),
        ['out_of_range'],
      );
    });

    test('a time without a launch height is rejected', () {
      expect(issueCodes(() => flight({'time_flown': 100})), ['required']);
    });

    test('a launch height without a time is rejected', () {
      expect(issueCodes(() => flight({'launch_height': 100})), ['required']);
    });

    test('no altitude recorded excludes the other statuses', () {
      for (final other in ['motor_restart', 'out_of_bounds', 'late_landing']) {
        expect(
          issueCodes(() => flight({'no_altitude_recorded': true, other: true})),
          ['exclusive_status'],
          reason: other,
        );
      }
    });

    test('a motor restart is rejected when the mode is Not Allowed', () {
      expect(
        issueCodes(
          () => flight(
            {'motor_restart': true},
            overrides: {'motor_restart_mode': 'not_allowed'},
          ),
        ),
        ['not_allowed'],
      );
    });

    test('derived and unknown fields are rejected', () {
      expect(issueCodes(() => flight({'raw_score': 5})), ['derived_field']);
      expect(issueCodes(() => flight({'nope': 5})), ['unknown_field']);
    });

    test('a negative flight penalty is rejected', () {
      expect(
        issueCodes(
          () => flight({
            'time_flown': 100,
            'launch_height': 100,
            'flight_penalty': -1,
          }),
        ),
        ['out_of_range'],
      );
    });
  });

  group('option overrides', () {
    test('an unknown option is rejected', () {
      expect(issueCodes(() => flight({}, overrides: {'nope': 1})), [
        'unknown_option',
      ]);
    });

    test('invalid option values are rejected', () {
      for (final bad in [
        {'working_time': 0},
        {'working_time': 3600},
        {'points_per_second': 0},
        {'fractional_seconds': 4},
        {'reference_launch_height': 0},
        {'minor_penalty_per_meter': -1},
        {'motor_restart_mode': 'sometimes'},
        {'group_score_mode': 'Best'},
        {'decimal_places': 5},
      ]) {
        expect(issueCodes(() => flight({}, overrides: bad)), [
          'invalid_option',
        ], reason: '$bad');
      }
    });

    test('group score options can be overridden', () {
      final options = f5j.options({
        'group_score_mode': 'Time',
        'rounding_mode': 'Truncate',
        'decimal_places': 0,
      });

      expect(options.groupScore.mode, GroupScoreMode.time);
      expect(options.groupScore.roundingMode, RoundingMode.truncate);
      expect(options.groupScore.decimalPlaces, 0);
    });
  });
}
