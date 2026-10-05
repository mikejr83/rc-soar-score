import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final ales = AlesProfile();

  List<String> codes(Map<String, Object?> components) => [
    for (final i in ales.validate(components)) i.code,
  ];

  group('defaults', () {
    test('identify the discipline and use Time group scoring', () {
      expect(ales.discipline, DisciplineType.ales);
      expect(ales.rulesVersion, 1);
      final options = ales.options();
      expect(options.targetTimeSeconds, 600);
      expect(options.pointsPerSecond, 1);
      expect(options.groupScore.mode, GroupScoreMode.time);
      expect(options.groupScore.roundingMode, RoundingMode.round);
      expect(options.groupScore.decimalPlaces, 1);
      expect(options.latestScorableSeconds, 660);
    });

    test('have no motor restart option', () {
      expect(ales.defaultOptions.containsKey('motor_restart_mode'), isFalse);
      expect(
        () => ales.options({'motor_restart_mode': 'allowed'}),
        throwsA(isA<ScoringValidationError>()),
      );
    });

    test('overrides are laid over the defaults', () {
      final options = ales.options({
        'target_time': 480,
        'group_score_mode': 'Normalized',
        'decimal_places': 0,
      });
      expect(options.targetTimeSeconds, 480);
      expect(options.groupScore.mode, GroupScoreMode.normalized);
      expect(options.groupScore.decimalPlaces, 0);
    });

    test('reject a target time that is not below an hour', () {
      expect(
        () => ales.options({'target_time': 3600}),
        throwsA(isA<ScoringValidationError>()),
      );
      expect(
        () => ales.options({'target_time': 0}),
        throwsA(isA<ScoringValidationError>()),
      );
    });
  });

  group('validation', () {
    test('accepts a time and a landing', () {
      expect(codes({'time_flown': 477, 'landing': 'within_5m'}), isEmpty);
    });

    test('rejects a negative time', () {
      expect(codes({'time_flown': -1}), ['out_of_range']);
    });

    for (final pair in [
      ['motor_restart', 'out_of_bounds'],
      ['motor_restart', 'overflight_gt_one_min'],
      ['out_of_bounds', 'overflight_gt_one_min'],
    ]) {
      test('${pair[0]} excludes ${pair[1]}', () {
        expect(codes({pair[0]: true, pair[1]: true}), ['exclusive_status']);
      });
    }

    test('one status flag alone is valid', () {
      for (final id in ['motor_restart', 'out_of_bounds']) {
        expect(codes({id: true}), isEmpty);
      }
      expect(codes({'overflight_gt_one_min': true}), isEmpty);
    });
  });

  group('zero reasons', () {
    test('codes match the score field keys', () {
      for (final reason in AlesZeroReason.values) {
        expect(ales.field(reason.code), isNotNull);
      }
    });
  });

  group('worked example from the ALES rules (target 480 s, 1 point/s)', () {
    // Raw flight points are given: A 477, B 480 - 3 = 477, C 470.
    final pilots = [
      PilotRound(pilotId: 'A', flightPoints: 477, landingBonus: 30),
      PilotRound(pilotId: 'B', flightPoints: 477, landingBonus: 25),
      PilotRound(pilotId: 'C', flightPoints: 470, landingBonus: 50),
    ];

    List<double> scores(GroupScoreMode mode) => [
      for (final e in calculateGroupScores(
        pilots,
        GroupScoreOptions(mode: mode, decimalPlaces: 0),
      ))
        e.groupScore,
    ];

    test('Time mode adds the landing bonus after normalizing', () {
      expect(scores(GroupScoreMode.time), [1030, 1025, 1035]);
    });

    test('Normalized mode normalizes flight plus landing', () {
      expect(scores(GroupScoreMode.normalized), [975, 965, 1000]);
    });
  });
}
