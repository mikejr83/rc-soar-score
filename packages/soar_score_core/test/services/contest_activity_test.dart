import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final last = DateTime.utc(2026, 10, 17, 15);
  ContestDisplayStatus status(
    LifecycleState state,
    DateTime? activity,
    Duration since,
  ) => contestDisplayStatus(
    lifecycleState: state,
    lastActivityAt: activity,
    now: last.add(since),
  );

  group('contestDisplayStatus', () {
    test('the inactivity period is 48 hours', () {
      expect(contestInactivityPeriod, const Duration(hours: 48));
    });

    test('running inside 48 hours is in progress', () {
      expect(
        status(LifecycleState.running, last, const Duration(hours: 48)),
        ContestDisplayStatus.inProgress,
      );
    });

    test('running past 48 hours is completed', () {
      expect(
        status(
          LifecycleState.running,
          last,
          const Duration(hours: 48, minutes: 1),
        ),
        ContestDisplayStatus.completed,
      );
    });

    test('a ready contest with invitations sent follows the same rule', () {
      expect(
        status(LifecycleState.ready, last, const Duration(hours: 49)),
        ContestDisplayStatus.completed,
      );
    });

    test('Completed is completed whatever the activity', () {
      expect(
        status(LifecycleState.completed, null, Duration.zero),
        ContestDisplayStatus.completed,
      );
    });

    test('no activity at all is in progress', () {
      expect(
        status(LifecycleState.running, null, const Duration(days: 30)),
        ContestDisplayStatus.inProgress,
      );
    });

    test('earlier states are in progress', () {
      expect(
        status(LifecycleState.configuring, last, const Duration(days: 30)),
        ContestDisplayStatus.inProgress,
      );
    });

    test('wire names', () {
      expect(ContestDisplayStatus.inProgress.wireName, 'in_progress');
      expect(ContestDisplayStatus.completed.wireName, 'completed');
    });
  });
}
