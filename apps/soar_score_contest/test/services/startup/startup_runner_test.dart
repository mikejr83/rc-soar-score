import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/startup/startup_mode.dart';
import 'package:soar_score_contest/services/startup/startup_runner.dart';

void main() {
  test('no plan starts at once without a splash', () async {
    final shown = <StartupMode>[];
    final result = await startWithSplash<int>(
      plan: () async => null,
      start: () async => 7,
      showSplash: shown.add,
    );
    expect(result, 7);
    expect(shown, isEmpty);
  });

  test('the splash stays for the minimum even when start is quick', () {
    fakeAsync((async) {
      final shown = <StartupMode>[];
      int? result;
      startWithSplash<int>(
        plan: () async => const StartupPlan(StartupMode.updating),
        start: () async => 3,
        showSplash: shown.add,
        minimum: const Duration(seconds: 5),
      ).then((v) => result = v);
      async.elapse(const Duration(seconds: 4));
      expect(shown, [StartupMode.updating]);
      expect(result, isNull);
      async.elapse(const Duration(seconds: 2));
      expect(result, 3);
    });
  });

  test('a failure is thrown at once, without waiting out the minimum', () {
    fakeAsync((async) {
      Object? error;
      startWithSplash<int>(
        plan: () async => const StartupPlan(StartupMode.initializing),
        start: () async => throw StateError('no database'),
        showSplash: (_) {},
        minimum: const Duration(seconds: 5),
      ).catchError((Object e) {
        error = e;
        return 0;
      });
      async.flushMicrotasks();
      expect(error, isA<StateError>());
    });
  });

  test('a failure after some work still skips the rest of the minimum', () {
    fakeAsync((async) {
      Object? error;
      startWithSplash<int>(
        plan: () async => const StartupPlan(StartupMode.starting),
        // Stands for the bootstrap and the controller preparation.
        start: () async {
          await Future<void>.delayed(const Duration(seconds: 1));
          throw StateError('theme could not load');
        },
        showSplash: (_) {},
        minimum: const Duration(seconds: 5),
      ).catchError((Object e) {
        error = e;
        return 0;
      });
      async.elapse(const Duration(seconds: 2));
      expect(error, isA<StateError>());
    });
  });

  test('a start longer than the minimum adds no extra wait', () {
    fakeAsync((async) {
      int? result;
      startWithSplash<int>(
        plan: () async => const StartupPlan(StartupMode.starting),
        start: () async {
          await Future<void>.delayed(const Duration(seconds: 8));
          return 1;
        },
        showSplash: (_) {},
        minimum: const Duration(seconds: 5),
      ).then((v) => result = v);
      async.elapse(const Duration(seconds: 8));
      expect(result, 1);
    });
  });
}
