import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../models/contest/fixtures.dart';

void main() {
  final now = DateTime.utc(2026, 10, 6, 12);

  Contest apply(Contest contest, ContestAction action) =>
      ContestLifecycle.apply(contest, action, now);

  void rejects(Contest contest, ContestAction action) => expect(
    () => apply(contest, action),
    throwsA(
      isA<ContestStateError>().having(
        (e) => e.code,
        'code',
        'invalid_transition',
      ),
    ),
  );

  group('complete', () {
    test('completes a Running contest, closes scoring and ends hiding', () {
      final running = makeContest(
        lifecycleState: LifecycleState.running,
        scoringAccess: ScoringAccess.open,
        hiddenThrough: 2,
        hiddenAt: DateTime.utc(2026, 10, 6),
      );

      final completed = apply(running, ContestAction.complete);

      expect(completed.lifecycleState, LifecycleState.completed);
      expect(completed.scoringAccess, ScoringAccess.closed);
      expect(completed.resultsHidden, isFalse);
      expect(completed.resultsHiddenAt, isNull);
      expect(completed.updatedAt, now);
      expect(completed.revision, running.revision);
    });

    test('is refused from every other lifecycle state', () {
      for (final state in LifecycleState.values) {
        if (state == LifecycleState.running) continue;
        rejects(makeContest(lifecycleState: state), ContestAction.complete);
      }
    });
  });

  group('scoring access', () {
    test('opens and closes', () {
      final open = apply(
        makeContest(lifecycleState: LifecycleState.running),
        ContestAction.openScoring,
      );
      expect(open.scoringAccess, ScoringAccess.open);
      expect(
        apply(open, ContestAction.closeScoring).scoringAccess,
        ScoringAccess.closed,
      );
    });

    test('does not change the lifecycle state', () {
      final open = apply(
        makeContest(lifecycleState: LifecycleState.ready),
        ContestAction.openScoring,
      );
      expect(open.lifecycleState, LifecycleState.ready);
    });

    test('a Completed contest cannot open scoring', () {
      rejects(
        makeContest(lifecycleState: LifecycleState.completed),
        ContestAction.openScoring,
      );
    });

    test('repeating a change is refused', () {
      rejects(makeContest(), ContestAction.closeScoring);
      rejects(
        makeContest(scoringAccess: ScoringAccess.open),
        ContestAction.openScoring,
      );
    });
  });

  group('administration lock', () {
    test('locks and unlocks without touching anything else', () {
      final base = makeContest(lifecycleState: LifecycleState.running);
      final locked = apply(base, ContestAction.lock);
      expect(locked.adminLock, AdminLock.locked);
      expect(locked.lifecycleState, LifecycleState.running);
      expect(apply(locked, ContestAction.unlock).adminLock, AdminLock.unlocked);
    });

    test('a locked contest can still be unlocked or completed', () {
      final locked = makeContest(
        lifecycleState: LifecycleState.running,
        adminLock: AdminLock.locked,
      );
      expect(apply(locked, ContestAction.unlock).adminLock, AdminLock.unlocked);
      expect(
        apply(locked, ContestAction.complete).lifecycleState,
        LifecycleState.completed,
      );
    });

    test('repeating a change is refused', () {
      rejects(makeContest(), ContestAction.unlock);
      rejects(makeContest(adminLock: AdminLock.locked), ContestAction.lock);
    });
  });

  group('results hiding', () {
    final running = makeContest(lifecycleState: LifecycleState.running);

    test('hides through the given round, stamped now', () {
      final hidden = ContestLifecycle.apply(
        running,
        ContestAction.hideResults,
        now,
        hideThroughRound: 3,
      );

      expect(hidden.resultsHiddenThroughRound, 3);
      expect(hidden.resultsHiddenAt, now);
      expect(hidden.lifecycleState, LifecycleState.running);
    });

    test('hiding again moves the round and restarts the time', () {
      final hidden = makeContest(
        lifecycleState: LifecycleState.running,
        hiddenThrough: 1,
        hiddenAt: DateTime.utc(2026, 10, 6),
      );

      final moved = ContestLifecycle.apply(
        hidden,
        ContestAction.hideResults,
        now,
        hideThroughRound: 2,
      );

      expect(moved.resultsHiddenThroughRound, 2);
      expect(moved.resultsHiddenAt, now);
    });

    test('is refused unless the contest is Running', () {
      for (final state in LifecycleState.values) {
        if (state == LifecycleState.running) continue;
        expect(
          () => ContestLifecycle.apply(
            makeContest(lifecycleState: state),
            ContestAction.hideResults,
            now,
            hideThroughRound: 1,
          ),
          throwsA(isA<ContestStateError>()),
        );
      }
    });

    test('shows results again, and refuses when none are hidden', () {
      final hidden = makeContest(
        lifecycleState: LifecycleState.running,
        hiddenThrough: 2,
        hiddenAt: DateTime.utc(2026, 10, 6),
      );

      final shown = apply(hidden, ContestAction.showResults);

      expect(shown.resultsHidden, isFalse);
      expect(shown.resultsHiddenAt, isNull);
      rejects(running, ContestAction.showResults);
    });
  });
}
