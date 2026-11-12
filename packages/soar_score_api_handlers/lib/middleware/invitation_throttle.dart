import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:soar_score_core/soar_score_core.dart' show RequestThrottleStore;

import 'failure_rate_limiter.dart';

final _logger = Logger('InvitationThrottle');

/// The limits on opening invitation links, per caller address.
///
/// Two counters, both fixed windows of [window]:
///
/// - Every request counts as an attempt, so a flood of malformed bodies or of
///   valid redemptions is limited, not only wrong credentials. [maxAttempts]
///   is generous: a whole contest can scan their cards from one venue network
///   (100 pilots opening a link, two or three times each, is well under it).
/// - A request that does not open a link (unknown, expired or malformed
///   credential, or a body that is not a valid request) is also a failure.
///   From the [maxFailures]th failure the address is blocked until its window
///   ends. Credentials carry 192 random bits, so guessing one is hopeless;
///   the failure limit keeps a stuck script cheap to ignore, while a venue
///   sees a handful of failures (an expired link scanned twice).
///
/// The counts live in [store] (the service database), so every machine counts
/// together and a restart forgets nothing. Callers are stored as a keyed hash
/// ([keySecret]), never as addresses. If the store fails, this instance falls
/// back to counting in memory and logs a warning: a pilot at the field is
/// never refused because the database hiccuped. With no store (the embedded
/// instance, tests) it counts in memory only.
class InvitationThrottle {
  InvitationThrottle({
    this.store,
    String? keySecret,
    this.maxAttempts = 300,
    this.maxFailures = 20,
    this.window = const Duration(minutes: 10),
    DateTime Function()? clock,
  }) : _keySecret = utf8.encode(keySecret ?? 'soar-score-invitation-throttle'),
       _clock = clock ?? DateTime.now,
       _memoryAttempts = FailureRateLimiter(
         // The limiter blocks at its maxFailures-th count; a request is
         // refused when its count is above maxAttempts.
         maxFailures: maxAttempts + 1,
         window: window,
         clock: clock,
       ),
       _memoryFailures = FailureRateLimiter(
         maxFailures: maxFailures,
         window: window,
         clock: clock,
       );

  final RequestThrottleStore? store;
  final int maxAttempts;
  final int maxFailures;
  final Duration window;
  final List<int> _keySecret;
  final DateTime Function() _clock;
  final FailureRateLimiter _memoryAttempts;
  final FailureRateLimiter _memoryFailures;
  DateTime? _lastPurge;
  DateTime? _lastWarning;

  static const _attempts = 'invitation-attempts';
  static const _failures = 'invitation-failures';

  /// Counts an attempt by [address] and returns how long it must wait, or
  /// null when it may go on. Call it before reading the request body.
  Future<Duration?> admit(String address) async {
    final caller = _caller(address);
    final shared = store;
    if (shared != null) {
      try {
        final attempt = await shared.hit(_attempts, caller, window: window);
        final failed = await shared.read(_failures, caller, window: window);
        await _purge(shared);
        if (attempt.count > maxAttempts) return _remaining(attempt.windowStart);
        if (failed != null && failed.count >= maxFailures) {
          return _remaining(failed.windowStart);
        }
        return null;
      } on Object catch (error) {
        _storeFailed(error);
      }
    }
    _memoryAttempts.recordFailure(caller);
    final waits = [
      _memoryAttempts.blockedFor(caller),
      _memoryFailures.blockedFor(caller),
    ].nonNulls;
    return waits.isEmpty ? null : waits.reduce((a, b) => a > b ? a : b);
  }

  /// Counts a request by [address] that did not open a link.
  Future<void> recordFailure(String address) async {
    final caller = _caller(address);
    final shared = store;
    if (shared != null) {
      try {
        await shared.hit(_failures, caller, window: window);
        return;
      } on Object catch (error) {
        _storeFailed(error);
      }
    }
    _memoryFailures.recordFailure(caller);
  }

  Duration _remaining(DateTime windowStart) {
    final left = windowStart.add(window).difference(_clock());
    return left.isNegative ? Duration.zero : left;
  }

  /// Deletes expired counters, at most once a window per instance.
  Future<void> _purge(RequestThrottleStore shared) async {
    final now = _clock();
    final last = _lastPurge;
    if (last != null && now.difference(last) < window) return;
    _lastPurge = now;
    await shared.purgeBefore(now.subtract(window));
  }

  void _storeFailed(Object error) {
    final now = _clock();
    final last = _lastWarning;
    if (last != null && now.difference(last) < const Duration(minutes: 1)) {
      return;
    }
    _lastWarning = now;
    // Never the error text itself: it can carry statement arguments.
    _logger.warning(
      'The throttle store failed (${error.runtimeType}); '
      'counting in memory on this instance.',
    );
  }

  /// A keyed hash of [address], so no address reaches the store.
  String _caller(String address) => Hmac(
    sha256,
    _keySecret,
  ).convert(utf8.encode(address)).toString().substring(0, 32);
}
