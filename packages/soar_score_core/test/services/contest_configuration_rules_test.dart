import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../models/contest/fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 10, 6, 12);
  final f5jId = SystemDisciplineProfiles.f5jId;

  ContestConfigurationRevision revision(
    int number, {
    Map<String, Object?> core = const {},
    Map<String, Object?> discipline = const {},
    Id? landingTableId,
  }) => ContestConfigurationRevision(
    id: id(0x100 + number),
    contestId: id(0x10),
    revisionNumber: number,
    disciplineProfileId: f5jId,
    config: ContestConfig(core: core, discipline: discipline),
    landingTableId: landingTableId,
    createdBy: id(1),
    createdAt: now,
  );

  Contest apply(
    Contest contest,
    ContestConfigurationRevision? previous,
    ContestConfigurationRevision next,
  ) => ContestConfigurationRules.apply(contest, previous, next, now);

  void rejects(
    Contest contest,
    ContestConfigurationRevision? previous,
    ContestConfigurationRevision next,
    String code,
  ) => expect(
    () => apply(contest, previous, next),
    throwsA(isA<ContestStateError>().having((e) => e.code, 'code', code)),
  );

  group('Created and Configuring', () {
    test('the first configuration moves Created to Configuring', () {
      final changed = apply(makeContest(), null, revision(1));
      expect(changed.lifecycleState, LifecycleState.configuring);
      expect(changed.updatedAt, now);
    });

    test('Configuring stays Configuring and takes any change', () {
      final contest = makeContest(lifecycleState: LifecycleState.configuring);
      final changed = apply(
        contest,
        revision(1),
        revision(2, core: {'teams_enabled': true, 'team_pilot_count': 2}),
      );
      expect(changed.lifecycleState, LifecycleState.configuring);
    });
  });

  group('Ready', () {
    final ready = makeContest(lifecycleState: LifecycleState.ready);

    test('a derived-score change keeps the matrix valid', () {
      final changed = apply(
        ready,
        revision(1),
        revision(2, core: {'group_score_mode': 'Raw'}),
      );
      expect(changed.lifecycleState, LifecycleState.ready);
    });

    test('a change that affects the matrix goes back to Configuring', () {
      for (final core in <Map<String, Object?>>[
        {'teams_enabled': true, 'team_pilot_count': 2},
        {'draw_mode': 'SeededManOnMan'},
        {'lane_mode': 'Random'},
      ]) {
        final changed = apply(ready, revision(1), revision(2, core: core));
        expect(
          changed.lifecycleState,
          LifecycleState.configuring,
          reason: '$core',
        );
      }
    });
  });

  group('Running', () {
    final running = makeContest(lifecycleState: LifecycleState.running);
    final first = revision(
      1,
      core: {'teams_enabled': true, 'team_pilot_count': 2},
      discipline: {'working_time': 600},
    );

    test('derived-score and reporting options may change', () {
      final changed = apply(
        running,
        first,
        revision(
          2,
          core: {
            'teams_enabled': true,
            'team_pilot_count': 3,
            'group_score_mode': 'Raw',
            'rounding_mode': 'Truncate',
            'decimal_places': 2,
            'drop_after_rounds': [4],
            'tiebreaker_enabled': true,
            'review_requests_enabled': false,
          },
          discipline: {'working_time': 600},
        ),
      );
      expect(changed.lifecycleState, LifecycleState.running);
    });

    test('an omitted setting equals its default', () {
      // The first revision leaves lane_mode out; sending the default is no
      // change.
      apply(
        running,
        first,
        revision(
          2,
          core: {
            'teams_enabled': true,
            'team_pilot_count': 2,
            'lane_mode': 'None',
          },
          discipline: {'working_time': 600},
        ),
      );
    });

    test('teams, draw, lanes and roles are fixed', () {
      for (final core in <Map<String, Object?>>[
        {},
        {'teams_enabled': true, 'team_pilot_count': 2, 'team_protection': true},
        {'allow_back_to_back': false},
        {'teams_enabled': true, 'team_pilot_count': 2, 'roles_enabled': true},
        {
          'teams_enabled': true,
          'team_pilot_count': 2,
          'draw_mode': 'SeededManOnMan',
        },
        {'teams_enabled': true, 'team_pilot_count': 2, 'lane_mode': 'Random'},
        {
          'teams_enabled': true,
          'team_pilot_count': 2,
          'participant_numbers_enabled': true,
        },
      ]) {
        rejects(
          running,
          first,
          revision(2, core: core, discipline: {'working_time': 600}),
          'configuration_fixed',
        );
      }
    });

    test('the discipline settings are fixed whatever their key order', () {
      final base = revision(
        1,
        discipline: {'working_time': 600, 'points_per_second': 1.0},
      );
      apply(
        running,
        base,
        revision(
          2,
          discipline: {'points_per_second': 1.0, 'working_time': 600},
        ),
      );
      rejects(
        running,
        base,
        revision(
          2,
          discipline: {'working_time': 480, 'points_per_second': 1.0},
        ),
        'configuration_fixed',
      );
    });

    test('the landing table is fixed', () {
      rejects(
        running,
        revision(1, landingTableId: id(0x200)),
        revision(2, landingTableId: id(0x201)),
        'configuration_fixed',
      );
    });
  });

  test('a Completed contest keeps its configuration', () {
    rejects(
      makeContest(lifecycleState: LifecycleState.completed),
      revision(1),
      revision(2),
      'configuration_closed',
    );
  });

  test('a locked contest takes no change, whatever its state', () {
    for (final state in [
      LifecycleState.created,
      LifecycleState.configuring,
      LifecycleState.ready,
      LifecycleState.running,
    ]) {
      rejects(
        makeContest(lifecycleState: state, adminLock: AdminLock.locked),
        null,
        revision(1),
        'contest_locked',
      );
    }
  });
}
