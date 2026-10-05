import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

ConfigChange classify({
  Map<String, Object?> beforeCore = const {},
  Map<String, Object?> afterCore = const {},
  Map<String, Object?> beforeDiscipline = const {},
  Map<String, Object?> afterDiscipline = const {},
  Object? beforeLanding,
  Object? afterLanding,
  LifecycleState state = LifecycleState.configuring,
}) => classifyConfigChange(
  beforeCore: beforeCore,
  afterCore: afterCore,
  beforeDiscipline: beforeDiscipline,
  afterDiscipline: afterDiscipline,
  beforeLandingTableId: beforeLanding,
  afterLandingTableId: afterLanding,
  state: state,
);

void main() {
  group('what a change is', () {
    test('no difference means nothing to do', () {
      final change = classify(
        beforeCore: {
          'decimal_places': 1,
          'drop_after_rounds': [4],
        },
        afterCore: {
          'decimal_places': 1,
          'drop_after_rounds': [4],
        },
      );
      expect(change.changes, isEmpty);
      expect(change.isAllowed, isTrue);
      expect(change.requiresRecalculation, isFalse);
    });

    test('every recalculating option triggers a recalculation', () {
      const options = {
        'team_pilot_count': [3, 4],
        'group_score_mode': ['Normalized', 'Raw'],
        'rounding_mode': ['Round', 'Truncate'],
        'decimal_places': [1, 2],
        'drop_after_rounds': [
          <int>[],
          [4],
        ],
        'tiebreaker_enabled': [false, true],
      };
      for (final entry in options.entries) {
        final change = classify(
          beforeCore: {entry.key: entry.value[0]},
          afterCore: {entry.key: entry.value[1]},
          state: LifecycleState.running,
        );
        expect(change.changes, [
          ChangedOption(entry.key, OptionGroup.recalculating),
        ]);
        expect(change.requiresRecalculation, isTrue, reason: entry.key);
        expect(change.isAllowed, isTrue, reason: entry.key);
      }
    });

    test('presentation changes never recalculate', () {
      final change = classify(
        beforeCore: {'public_update_mode': 'RoundCompletion'},
        afterCore: {'public_update_mode': 'Live'},
        state: LifecycleState.running,
      );
      expect(change.requiresRecalculation, isFalse);
      expect(change.isAllowed, isTrue);
    });

    test('a key added or removed is a difference', () {
      expect(
        classify(
          beforeCore: {'decimal_places': 1},
          afterCore: {},
        ).requiresRecalculation,
        isTrue,
      );
    });

    test('an unknown core key is treated as recalculating', () {
      final change = classify(afterCore: {'future_option': true});
      expect(change.changes.single.group, OptionGroup.recalculating);
    });

    test('discipline fields and the landing table are scoring rules', () {
      final change = classify(
        beforeDiscipline: {'working_time': 600},
        afterDiscipline: {'working_time': 480},
        beforeLanding: 'a',
        afterLanding: 'b',
      );
      expect(change.changes, [
        const ChangedOption(
          'discipline.working_time',
          OptionGroup.scoringRules,
        ),
        const ChangedOption('landing_table', OptionGroup.scoringRules),
      ]);
      expect(change.requiresRecalculation, isTrue);
    });
  });

  group('lifecycle rules', () {
    test('scoring rules are free before the first score', () {
      for (final state in [
        LifecycleState.created,
        LifecycleState.configuring,
        LifecycleState.ready,
      ]) {
        expect(
          classify(
            beforeDiscipline: {'working_time': 600},
            afterDiscipline: {'working_time': 480},
            state: state,
          ).isAllowed,
          isTrue,
          reason: state.name,
        );
      }
    });

    test('scoring rules and the landing table are fixed once running', () {
      final change = classify(
        beforeDiscipline: {'working_time': 600},
        afterDiscipline: {'working_time': 480},
        beforeLanding: 'a',
        afterLanding: 'b',
        state: LifecycleState.running,
      );
      expect(change.isAllowed, isFalse);
      expect(change.rejected.map((r) => r.option.key), [
        'discipline.working_time',
        'landing_table',
      ]);
    });

    test('structural changes are fixed once running', () {
      final change = classify(
        beforeCore: {'lane_mode': 'None'},
        afterCore: {'lane_mode': 'Fixed'},
        state: LifecycleState.running,
      );
      expect(change.isAllowed, isFalse);
    });

    test('a structural change after the draw offers a redraw', () {
      final change = classify(
        beforeCore: {'lane_mode': 'None'},
        afterCore: {'lane_mode': 'Fixed'},
        state: LifecycleState.ready,
      );
      expect(change.isAllowed, isTrue);
      expect(change.offerRedraw, isTrue);
      expect(change.requiresRecalculation, isFalse);
    });

    test('a structural change before the draw offers no redraw', () {
      final change = classify(
        beforeCore: {'lane_mode': 'None'},
        afterCore: {'lane_mode': 'Fixed'},
      );
      expect(change.offerRedraw, isFalse);
    });

    test('nothing changes once completed', () {
      final change = classify(
        beforeCore: {'decimal_places': 1},
        afterCore: {'decimal_places': 2},
        state: LifecycleState.completed,
      );
      expect(change.isAllowed, isFalse);
      expect(change.rejected.single.reason, 'the contest is completed');
    });
  });

  test('every core option key the model reads has a group', () {
    final keys = {
      'teams_enabled',
      'team_pilot_count',
      'team_protection',
      'roles_enabled',
      'draw_mode',
      'preliminary_rounds',
      'lane_mode',
      'group_score_mode',
      'rounding_mode',
      'decimal_places',
      'drop_after_rounds',
      'tiebreaker_enabled',
      'classes_enabled',
      'models_enabled',
      'participant_numbers_enabled',
      'review_requests_enabled',
      'public_update_mode',
      'intended_total_rounds',
    };
    expect(coreOptionGroups.keys.toSet(), keys);
  });
}
