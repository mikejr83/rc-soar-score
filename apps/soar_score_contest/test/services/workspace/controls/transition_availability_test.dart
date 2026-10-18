import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/controls/contest_transition.dart';
import 'package:soar_score_contest/services/workspace/controls/transition_availability.dart';
import 'package:soar_score_core/soar_score_core.dart';

Contest _contest(
  LifecycleState state, {
  ScoringAccess access = ScoringAccess.closed,
  AdminLock lock = AdminLock.unlocked,
}) => Contest(
  id: Id.parse('019c0000-0000-7000-8000-000000000017'),
  name: 'Test',
  startDateTime: DateTime.utc(2026, 10, 17),
  endDateTime: DateTime.utc(2026, 10, 18),
  timezone: 'UTC',
  lifecycleState: state,
  scoringAccess: access,
  adminLock: lock,
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
);

bool _enabled(Contest contest, ContestTransition transition) =>
    TransitionAvailability.of(contest, transition).enabled;

void main() {
  group('complete', () {
    for (final state in LifecycleState.values) {
      test('${state.name}: only a running contest can be completed', () {
        final availability = TransitionAvailability.of(
          _contest(state),
          ContestTransition.complete,
        );
        expect(availability.enabled, state == LifecycleState.running);
        expect(availability.reason == null, availability.enabled);
      });
    }

    test('the reason for a contest not yet running names its state', () {
      final availability = TransitionAvailability.of(
        _contest(LifecycleState.ready),
        ContestTransition.complete,
      );
      expect(availability.reason, contains('ready'));
    });
  });

  group('participant scoring', () {
    test('opens a closed contest and closes an open one', () {
      final closed = _contest(LifecycleState.ready);
      final open = _contest(LifecycleState.ready, access: ScoringAccess.open);
      expect(_enabled(closed, ContestTransition.openScoring), isTrue);
      expect(_enabled(closed, ContestTransition.closeScoring), isFalse);
      expect(_enabled(open, ContestTransition.openScoring), isFalse);
      expect(_enabled(open, ContestTransition.closeScoring), isTrue);
    });

    test('a completed contest keeps scoring closed', () {
      final availability = TransitionAvailability.of(
        _contest(LifecycleState.completed),
        ContestTransition.openScoring,
      );
      expect(availability.enabled, isFalse);
      expect(availability.reason, contains('completed'));
    });
  });

  group('administration lock', () {
    test('locks an unlocked contest and unlocks a locked one', () {
      final unlocked = _contest(LifecycleState.running);
      final locked = _contest(LifecycleState.running, lock: AdminLock.locked);
      expect(_enabled(unlocked, ContestTransition.lock), isTrue);
      expect(_enabled(unlocked, ContestTransition.unlock), isFalse);
      expect(_enabled(locked, ContestTransition.lock), isFalse);
      expect(_enabled(locked, ContestTransition.unlock), isTrue);
    });

    test('a completed contest can still be locked and unlocked', () {
      expect(
        _enabled(_contest(LifecycleState.completed), ContestTransition.lock),
        isTrue,
      );
    });
  });

  test('every disabled transition says why', () {
    for (final state in LifecycleState.values) {
      for (final access in ScoringAccess.values) {
        for (final lock in AdminLock.values) {
          final contest = _contest(state, access: access, lock: lock);
          for (final transition in ContestTransition.values) {
            final availability = TransitionAvailability.of(contest, transition);
            expect(
              availability.reason == null,
              availability.enabled,
              reason: '$state $access $lock $transition',
            );
          }
        }
      }
    }
  });
}
