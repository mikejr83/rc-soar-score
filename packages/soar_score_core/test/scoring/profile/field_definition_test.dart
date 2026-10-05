import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('ScoringFieldDefinition', () {
    test('exposes field metadata', () {
      final time = FakeProfile().field('time')!;

      expect(time.label, 'Time');
      expect(time.unit, 's');
      expect(time.precision, 1);
      expect(time.min, 0);
      expect(time.max, 600);
      expect(time.required, isTrue);
      expect(time.acceptedInSubmission, isTrue);
    });

    test('derived fields are not accepted in a submission', () {
      expect(FakeProfile().field('raw_score')!.acceptedInSubmission, isFalse);
    });

    test('an unknown field resolves to null', () {
      expect(FakeProfile().field('nope'), isNull);
    });

    test('rejects invalid definitions', () {
      expect(
        () => ScoringFieldDefinition(
          id: ' ',
          label: 'x',
          type: ScoreFieldType.int,
        ),
        throwsArgumentError,
      );
      expect(
        () => ScoringFieldDefinition(
          id: 'x',
          label: 'x',
          type: ScoreFieldType.int,
          min: 5,
          max: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => ScoringFieldDefinition(
          id: 'x',
          label: 'x',
          type: ScoreFieldType.int,
          allowedValues: [1],
        ),
        throwsArgumentError,
      );
      expect(
        () => ScoringFieldDefinition(
          id: 'x',
          label: 'x',
          type: ScoreFieldType.float,
          precision: -1,
        ),
        throwsArgumentError,
      );
    });
  });
}
