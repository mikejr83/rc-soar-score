import 'dart:async';

import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_sync/soar_score_sync.dart';
import 'package:test/test.dart';

import 'support/fake_gateway.dart';
import 'support/fixtures.dart';

/// A timer the test fires by hand.
class ManualTimer implements Timer {
  ManualTimer(this.delay, this._run);

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
  late Rig rig;
  late List<ManualTimer> timers;
  late SyncScheduler scheduler;

  setUp(() {
    rig = Rig();
    timers = [];
    scheduler = SyncScheduler(
      rig.engine,
      window: const Duration(milliseconds: 500),
      maxBackoff: const Duration(seconds: 4),
      timerFactory: (delay, run) {
        final timer = ManualTimer(delay, run);
        timers.add(timer);
        return timer;
      },
    );
    addTearDown(scheduler.dispose);
  });

  List<ManualTimer> active() => timers.where((t) => t.isActive).toList();

  test('a burst of changes becomes one sync after the window', () async {
    scheduler
      ..notifyLocalChange(scope)
      ..notifyLocalChange(scope)
      ..notifyLocalChange(scope);

    expect(active(), hasLength(1));
    expect(active().single.delay, const Duration(milliseconds: 500));

    active().single.fire();
    await Future<void>.delayed(Duration.zero);
    await rig.engine.syncScope(scope); // waits for the queued sync to finish

    // One scheduled sync plus the one awaited above.
    expect(rig.gateway.infoCalls, 1);
    expect(rig.gateway.exchanges.length, 2);
  });

  test('a change after the sync started schedules the next one', () async {
    scheduler.notifyLocalChange(scope);
    active().single.fire();
    scheduler.notifyLocalChange(scope);

    expect(active(), hasLength(1));
  });

  test('scopes are scheduled separately', () {
    scheduler
      ..notifyLocalChange(scope)
      ..notifyLocalChange(DirectorScopeKey(idN(5)));

    expect(active(), hasLength(2));
  });

  test('a server error retries with a growing delay, up to the cap', () async {
    rig.gateway.onExchange = (_) async => throw httpError(500);
    scheduler.notifyLocalChange(scope);

    final delays = <Duration>[];
    for (var i = 0; i < 4; i++) {
      active().single.fire();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      delays.add(active().single.delay);
    }

    expect(delays, [
      const Duration(seconds: 1),
      const Duration(seconds: 2),
      const Duration(seconds: 4),
      const Duration(seconds: 4),
    ]);
  });

  test(
    'an offline failure waits for connectivity instead of retrying',
    () async {
      rig.gateway.onExchange = (_) async =>
          throw ApiNetworkError('down', requestUri: Uri.parse('http://x'));
      scheduler.notifyLocalChange(scope);

      active().single.fire();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(active(), isEmpty);

      rig.gateway.onExchange = (_) async => FakeGateway.response();
      scheduler.connectivityRestored();
      expect(active().single.delay, Duration.zero);
    },
  );

  test('connectivityRestored syncs every scope seen so far', () {
    scheduler
      ..notifyLocalChange(scope)
      ..notifyLocalChange(DirectorScopeKey(idN(5)));
    for (final timer in active()) {
      timer.cancel();
    }

    scheduler.connectivityRestored();

    expect(active(), hasLength(2));
  });

  test('nothing is scheduled after dispose', () {
    scheduler
      ..dispose()
      ..notifyLocalChange(scope);

    expect(active(), isEmpty);
  });
}
