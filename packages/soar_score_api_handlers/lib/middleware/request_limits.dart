/// Limits on how much one request may carry and how often one caller may ask
/// for expensive work.
library;

/// The most bytes a JSON request body may hold unless a route sets its own
/// limit. The largest ordinary body (a bulk score entry of 100 entries, a
/// contest configuration) is far below this.
const int defaultMaxBodyBytes = 1024 * 1024;

/// The most bytes a `POST /sync/exchange` body may hold. A director's first
/// upload of the largest contest we support (100 pilots, 6 to 8 rounds) sends
/// every row of it in one exchange.
const int syncExchangeMaxBodyBytes = 16 * 1024 * 1024;

/// The most mutations one `POST /sync/exchange` may carry.
const int syncExchangeMaxMutations = 10000;

/// The request body is larger than the route allows (413).
class PayloadTooLargeError implements Exception {
  const PayloadTooLargeError(this.maxBytes);

  /// The limit that was exceeded.
  final int maxBytes;

  String get message =>
      'The request body is larger than the $maxBytes bytes this route takes.';

  @override
  String toString() => 'PayloadTooLargeError: $message';
}

/// The caller asked for expensive work too often (429).
class TooManyRequestsError implements Exception {
  const TooManyRequestsError(this.retryAfter);

  /// How long until the caller may ask again.
  final Duration retryAfter;

  @override
  String toString() =>
      'TooManyRequestsError: try again in ${retryAfter.inSeconds + 1} seconds';
}

/// Allows each key [maxRequests] in every [window] (a fixed window that
/// starts with the key's first request).
///
/// Guards routes that cost the server real work (a draw, a recalculation,
/// the participant results) per account or guest session. It counts in
/// memory, so each server instance counts for itself and a restart forgets
/// the counts; that bounds what one caller can make a single machine do,
/// which is the point.
class RequestRateLimiter {
  RequestRateLimiter({
    required this.maxRequests,
    this.window = const Duration(minutes: 1),
    this.maxKeys = 10000,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int maxRequests;
  final Duration window;

  /// Most keys remembered; expired ones are dropped first when it is hit.
  final int maxKeys;
  final DateTime Function() _clock;
  final Map<String, ({DateTime since, int count})> _counts = {};

  /// Counts a request by [key]; throws [TooManyRequestsError] when the key
  /// has used its budget for the window.
  void check(String key) {
    final now = _clock();
    final entry = _counts[key];
    if (entry == null || !now.isBefore(entry.since.add(window))) {
      if (_counts.length >= maxKeys) {
        _counts.removeWhere((_, e) => !now.isBefore(e.since.add(window)));
        if (_counts.length >= maxKeys) _counts.remove(_counts.keys.first);
      }
      _counts[key] = (since: now, count: 1);
      return;
    }
    if (entry.count >= maxRequests) {
      throw TooManyRequestsError(entry.since.add(window).difference(now));
    }
    _counts[key] = (since: entry.since, count: entry.count + 1);
  }
}
