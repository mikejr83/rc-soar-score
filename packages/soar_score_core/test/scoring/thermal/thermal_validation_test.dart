import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('mutually exclusive statuses', () {
    test('out of bounds and over-flight cannot be combined', () {
      expect(
        issueCodes(
          () => flight({
            'time_flown': 700,
            'out_of_bounds': true,
            'overflight_gt_one_min': true,
          }),
        ),
        contains('exclusive_status'),
      );
    });

    test('the over-flight flag needs a time flown', () {
      expect(issueCodes(() => flight({'overflight_gt_one_min': true})), [
        'required',
      ]);
    });
  });

  group('over-flight flag', () {
    test('is rejected when the time is not over the limit', () {
      expect(
        issueCodes(
          () => flight({'time_flown': 660, 'overflight_gt_one_min': true}),
        ),
        ['not_allowed'],
      );
    });

    test('is required when the time is over the limit', () {
      expect(issueCodes(() => flight({'time_flown': 661})), ['required']);
    });

    test('is not checked once the flight is out of bounds', () {
      final result = flight({'time_flown': 700, 'out_of_bounds': true});

      expect(result.zeroReasons, [ThermalZeroReason.outOfBounds]);
    });
  });

  group('field and option checks', () {
    test('rejects a negative time and too many decimals', () {
      expect(
        issueCodes(() => flight({'time_flown': -1})),
        contains('out_of_range'),
      );
      expect(
        issueCodes(() => flight({'time_flown': 10.5})),
        contains('too_precise'),
      );
    });

    test('rejects unknown and derived fields', () {
      expect(
        issueCodes(() => flight({'motor_restart': true})),
        contains('unknown_field'),
      );
      expect(
        issueCodes(() => flight({'raw_score': 1.0})),
        contains('derived_field'),
      );
    });

    test('rejects an unknown or invalid option', () {
      expect(issueCodes(() => flight({}, overrides: {'working_time': 600})), [
        'unknown_option',
      ]);
      expect(issueCodes(() => flight({}, overrides: {'target_time': 0})), [
        'invalid_option',
      ]);
    });

    test('rejects a negative landing bonus', () {
      expect(
        () => flight({'time_flown': 100}, landingBonus: -1),
        throwsArgumentError,
      );
    });
  });
}
