import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreOptions platform defaults', () {
    final options = CoreOptions.fromMap(const {});

    test('match contest-options.md', () {
      expect(options.teamsEnabled, isFalse);
      expect(options.teamPilotCount, isNull);
      expect(options.teamProtection, isFalse);
      expect(options.rolesEnabled, isFalse);
      expect(options.drawMode, DrawMode.standardManOnMan);
      expect(options.preliminaryRounds, isNull);
      expect(options.laneMode, LaneMode.none);
      expect(options.groupScoreMode, GroupScoreMode.normalized);
      expect(options.roundingMode, RoundingMode.round);
      expect(options.decimalPlaces, 1);
      expect(options.dropAfterRounds, isEmpty);
      expect(options.tiebreakerEnabled, isFalse);
      expect(options.classesEnabled, isFalse);
      expect(options.modelsEnabled, isFalse);
      expect(options.participantNumbersEnabled, isFalse);
      expect(options.reviewRequestsEnabled, isTrue);
      expect(options.publicUpdateMode, PublicUpdateMode.roundCompletion);
      expect(options.intendedTotalRounds, isNull);
    });

    test('compare by value', () {
      expect(options, CoreOptions.fromMap(const {}));
    });
  });

  group('CoreOptions values', () {
    test('read every documented enum text', () {
      final options = CoreOptions.fromMap(const {
        'draw_mode': 'SeededManOnMan',
        'lane_mode': 'Random',
        'group_score_mode': 'Raw',
        'rounding_mode': 'Truncate',
        'public_update_mode': 'Manual',
      });
      expect(options.drawMode, DrawMode.seededManOnMan);
      expect(options.laneMode, LaneMode.random);
      expect(options.groupScoreMode, GroupScoreMode.raw);
      expect(options.roundingMode, RoundingMode.truncate);
      expect(options.publicUpdateMode, PublicUpdateMode.manual);
    });

    test('reject an unknown enum text or a wrong type', () {
      expect(
        () => CoreOptions.fromMap(const {'lane_mode': 'Sideways'}),
        throwsArgumentError,
      );
      expect(
        () => CoreOptions.fromMap(const {'teams_enabled': 'yes'}),
        throwsArgumentError,
      );
      expect(
        () => CoreOptions.fromMap(const {'decimal_places': 1.5}),
        throwsArgumentError,
      );
    });

    test('ignore unknown keys', () {
      expect(
        CoreOptions.fromMap(const {'from_the_future': true}),
        CoreOptions.fromMap(const {}),
      );
    });

    test('decimal places run from 0 to 3', () {
      for (final ok in [0, 1, 2, 3]) {
        expect(CoreOptions.fromMap({'decimal_places': ok}).decimalPlaces, ok);
      }
      for (final bad in [-1, 4]) {
        expect(
          () => CoreOptions.fromMap({'decimal_places': bad}),
          throwsArgumentError,
        );
      }
    });

    test('drop rounds are ascending, at most two, each 1 or more', () {
      expect(
        CoreOptions.fromMap(const {
          'drop_after_rounds': [4, 8],
        }).dropAfterRounds,
        [4, 8],
      );
      for (final bad in [
        [8, 4],
        [4, 4],
        [0],
        [2, 4, 6],
      ]) {
        expect(
          () => CoreOptions.fromMap({'drop_after_rounds': bad}),
          throwsArgumentError,
          reason: '$bad',
        );
      }
    });
  });

  group('CoreOptions dependencies', () {
    test('teams need a pilot count of 1 or more', () {
      expect(
        () => CoreOptions.fromMap(const {'teams_enabled': true}),
        throwsArgumentError,
      );
      expect(
        () => CoreOptions.fromMap(const {
          'teams_enabled': true,
          'team_pilot_count': 0,
        }),
        throwsArgumentError,
      );
      expect(
        CoreOptions.fromMap(const {
          'teams_enabled': true,
          'team_pilot_count': 2,
        }).teamPilotCount,
        2,
      );
    });

    test('team options are invalid without teams', () {
      expect(
        () => CoreOptions.fromMap(const {'team_protection': true}),
        throwsArgumentError,
      );
      expect(
        () => CoreOptions.fromMap(const {'team_pilot_count': 2}),
        throwsArgumentError,
      );
    });

    test('seeded draw and team protection are forbidden together', () {
      expect(
        () => CoreOptions.fromMap(const {
          'draw_mode': 'SeededManOnMan',
          'teams_enabled': true,
          'team_pilot_count': 2,
          'team_protection': true,
        }),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('cannot be used with SeededManOnMan'),
          ),
        ),
      );
      expect(
        CoreOptions.fromMap(const {
          'draw_mode': 'SeededManOnMan',
          'teams_enabled': true,
          'team_pilot_count': 2,
        }).drawMode,
        DrawMode.seededManOnMan,
      );
    });

    test('seeded options need SeededManOnMan', () {
      expect(
        () => CoreOptions.fromMap(const {'preliminary_rounds': 2}),
        throwsArgumentError,
      );
      expect(
        () => CoreOptions.fromMap(const {'intended_total_rounds': 8}),
        throwsArgumentError,
      );
    });

    test('seeded draws default to one preliminary round', () {
      final options = CoreOptions.fromMap(const {
        'draw_mode': 'SeededManOnMan',
        'intended_total_rounds': 8,
      });
      expect(options.preliminaryRounds, 1);
      expect(options.intendedTotalRounds, 8);
      expect(
        CoreOptions.fromMap(const {
          'draw_mode': 'SeededManOnMan',
          'preliminary_rounds': 3,
        }).preliminaryRounds,
        3,
      );
    });

    test('rounds must be 1 or more', () {
      expect(
        () => CoreOptions.fromMap(const {
          'draw_mode': 'SeededManOnMan',
          'preliminary_rounds': 0,
        }),
        throwsArgumentError,
      );
    });
  });
}
