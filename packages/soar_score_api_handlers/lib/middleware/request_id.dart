import 'dart:math';

import 'package:shelf/shelf.dart';

/// Header carrying the request id in requests and responses.
const String requestIdHeader = 'x-request-id';

/// Request context key under which [requestIdMiddleware] stores the id.
const String requestIdContextKey = 'soar_score.requestId';

final _validRequestId = RegExp(r'^[A-Za-z0-9._-]{8,64}$');
final _random = Random.secure();

/// The id [requestIdMiddleware] assigned to [request], or null if it did not
/// run.
String? requestIdOf(Request request) =>
    request.context[requestIdContextKey] as String?;

/// A fresh random request id (128 bits, hex).
String generateRequestId() => List.generate(
  4,
  (_) => _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0'),
).join();

/// Gives every request an id and echoes it in the response.
///
/// An incoming `X-Request-Id` is kept when it is 8 to 64 characters of
/// letters, digits, `.`, `_` or `-`; anything else is replaced, so a caller
/// cannot inject odd text into logs.
Middleware requestIdMiddleware() =>
    (inner) => (request) async {
      final incoming = request.headers[requestIdHeader];
      final id = incoming != null && _validRequestId.hasMatch(incoming)
          ? incoming
          : generateRequestId();
      final response = await inner(
        request.change(context: {requestIdContextKey: id}),
      );
      return response.change(headers: {requestIdHeader: id});
    };
