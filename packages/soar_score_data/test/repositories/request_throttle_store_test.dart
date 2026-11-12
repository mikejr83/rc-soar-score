import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  late RequestThrottleStore store;
  final start = DateTime.utc(2026, 11, 12, 12);
  const window = Duration(minutes: 10);

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    store = RequestThrottleStore(inst.db);
  });
  tearDown(() => inst.close());

  test('counts hits per bucket and caller', () async {
    for (var i = 1; i <= 3; i++) {
      final seen = await store.hit('a', 'x', window: window, now: start);
      expect(seen.count, i);
      expect(seen.windowStart, start);
    }
    expect((await store.hit('a', 'y', window: window, now: start)).count, 1);
    expect((await store.hit('b', 'x', window: window, now: start)).count, 1);
    expect((await store.read('a', 'x', window: window, now: start))!.count, 3);
    expect(await store.read('a', 'z', window: window, now: start), isNull);
  });

  test('read counts nothing', () async {
    await store.hit('a', 'x', window: window, now: start);
    await store.read('a', 'x', window: window, now: start);
    expect((await store.hit('a', 'x', window: window, now: start)).count, 2);
  });

  test(
    'the window ends window after it began; the next hit starts anew',
    () async {
      await store.hit('a', 'x', window: window, now: start);
      await store.hit(
        'a',
        'x',
        window: window,
        now: start.add(const Duration(minutes: 9)),
      );
      final end = start.add(window);
      expect(
        await store.read('a', 'x', window: window, now: end),
        isNull,
        reason: 'the window is over',
      );
      final fresh = await store.hit('a', 'x', window: window, now: end);
      expect(fresh.count, 1);
      expect(fresh.windowStart, end);
    },
  );

  test('concurrent hits all count', () async {
    final counts = await Future.wait([
      for (var i = 0; i < 25; i++)
        store.hit('a', 'x', window: window, now: start),
    ]);
    expect(
      {for (final c in counts) c.count},
      {for (var i = 1; i <= 25; i++) i},
    );
  });

  test('purges counters whose window began before the cutoff', () async {
    await store.hit('a', 'old', window: window, now: start);
    await store.hit(
      'a',
      'new',
      window: window,
      now: start.add(const Duration(minutes: 5)),
    );
    await store.purgeBefore(start.add(const Duration(minutes: 1)));
    final at = start.add(const Duration(minutes: 6));
    expect(await store.read('a', 'old', window: window, now: at), isNull);
    expect((await store.read('a', 'new', window: window, now: at))!.count, 1);
  });

  test('keeps sub-millisecond time out of the stored window', () async {
    final odd = start.add(const Duration(microseconds: 1234));
    final first = await store.hit('a', 'x', window: window, now: odd);
    expect(first.windowStart, start.add(const Duration(milliseconds: 1)));
    expect((await store.hit('a', 'x', window: window, now: odd)).count, 2);
  });
}
