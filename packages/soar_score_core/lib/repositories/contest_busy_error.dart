/// A contest's score writers could not take their turn in time: the database
/// refused to wait any longer for the contest's gate or a row lock (a lock
/// timeout), or chose this request as the victim of a deadlock.
///
/// Nothing of the request was kept, so it is safe to repeat as it is. The API
/// answers 503 `contest_busy` with a `retry-after`; callers treat it as "try
/// again", never as a failed save.
class ContestBusyError implements Exception {
  const ContestBusyError({
    this.retryAfter = const Duration(seconds: 2),
    this.cause,
  });

  /// How long the caller should wait before it repeats the request.
  final Duration retryAfter;

  /// The database's own error, for the log.
  final Object? cause;

  @override
  String toString() =>
      'ContestBusyError: the contest is busy with another score write, '
      'try again shortly${cause == null ? '' : ' ($cause)'}';
}
