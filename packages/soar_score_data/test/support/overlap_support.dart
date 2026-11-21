import 'dart:async';

/// Completes [release] if it is still pending, then waits for every started
/// operation in [started] to end, ignoring how they end so that cleanup never
/// hides the failure that led to it.
Future<void> settleStarted(
  Iterable<Completer<void>> releases,
  Iterable<Future<Object?>?> started,
) async {
  for (final release in releases) {
    if (!release.isCompleted) release.complete();
  }
  for (final operation in started) {
    if (operation == null) continue;
    try {
      await operation;
    } on Object {
      // reported by the test body, or by nobody when it was never awaited
    }
  }
}

/// Waits until [ready] completes, or fails with what [operation] failed with
/// when it ends first, so an operation that fails before it signals readiness
/// surfaces its own error instead of a test timeout.
Future<void> readyOrDone(Future<void> ready, Future<Object?> operation) async {
  final ended = operation.then<void>(
    (_) => throw StateError('the operation ended before it signalled ready'),
  );
  // Whichever loses the race must not report an unhandled error later.
  ended.ignore();
  ready.ignore();
  await Future.any<void>([ready, ended]);
}
