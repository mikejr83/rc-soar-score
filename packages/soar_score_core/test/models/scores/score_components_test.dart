import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  group('requireValidPenalties', () {
    Map<String, Object?> withPenalties({
      Object? flight,
      Object? cumulative,
    }) {
      final components = <String, Object?>{};
      if (flight != null) components['flight_penalty'] = flight;
      if (cumulative != null) components['cumulative_penalty'] = cumulative;
      return components;
    }

    test('absent and explicit null penalties are always OK', () {
      expect(() => requireValidPenalties({}), isNot(throwsArgumentError));
      expect(
        () => requireValidPenalties(withPenalties(
          flight: null,
          cumulative: null,
        )),
        isNot(throwsArgumentError),
      );
    });

    test('zero and positive penalties are a valid shape', () {
      for (final value in const [0, 5]) {
        for (final authority in Authority.values) {
          expect(
            () => requireValidPenalties(
              withPenalties(flight: value),
              authority: authority,
            ),
            isNot(throwsArgumentError),
            reason: 'flight $value with $authority',
          );
          expect(
            () => requireValidPenalties(
              withPenalties(cumulative: value),
              authority: authority == Authority.director ? authority : null,
            ),
            isNot(throwsArgumentError),
            reason: 'cumulative $value with $authority',
          );
        }
      }
    });

    test('a negative penalty is rejected', () {
      for (final value in const [-1, -100]) {
        expect(
          () => requireValidPenalties(withPenalties(flight: value)),
          throwsArgumentError,
          reason: 'flight $value',
        );
        expect(
          () => requireValidPenalties(
            withPenalties(cumulative: value),
            authority: Authority.director,
          ),
          throwsArgumentError,
          reason: 'cumulative $value',
        );
      }
    });

    test('a non-integer penalty is rejected', () {
      for (final value in const ['a lot', 1.5, true]) {
        expect(
          () => requireValidPenalties(withPenalties(flight: value)),
          throwsArgumentError,
          reason: 'flight $value',
        );
        expect(
          () => requireValidPenalties(
            withPenalties(cumulative: value),
            authority: Authority.director,
          ),
          throwsArgumentError,
          reason: 'cumulative $value',
        );
      }
    });

    test('only director authority may set a non-null cumulative penalty', () {
      for (final authority in Authority.values.where((a) => a != Authority.director)) {
        for (final value in const [0, 5]) {
          expect(
            () => requireValidPenalties(
              withPenalties(cumulative: value),
              authority: authority,
            ),
            throwsArgumentError,
            reason: '$authority with $value',
          );
        }
        expect(
          () => requireValidPenalties(
            withPenalties(cumulative: null),
            authority: authority,
          ),
          isNot(throwsArgumentError),
          reason: '$authority with null',
        );
      }
    });
  });
}
