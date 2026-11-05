import 'dart:async';

import 'package:shelf/shelf.dart';

/// Counts the requests being handled, so a server can stop taking new ones
/// and wait for the running ones before it closes what they use (the
/// database).
///
/// Closing the HTTP server alone does not do that: a forced close ends the
/// connections at once but leaves handlers already running against the
/// database.
class InFlightRequests {
  int _count = 0;
  bool _closing = false;
  Completer<void>? _idle;

  /// Requests being handled now.
  int get count => _count;

  /// Whether new requests are being refused.
  bool get closing => _closing;

  /// Outermost middleware of the server: counts a request while its handler
  /// runs, and answers 503 once [drain] has started.
  Middleware get middleware =>
      (inner) => (request) async {
        if (_closing) {
          return Response(
            503,
            headers: {'retry-after': '1', 'content-type': 'text/plain'},
            body: 'The server is shutting down.',
          );
        }
        _count++;
        try {
          return await inner(request);
        } finally {
          _count--;
          if (_count == 0) _idle?.complete();
        }
      };

  /// Refuses new requests and waits until the running ones have answered.
  /// Returns false when [timeout] passed first (an abnormal shutdown, where
  /// the caller closes anyway).
  Future<bool> drain({Duration timeout = const Duration(seconds: 10)}) async {
    _closing = true;
    if (_count == 0) return true;
    final idle = _idle ??= Completer<void>();
    try {
      await idle.future.timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    }
  }
}
