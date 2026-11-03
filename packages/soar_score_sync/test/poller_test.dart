import 'dart:async';

import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_sync/soar_score_sync.dart';
import 'package:test/test.dart';

class _ManualTimer implements Timer {
  _ManualTimer(this.delay, this._run);

  final Duration delay;
  final void Function() _run;
  bool cancelled = false;
  bool fired = false;

  void fire() {
    fired = true;
    _run();
  }

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled && !fired;

  @override
  int get tick => 0;
}

void main() {
  late List<_ManualTimer> timers;
  late List<SyncPollFocus> polls;
  late DateTime clock;
  late SyncPoller poller;

  setUp(() {
    timers = [];
    polls = [];
    clock = DateTime.utc(2026, 11, 3, 12);
    poller = SyncPoller(
      onPoll: (focus) async => polls.add(focus),
      timerFactory: (delay, run) {
        final timer = _ManualTimer(delay, run);
        timers.add(timer);
        return timer;
      },
      now: () => clock,
    );
    addTearDown(poller.dispose);
  });

  _ManualTimer active() => timers.singleWhere((t) => t.isActive);

  test('does nothing until enabled', () {
    poller.synced();
    expect(timers, isEmpty);
  });

  test('outside a contest the check comes after 10 minutes', () {
    poller.enabled = true;
    expect(active().delay, const Duration(minutes: 10));
  });

  test('inside a contest the check comes after 5 minutes', () {
    poller.enabled = true;
    poller.focusChanged(SyncPollContest(Id.create()));
    expect(active().delay, const Duration(minutes: 5));
  });

  test('a sync of any kind pushes the next check back', () {
    poller.enabled = true;
    poller.focusChanged(SyncPollContest(Id.create()));
    clock = clock.add(const Duration(minutes: 3));
    poller.synced();
    expect(active().delay, const Duration(minutes: 5));
  });

  test('moving into a contest uses the time left since the last sync', () {
    poller.enabled = true;
    poller.synced();
    clock = clock.add(const Duration(minutes: 4));
    poller.focusChanged(SyncPollContest(Id.create()));
    expect(active().delay, const Duration(minutes: 1));
  });

  test('an overdue check runs at once', () {
    poller.enabled = true;
    poller.synced();
    clock = clock.add(const Duration(minutes: 30));
    poller.focusChanged(SyncPollContest(Id.create()));
    expect(active().delay, Duration.zero);
  });

  test('a fired check polls the focus and schedules the next', () async {
    final id = Id.create();
    poller.enabled = true;
    poller.focusChanged(SyncPollContest(id));
    active().fire();
    await Future<void>.delayed(Duration.zero);
    expect(polls, [SyncPollContest(id)]);
    expect(active().delay, const Duration(minutes: 5));
  });

  test('disabling or pausing stops the timer', () {
    poller.enabled = true;
    poller.enabled = false;
    expect(timers.where((t) => t.isActive), isEmpty);
    poller.enabled = true;
    poller.paused = true;
    expect(timers.where((t) => t.isActive), isEmpty);
    poller.paused = false;
    expect(active(), isNotNull);
  });

  test('a failing poll does not stop the checks', () async {
    final failing = SyncPoller(
      onPoll: (_) async => throw StateError('boom'),
      timerFactory: (delay, run) {
        final timer = _ManualTimer(delay, run);
        timers.add(timer);
        return timer;
      },
      now: () => clock,
    )..enabled = true;
    addTearDown(failing.dispose);
    active().fire();
    await Future<void>.delayed(Duration.zero);
    expect(active().delay, const Duration(minutes: 10));
  });
}
