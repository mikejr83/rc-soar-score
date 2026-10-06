import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final f5j = SystemDisciplineProfiles.f5j;

  List<String> problems(
    Map<String, Object?> discipline, {
    DisciplineProfileWithRules? profile,
  }) {
    try {
      DisciplineConfigValidator.validate(profile ?? f5j, discipline);
    } on ScoringValidationError catch (e) {
      return [for (final issue in e.issues) '${issue.fieldId}:${issue.code}'];
    }
    return const [];
  }

  test('accepts a complete F5J configuration and an empty one', () {
    expect(
      problems({
        'working_time': 600,
        'points_per_second': 1.0,
        'fractional_seconds': 0,
        'motor_restart_mode': 'allowed',
        'reference_launch_height': 200,
        'minor_penalty_per_meter': 0.5,
        'major_penalty_per_meter': 3.0,
      }),
      isEmpty,
    );
    // Every F5J field has a default, so leaving them out is valid.
    expect(problems({}), isEmpty);
  });

  test('a float setting takes a whole number too', () {
    expect(problems({'points_per_second': 2}), isEmpty);
  });

  test('rejects a setting the profile does not have', () {
    expect(problems({'working_tyme': 600}), ['working_tyme:unknown_field']);
  });

  test('rejects values of the wrong type', () {
    expect(
      problems({
        'working_time': '600',
        'points_per_second': 'fast',
        'motor_restart_mode': 3,
      }),
      unorderedEquals([
        'working_time:wrong_type',
        'points_per_second:wrong_type',
        'motor_restart_mode:not_allowed',
      ]),
    );
  });

  test('an int setting does not take a fraction', () {
    expect(problems({'working_time': 600.5}), ['working_time:wrong_type']);
  });

  test('enforces the bounds of each field', () {
    expect(problems({'working_time': 0}), ['working_time:out_of_range']);
    expect(problems({'working_time': 3600}), ['working_time:out_of_range']);
    expect(problems({'working_time': 1}), isEmpty);
    expect(problems({'working_time': 3599}), isEmpty);
    expect(problems({'fractional_seconds': 4}), [
      'fractional_seconds:out_of_range',
    ]);
    expect(problems({'fractional_seconds': 3}), isEmpty);
    expect(problems({'minor_penalty_per_meter': -0.1}), [
      'minor_penalty_per_meter:out_of_range',
    ]);
  });

  test('an enum setting takes only its options', () {
    expect(problems({'motor_restart_mode': 'not_allowed'}), isEmpty);
    expect(problems({'motor_restart_mode': 'sometimes'}), [
      'motor_restart_mode:not_allowed',
    ]);
  });

  test('the landing table is chosen outside the settings', () {
    expect(problems({'landing_table': 'x'}), [
      'landing_table:landing_in_settings',
    ]);
  });

  test('reports every problem at once', () {
    expect(
      problems({'working_time': 0, 'nope': 1, 'fractional_seconds': 'a'}),
      hasLength(3),
    );
  });

  group('a required setting with no default', () {
    final profile = DisciplineProfileWithRules(
      profile: f5j.profile,
      configFields: [
        DisciplineConfigField(
          id: Id.parse('019c0000-0000-7000-8000-0000000000a1'),
          disciplineProfileId: f5j.profile.id,
          fieldKey: 'venue_code',
          fieldType: ConfigFieldType.string,
          name: 'Venue code',
          required: true,
          validation: const {'pattern': r'^[A-Z]{3}$'},
          createdAt: DateTime.utc(2026),
        ),
      ],
      scoreFields: const [],
      validations: const [],
      formulas: const [],
      rules: const [],
    );

    test('must be given', () {
      expect(problems({}, profile: profile), ['venue_code:required']);
    });

    test('is checked against its pattern', () {
      expect(problems({'venue_code': 'DEN'}, profile: profile), isEmpty);
      expect(problems({'venue_code': 'denver'}, profile: profile), [
        'venue_code:out_of_range',
      ]);
    });
  });
}
