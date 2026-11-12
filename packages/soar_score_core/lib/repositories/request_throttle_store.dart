/// A caller's request count in its current window.
class ThrottleCount {
  const ThrottleCount({required this.count, required this.windowStart});

  /// Requests counted since [windowStart], this one included for [RequestThrottleStore.hit].
  final int count;

  /// When the window began; it ends one window length later.
  final DateTime windowStart;

  @override
  String toString() => 'ThrottleCount($count since $windowStart)';
}

/// Counts requests per caller in fixed windows, shared by every server
/// instance that uses the same store.
///
/// Operational state, not an entity: it never syncs and is never exported. A
/// caller is an opaque string (callers pass a keyed hash, never an address).
abstract interface class RequestThrottleStore {
  /// Counts one request by [caller] in [bucket] and returns the count in the
  /// current window. A window that began [window] or more before [now]
  /// (default: the current time) is over, and this request starts a new one.
  /// Atomic: concurrent hits from several instances all count.
  Future<ThrottleCount> hit(
    String bucket,
    String caller, {
    required Duration window,
    DateTime? now,
  });

  /// The count of [caller] in [bucket] in the current window, or null when it
  /// has none (never counted, or the window is over). Counts nothing.
  Future<ThrottleCount?> read(
    String bucket,
    String caller, {
    required Duration window,
    DateTime? now,
  });

  /// Deletes every counter whose window began before [cutoff].
  Future<void> purgeBefore(DateTime cutoff);
}
