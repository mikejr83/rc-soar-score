import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final last = DateTime.utc(2026, 10, 17, 15);
  ContestDisplayStatus status(
    LifecycleState state,
    DateTime? activity,
    Duration since, {
    DateTime? start,
  }) => contestDisplayStatus(
    lifecycleState: state,
    startsAt: start ?? last.subtract(const Duration(days: 1)),
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

    test('no activity counts from the start', () {
      final start = last.subtract(const Duration(days: 1));
      expect(
        status(LifecycleState.ready, null, const Duration(hours: 20)),
        ContestDisplayStatus.inProgress,
        reason: 'started 44 hours ago',
      );
      expect(
        status(LifecycleState.ready, null, const Duration(hours: 25)),
        ContestDisplayStatus.completed,
        reason: 'started 49 hours ago ($start)',
      );
    });

    test('before the start it is upcoming, whatever was sent or scored', () {
      final start = last.add(const Duration(days: 7));
      expect(
        status(
          LifecycleState.ready,
          last.subtract(const Duration(days: 5)),
          Duration.zero,
          start: start,
        ),
        ContestDisplayStatus.upcoming,
      );
      expect(
        status(
          LifecycleState.ready,
          last,
          const Duration(days: 7, hours: 47),
          start: start,
        ),
        ContestDisplayStatus.inProgress,
        reason: 'the clock starts at the start, not at the invitations',
      );
      expect(
        status(
          LifecycleState.ready,
          last,
          const Duration(days: 7, hours: 49),
          start: start,
        ),
        ContestDisplayStatus.completed,
      );
    });

    test('a Completed contest is completed even before its start', () {
      expect(
        status(
          LifecycleState.completed,
          null,
          Duration.zero,
          start: last.add(const Duration(days: 1)),
        ),
        ContestDisplayStatus.completed,
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
      expect(ContestDisplayStatus.upcoming.wireName, 'upcoming');
    });
  });
}
