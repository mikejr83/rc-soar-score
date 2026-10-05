import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'fixture_files.dart';

void main() {
  final profile = F5jProfile();

  for (final fixture in loadF5jFixtures('flights.json')) {
    final name = fixture['name'] as String;
    final components = asMap(fixture['components']);
    final options = fixture['options'] == null
        ? null
        : asMap(fixture['options']);
    final bonus = asDouble(fixture['landing_bonus'] ?? 0);

    test(name, () {
      final expectedError = fixture['expected_error'] as List?;
      if (expectedError != null) {
        expect(
          () => profile.calculate(
            components,
            overrides: options,
            landingBonus: bonus,
          ),
          throwsA(
            isA<ScoringValidationError>().having(
              (e) => e.issues.map((i) => i.code).toList()..sort(),
              'issue codes',
              [...expectedError.cast<String>()]..sort(),
            ),
          ),
        );
        return;
      }

      final result = profile.calculate(
        components,
        overrides: options,
        landingBonus: bonus,
      );
      final expected = asMap(fixture['expected']);
      expect(result.outcome.name, expected['outcome']);
      expect(result.zeroReasons.map((r) => r.code).toList(), [
        ...(expected['zero_reasons'] as List).cast<String>(),
      ]);
      expect(result.lateLanding, expected['late_landing']);
      expect(result.nonDroppable, expected['non_droppable']);
      expect(result.motorRestartMode.json, expected['motor_restart_mode']);
      for (final (key, actual) in [
        ('flight_points', result.flightPoints),
        ('landing_bonus', result.landingBonus),
        ('height_penalty', result.heightPenalty),
        ('flight_penalty', result.flightPenalty),
        ('raw_score', result.rawScore),
      ]) {
        expect(actual, closeTo(asDouble(expected[key]), 1e-9), reason: key);
      }
    });
  }
}
