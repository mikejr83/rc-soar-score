import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:test/test.dart';

import '../stubs/memory_throttle_store.dart';

void main() {
  var now = DateTime.utc(2026, 11, 12, 12);
  setUp(() => now = DateTime.utc(2026, 11, 12, 12));
  DateTime clock() => now;

  InvitationThrottle make(
    MemoryThrottleStore? store, {
    int attempts = 5,
    int failures = 3,
  }) => InvitationThrottle(
    store: store,
    keySecret: 'a-secret-for-the-test-of-the-keys',
    maxAttempts: attempts,
    maxFailures: failures,
    clock: clock,
  );

  group('with a store', () {
    test('machines sharing a store count together', () async {
      final store = MemoryThrottleStore(clock: clock);
      final one = make(store);
      final two = make(store);
      for (var i = 0; i < 5; i++) {
        expect(await (i.isEven ? one : two).admit('1.1.1.1'), isNull);
      }
      expect(await one.admit('1.1.1.1'), const Duration(minutes: 10));
      expect(await two.admit('1.1.1.1'), isNotNull);
      expect(await two.admit('2.2.2.2'), isNull);
    });

    test('failures from several machines block from the limit', () async {
      final store = MemoryThrottleStore(clock: clock);
      final one = make(store);
      final two = make(store);
      await one.recordFailure('1.1.1.1');
      await two.recordFailure('1.1.1.1');
      expect(await one.admit('1.1.1.1'), isNull);
      await one.recordFailure('1.1.1.1');
      expect(await two.admit('1.1.1.1'), const Duration(minutes: 10));
      now = now.add(const Duration(minutes: 4));
      expect(await two.admit('1.1.1.1'), const Duration(minutes: 6));
      now = now.add(const Duration(minutes: 6));
      expect(await two.admit('1.1.1.1'), isNull);
    });

    test('a new instance sees counts made before it started', () async {
      final store = MemoryThrottleStore(clock: clock);
      for (var i = 0; i < 3; i++) {
        await make(store).recordFailure('1.1.1.1');
      }
      expect(await make(store).admit('1.1.1.1'), isNotNull);
    });

    test('keeps no address in the store and purges expired rows', () async {
      final store = MemoryThrottleStore(clock: clock);
      final throttle = make(store);
      await throttle.admit('203.0.113.7');
      await throttle.recordFailure('203.0.113.7');
      expect(store.rows, 2);
      expect(store.purges, 1);
      now = now.add(const Duration(minutes: 11));
      await throttle.admit('198.51.100.1');
      expect(store.purges, 2);
      expect(store.rows, 1, reason: 'the two expired rows left, one new');
    });

    test('falls back to counting in memory when the store fails', () async {
      final store = MemoryThrottleStore(clock: clock)..failing = true;
      final throttle = make(store, attempts: 2, failures: 2);
      expect(await throttle.admit('1.1.1.1'), isNull);
      expect(await throttle.admit('1.1.1.1'), isNull);
      expect(await throttle.admit('1.1.1.1'), isNotNull);
      await throttle.recordFailure('2.2.2.2');
      await throttle.recordFailure('2.2.2.2');
      expect(await throttle.admit('2.2.2.2'), isNotNull);
    });
  });

  test('without a store it counts in memory', () async {
    final throttle = make(null, attempts: 2);
    expect(await throttle.admit('1.1.1.1'), isNull);
    expect(await throttle.admit('1.1.1.1'), isNull);
    expect(await throttle.admit('1.1.1.1'), isNotNull);
    now = now.add(const Duration(minutes: 11));
    expect(await throttle.admit('1.1.1.1'), isNull);
  });

  test('the defaults leave room for a venue network', () async {
    final throttle = InvitationThrottle(clock: clock);
    // 100 pilots opening a link three times each from one address.
    for (var i = 0; i < 300; i++) {
      expect(await throttle.admit('203.0.113.7'), isNull, reason: '$i');
    }
    // A few wrong links (an expired card) do not block anyone.
    for (var i = 0; i < 10; i++) {
      await throttle.recordFailure('203.0.113.7');
    }
    expect(await InvitationThrottle(clock: clock).admit('203.0.113.7'), isNull);
  });
}
