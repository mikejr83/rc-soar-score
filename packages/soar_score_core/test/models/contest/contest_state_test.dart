import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

final DateTime hiddenAt = DateTime.utc(2026, 10, 17, 18);

void main() {
  group('Contest independent states', () {
    test('every lifecycle state can combine with every other control', () {
      for (final lifecycle in LifecycleState.values) {
        for (final access in ScoringAccess.values) {
          for (final lock in AdminLock.values) {
            final contest = makeContest(
              lifecycleState: lifecycle,
              scoringAccess: access,
              adminLock: lock,
              hiddenThrough: 2,
              hiddenAt: hiddenAt,
              localArchive: true,
            );
            expect(Contest.fromJson(contest.toJson()), contest);
            expect(contest.lifecycleState, lifecycle);
            expect(contest.scoringAccess, access);
            expect(contest.adminLock, lock);
            expect(contest.resultsHidden, isTrue);
            expect(contest.localArchive, isTrue);
          }
        }
      }
    });

    test('changing one dimension leaves the others as they were', () {
      final base = makeContest(
        lifecycleState: LifecycleState.running,
        scoringAccess: ScoringAccess.open,
      );
      expect(
        makeContest(
          lifecycleState: LifecycleState.running,
          scoringAccess: ScoringAccess.open,
          adminLock: AdminLock.locked,
        ).scoringAccess,
        base.scoringAccess,
      );
      expect(
        makeContest(
          lifecycleState: LifecycleState.running,
          scoringAccess: ScoringAccess.open,
          localArchive: true,
        ).lifecycleState,
        base.lifecycleState,
      );
    });

    test('lifecycle, access and lock values match the documents', () {
      const lifecycles = {
        'Created': LifecycleState.created,
        'Configuring': LifecycleState.configuring,
        'Ready': LifecycleState.ready,
        'Running': LifecycleState.running,
        'Completed': LifecycleState.completed,
      };
      final base = makeContest().toJson();
      for (final e in lifecycles.entries) {
        expect(
          Contest.fromJson({...base, 'lifecycle_state': e.key}).lifecycleState,
          e.value,
        );
      }
      expect(
        Contest.fromJson({...base, 'scoring_access': 'Open'}).scoringAccess,
        ScoringAccess.open,
      );
      expect(
        Contest.fromJson({...base, 'admin_lock': 'Locked'}).adminLock,
        AdminLock.locked,
      );
    });
  });

  group('Contest results hiding', () {
    test('both hiding columns are set together', () {
      expect(makeContest().resultsHidden, isFalse);
      expect(() => makeContest(hiddenThrough: 2), throwsArgumentError);
      expect(() => makeContest(hiddenAt: hiddenAt), throwsArgumentError);
      expect(
        makeContest(hiddenThrough: 2, hiddenAt: hiddenAt).resultsHidden,
        isTrue,
      );
    });

    test('hides through a round of 1 or more', () {
      expect(
        () => makeContest(hiddenThrough: 0, hiddenAt: hiddenAt),
        throwsArgumentError,
      );
    });

    test('hiding expires 24 hours after it was turned on', () {
      final contest = makeContest(hiddenThrough: 2, hiddenAt: hiddenAt);
      expect(
        contest.hidingExpiredAt(
          hiddenAt.add(const Duration(hours: 23, minutes: 59)),
        ),
        isFalse,
      );
      expect(
        contest.hidingExpiredAt(hiddenAt.add(Contest.hidingLifetime)),
        isTrue,
      );
      expect(makeContest().hidingExpiredAt(hiddenAt), isFalse);
    });
  });
}
