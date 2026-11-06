/// Counts failed attempts per key and says when a key has had too many.
///
/// Guards the invitation resolve route against credential guessing. It keeps
/// its counts in memory, so each server instance counts for itself and a
/// restart or a scale-to-zero stop forgets them; with credentials that carry
/// 192 bits of unguessable tag, that only slows an attacker further and costs
/// nothing to keep simple. A key is blocked from its [maxFailures]th failure
/// until [window] after its first failure in the current window.
class FailureRateLimiter {
  FailureRateLimiter({
    this.maxFailures = 20,
    this.window = const Duration(minutes: 10),
    this.maxKeys = 10000,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int maxFailures;
  final Duration window;

  /// Most keys remembered; expired ones are dropped first when it is hit.
  final int maxKeys;
  final DateTime Function() _clock;
  final Map<String, ({DateTime since, int count})> _failures = {};

  /// How long until [key] may try again, or null when it is not blocked.
  Duration? blockedFor(String key) {
    final entry = _failures[key];
    if (entry == null) return null;
    final end = entry.since.add(window);
    final now = _clock();
    if (!now.isBefore(end)) {
      _failures.remove(key);
      return null;
    }
    return entry.count >= maxFailures ? end.difference(now) : null;
  }

  /// Records a failed attempt by [key].
  void recordFailure(String key) {
    final now = _clock();
    final entry = _failures[key];
    if (entry == null || !now.isBefore(entry.since.add(window))) {
      if (_failures.length >= maxKeys) {
        _failures.removeWhere((_, e) => !now.isBefore(e.since.add(window)));
        if (_failures.length >= maxKeys) _failures.remove(_failures.keys.first);
      }
      _failures[key] = (since: now, count: 1);
    } else {
      _failures[key] = (since: entry.since, count: entry.count + 1);
    }
  }
}
