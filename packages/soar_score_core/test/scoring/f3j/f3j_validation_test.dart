import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('F3jProfile', () {
    test('is registered by discipline and rules version', () {
      final registry = ScoringProfileRegistry([f3j]);

      expect(registry.resolve(DisciplineType.f3j, 1), same(f3j));
    });

    test('has the F3J defaults', () {
      final options = f3j.options();

      expect(options.duration.workingTimeSeconds, 600);
      expect(options.duration.pointsPerSecond, 1);
      expect(options.duration.timeDecimals, 1);
      expect(options.groupScore.mode, GroupScoreMode.normalized);
      expect(options.groupScore.roundingMode, RoundingMode.truncate);
      expect(options.groupScore.decimalPlaces, 1);
    });

    test('exposes status flags, inputs and the derived raw score', () {
      expect(f3j.field('late_landing')!.kind, ScoreFieldKind.statusFlag);
      expect(f3j.field('out_of_bounds')!.kind, ScoreFieldKind.statusFlag);
      expect(f3j.field('time_flown')!.kind, ScoreFieldKind.input);
      expect(f3j.field('raw_score')!.acceptedInSubmission, isFalse);
    });
  });

  group('invalid submissions', () {
    test('time at the working time is rejected', () {
      expect(issueCodes(() => flight({'time_flown': 600})), ['out_of_range']);
    });

    test('the largest time below the working time is accepted', () {
      expect(flight({'time_flown': 599.9}).flightPoints, closeTo(599.9, 1e-9));
    });

    test('a negative time is rejected', () {
      expect(issueCodes(() => flight({'time_flown': -1})), ['out_of_range']);
    });

    test('more decimals than the contest allows are rejected', () {
      expect(issueCodes(() => flight({'time_flown': 100.55})), ['too_precise']);
    });

    test('an F5J-only field is unknown', () {
      expect(issueCodes(() => flight({'launch_height': 100})), [
        'unknown_field',
      ]);
    });

    test('the raw score cannot be submitted', () {
      expect(issueCodes(() => flight({'raw_score': 100})), ['derived_field']);
    });

    test('an unknown option override is rejected', () {
      expect(
        issueCodes(
          () => flight(
            {'time_flown': 1},
            overrides: {'reference_launch_height': 1},
          ),
        ),
        ['unknown_option'],
      );
    });

    test('a bad option value is rejected', () {
      expect(issueCodes(() => f3j.options({'working_time': 0})), [
        'invalid_option',
      ]);
    });

    test('a negative landing bonus is rejected', () {
      expect(
        () => flight({'time_flown': 1}, landingBonus: -1),
        throwsArgumentError,
      );
    });
  });
}
