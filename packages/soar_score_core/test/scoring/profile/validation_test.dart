import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'support.dart';

List<String> _codes(Map<String, Object?> components) =>
    FakeProfile().validate(components).map((i) => i.code).toList();

void main() {
  group('ScoringProfile.validate', () {
    test('accepts a valid component set', () {
      expect(FakeProfile().validate({'time': 120.5, 'altitude': 100}), isEmpty);
    });

    test('requires required fields', () {
      expect(_codes({}), ['required']);
    });

    test('rejects unknown and derived fields', () {
      expect(_codes({'time': 1, 'nope': 1}), ['unknown_field']);
      expect(_codes({'time': 1, 'raw_score': 1}), ['derived_field']);
    });

    test('rejects the wrong type', () {
      expect(_codes({'time': 'x'}), ['wrong_type']);
      expect(_codes({'time': 1, 'altitude': 1.5}), ['wrong_type']);
      expect(_codes({'time': 1, 'late': 'yes'}), ['wrong_type']);
    });

    test('rejects values outside the range', () {
      expect(_codes({'time': -1}), ['out_of_range']);
      expect(_codes({'time': 601}), ['out_of_range']);
      expect(_codes({'time': 1, 'altitude': 0}), ['out_of_range']);
    });

    test('accepts the range boundaries', () {
      expect(FakeProfile().validate({'time': 0}), isEmpty);
      expect(FakeProfile().validate({'time': 600}), isEmpty);
    });

    test('rejects more decimal places than the precision', () {
      expect(_codes({'time': 1.25}), ['too_precise']);
      expect(FakeProfile().validate({'time': 1.3}), isEmpty);
    });

    test('rejects a value that is not allowed', () {
      expect(_codes({'time': 1, 'mode': 'c'}), ['not_allowed']);
      expect(FakeProfile().validate({'time': 1, 'mode': 'a'}), isEmpty);
    });

    test('rejects non-finite numbers', () {
      expect(_codes({'time': double.nan}), ['wrong_type']);
    });

    test('runs combination rules once fields are valid', () {
      expect(_codes({'time': 1, 'late': true}), ['combination']);
      expect(
        FakeProfile().validate({'time': 1, 'late': true, 'altitude': 5}),
        isEmpty,
      );
    });

    test('reports every field problem together', () {
      expect(_codes({'time': 'x', 'altitude': 0}), [
        'wrong_type',
        'out_of_range',
      ]);
    });
  });

  group('validateOrThrow', () {
    test('throws with the issues', () {
      expect(
        () => FakeProfile().validateOrThrow({}),
        throwsA(
          isA<ScoringValidationError>().having(
            (e) => e.issues.single.fieldId,
            'fieldId',
            'time',
          ),
        ),
      );
    });

    test('passes a valid set', () {
      FakeProfile().validateOrThrow({'time': 1});
    });
  });
}
