import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/scoring/score_entry_settings.dart';
import 'package:soar_score_contest/services/scoring/score_row_draft.dart';

ScoreRowDraft _draft([Map<String, Object?> saved = const {}]) =>
    ScoreRowDraft(settings: const ScoreEntrySettings(), saved: saved);

void main() {
  test('builds the request components from typed values', () {
    final d = _draft()
      ..setTime('630')
      ..setHeight('180')
      ..setLanding('within_1m')
      ..setPenalty('20');
    expect(d.components, {
      'time_flown': 390,
      'launch_height': 180,
      'landing': 'within_1m',
      'flight_penalty': 20,
    });
    expect(d.problems, isEmpty);
  });

  test('a saved row reads back as the same text and is not dirty', () {
    final d = _draft({'time_flown': 390.4, 'launch_height': 180});
    expect(d.timeText, '6:30.4');
    expect(d.heightText, '180');
    expect(d.isDirty, isFalse);
    d.setHeight('181');
    expect(d.isDirty, isTrue);
  });

  test('late landing clears the landing and turns it off', () {
    final d = _draft()
      ..setLanding('within_1m')
      ..setLateLanding(true);
    expect(d.landing, isNull);
    expect(d.landingOffReason, contains('Late landing'));
    expect(d.outOfBoundsOffReason, contains('late landing'));
    expect(d.components['late_landing'], true);
  });

  test('out of bounds zeroes time, height and landing', () {
    final d = _draft()
      ..setTime('630')
      ..setHeight('180')
      ..setLanding('within_1m')
      ..setOutOfBounds(true);
    expect(d.timeText, isEmpty);
    expect(d.heightText, isEmpty);
    expect(d.landing, isNull);
    expect(d.measurementsOffReason, 'Scores 0: out of bounds');
    expect(d.components, {'out_of_bounds': true});
    expect(d.motorRestartOffReason, isNotNull);
    expect(d.noAltitudeOffReason, isNotNull);
  });

  test('no altitude recorded switches the other toggles off', () {
    final d = _draft()..setNoAltitude(true);
    expect(d.lateLandingOffReason, isNotNull);
    expect(d.motorRestartOffReason, isNotNull);
    expect(d.outOfBoundsOffReason, isNotNull);
    expect(d.components, {'no_altitude_recorded': true});
  });

  test(
    'a time without a height, and a height without a time, are problems',
    () {
      expect(
        (_draft()..setTime('630')).problems.map((p) => p.field),
        contains('launch_height'),
      );
      expect(
        (_draft()..setHeight('180')).problems.map((p) => p.field),
        contains('time_flown'),
      );
    },
  );

  test('0 m is a problem and is flagged for No altitude recorded', () {
    final d = _draft()
      ..setTime('630')
      ..setHeight('0');
    expect(d.heightZero, isTrue);
    expect(d.problems.map((p) => p.field), contains('launch_height'));
  });

  test('a launch above 300 m asks, and still saves', () {
    final d = _draft()
      ..setTime('630')
      ..setHeight('350');
    expect(d.heightUnusual, isTrue);
    expect(d.problems, isEmpty);
  });

  test('a blank row and a zeroing row need a confirmation', () {
    expect(_draft().needsZeroConfirmation, isTrue);
    expect((_draft()..setMotorRestart(true)).needsZeroConfirmation, isTrue);
    expect(
      (_draft()
            ..setTime('630')
            ..setHeight('180'))
          .needsZeroConfirmation,
      isFalse,
    );
  });

  test('editing after a confirmation asks again', () {
    final d = _draft()
      ..setOutOfBounds(true)
      ..confirmZero();
    expect(d.zeroConfirmed, isTrue);
    d.setPenalty('5');
    expect(d.zeroConfirmed, isFalse);
  });

  group('cumulative penalty', () {
    test('is absent, applied or removed by the text', () {
      final draft = _draft({'time_flown': 390, 'launch_height': 180});
      expect(draft.cumulativePenalty, isNull);
      expect(draft.components.containsKey('cumulative_penalty'), isFalse);

      draft.setCumulativePenalty('25');
      expect(draft.cumulativePenalty, 25);
      expect(draft.components['cumulative_penalty'], 25);

      draft.setCumulativePenalty('0');
      expect(draft.cumulativePenalty, 0);
      expect(draft.components['cumulative_penalty'], 0);
    });

    test('reads back from the saved row', () {
      expect(_draft({'cumulative_penalty': 5}).cumulativePenaltyText, '5');
      expect(_draft({'cumulative_penalty': 0}).cumulativePenaltyText, '0');
      expect(
        _draft({
          'time_flown': 390,
          'launch_height': 180,
          'cumulative_penalty': 5,
        }).isDirty,
        isFalse,
      );
    });

    test('a removal from a saved 5 is a change, and saving it keeps it 0', () {
      final d = _draft({
        'time_flown': 390,
        'launch_height': 180,
        'cumulative_penalty': 5,
      });
      d.setCumulativePenalty('0');
      expect(d.isDirty, isTrue);
      expect(d.components['cumulative_penalty'], 0);
      d.resetTo(d.components);
      expect(d.isDirty, isFalse);
    });

    test('empty text stores no key and not a problem, and the row is blank again when nothing else was entered', () {
      final d = _draft({'cumulative_penalty': 5})..setCumulativePenalty('');
      expect(d.components.containsKey('cumulative_penalty'), isFalse);
      expect(
        d.problems.map((p) => p.field),
        isNot(contains('cumulative_penalty')),
      );
      expect(_draft().isBlank, isTrue);
      expect((_draft()..setCumulativePenalty('0')).isBlank, isFalse);
    });

    test('non-numeric or negative text is a problem', () {
      for (final text in ['a lot', '-5', '1.5']) {
        final d = _draft()..setCumulativePenalty(text);
        expect(
          d.problems.map((p) => p.field),
          contains('cumulative_penalty'),
          reason: text,
        );
      }
      expect((_draft()..setCumulativePenalty('0')).problems, isEmpty);
    });

    test('a flight-penalty 0 is still stripped, like before', () {
      expect(
        (_draft()..setPenalty('0')).components.containsKey('flight_penalty'),
        isFalse,
      );
    });
  });

  test('settings follow the contest', () {
    expect(const ScoreEntrySettings().restartsAllowed, isTrue);
    final s = ScoreEntrySettings.fromDiscipline({
      'motor_restart_mode': 'non_droppable',
      'working_time': 480,
    });
    expect(s.restartsNonDroppable, isTrue);
    expect(s.workingTimeSeconds, 480);
    expect(
      ScoreEntrySettings.fromDiscipline({'motor_restart_mode': 'not_allowed'})
          .restartsAllowed,
      isFalse,
    );
  });
}
