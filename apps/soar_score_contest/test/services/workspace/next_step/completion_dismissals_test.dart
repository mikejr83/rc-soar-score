import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/next_step/completion_dismissals.dart';

final _t0 = DateTime.utc(2026, 10, 17, 14);
final _score = DateTime.utc(2026, 10, 17, 13);

void main() {
  test('nothing is dismissed at first', () {
    expect(
      CompletionDismissals().isDismissed('c1', latestScoreAt: _score, now: _t0),
      isFalse,
    );
  });

  test('a dismissal holds for the same score within 48 hours', () {
    final dismissals = CompletionDismissals()
      ..dismiss('c1', latestScoreAt: _score, now: _t0);
    expect(
      dismissals.isDismissed(
        'c1',
        latestScoreAt: _score,
        now: _t0.add(const Duration(hours: 47, minutes: 59)),
      ),
      isTrue,
    );
  });

  test('it ends after another 48 hours', () {
    final dismissals = CompletionDismissals()
      ..dismiss('c1', latestScoreAt: _score, now: _t0);
    expect(
      dismissals.isDismissed(
        'c1',
        latestScoreAt: _score,
        now: _t0.add(const Duration(hours: 48)),
      ),
      isFalse,
    );
  });

  test('it ends when a newer score arrives', () {
    final dismissals = CompletionDismissals()
      ..dismiss('c1', latestScoreAt: _score, now: _t0);
    expect(
      dismissals.isDismissed(
        'c1',
        latestScoreAt: _t0.add(const Duration(minutes: 5)),
        now: _t0.add(const Duration(minutes: 10)),
      ),
      isFalse,
    );
  });

  test('a contest with no scores can be dismissed too', () {
    final dismissals = CompletionDismissals()..dismiss('c1', now: _t0);
    expect(dismissals.isDismissed('c1', latestScoreAt: null, now: _t0), isTrue);
  });

  test('dismissals are per contest', () {
    final dismissals = CompletionDismissals()
      ..dismiss('c1', latestScoreAt: _score, now: _t0);
    expect(
      dismissals.isDismissed('c2', latestScoreAt: _score, now: _t0),
      isFalse,
    );
  });
}
