import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:test/test.dart';

void main() {
  var now = DateTime.utc(2026, 11, 5, 12);
  FailureRateLimiter make({int max = 3, int maxKeys = 100}) =>
      FailureRateLimiter(
        maxFailures: max,
        window: const Duration(minutes: 10),
        maxKeys: maxKeys,
        clock: () => now,
      );
  setUp(() => now = DateTime.utc(2026, 11, 5, 12));

  test('blocks a key from its last allowed failure until the window ends', () {
    final limiter = make();
    limiter.recordFailure('a');
    limiter.recordFailure('a');
    expect(limiter.blockedFor('a'), isNull);
    limiter.recordFailure('a');
    expect(limiter.blockedFor('a'), const Duration(minutes: 10));
    expect(limiter.blockedFor('b'), isNull);
    now = now.add(const Duration(minutes: 4));
    expect(limiter.blockedFor('a'), const Duration(minutes: 6));
    now = now.add(const Duration(minutes: 6));
    expect(limiter.blockedFor('a'), isNull);
  });

  test('a new window starts counting from zero', () {
    final limiter = make(max: 2);
    limiter.recordFailure('a');
    now = now.add(const Duration(minutes: 11));
    limiter.recordFailure('a');
    expect(limiter.blockedFor('a'), isNull);
  });

  test('remembers a bounded number of keys', () {
    final limiter = make(max: 1, maxKeys: 2);
    for (final key in ['a', 'b', 'c']) {
      limiter.recordFailure(key);
    }
    expect(limiter.blockedFor('c'), isNotNull);
    expect(limiter.blockedFor('a'), isNull);
  });
}
