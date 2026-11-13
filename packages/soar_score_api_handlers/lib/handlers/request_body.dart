import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:shelf/shelf.dart';

import '../middleware/request_limits.dart';

/// Reads the JSON object in the body of [request] and builds a request DTO
/// from it with [fromJson].
///
/// Every way the body can be wrong (not JSON, not an object, a missing or
/// mistyped field, an invalid id or date) is an [ArgumentError], which the
/// error middleware answers with 400.
///
/// A body over [maxBytes] is a [PayloadTooLargeError] (413), refused from the
/// declared length or, for a body without one, as soon as the bytes read pass
/// the limit: nothing is decoded or parsed first.
///
/// With [within], a body not complete by then throws a [TimeoutException].
/// A read that fails for being too slow stops keeping or parsing what arrives
/// but is not cancelled: cancelling the request stream can close the
/// connection before the error response is sent, so the rest is read and
/// dropped, up to [maxBytes] in all (past that the read is cancelled).
Future<T> readJsonBody<T>(
  Request request,
  T Function(Map<String, dynamic> json) fromJson, {
  int maxBytes = defaultMaxBodyBytes,
  Duration? within,
}) async {
  final Object? decoded;
  try {
    decoded = jsonDecode(await _readText(request, maxBytes, within));
  } on FormatException {
    throw ArgumentError('The request body is not valid JSON.');
  }
  if (decoded is! Map<String, dynamic>) {
    throw ArgumentError('The request body must be a JSON object.');
  }
  try {
    return fromJson(decoded);
  } on CheckedFromJsonException catch (e) {
    throw ArgumentError('Invalid "${e.key}": ${e.message}');
  } on ArgumentError catch (e) {
    throw ArgumentError('Invalid request body: ${e.message}');
  } on FormatException catch (e) {
    throw ArgumentError('Invalid request body: ${e.message}');
  } on TypeError {
    throw ArgumentError('The request body has a field of the wrong type.');
  }
}

Future<String> _readText(Request request, int maxBytes, Duration? within) {
  final declared = request.contentLength;
  if (declared != null && declared > maxBytes) {
    throw PayloadTooLargeError(maxBytes);
  }
  final bytes = BytesBuilder(copy: false);
  final done = Completer<String>();
  late final StreamSubscription<List<int>> subscription;
  var total = 0;
  Timer? timer;

  void fail(Object error) {
    timer?.cancel();
    bytes.clear();
    if (!done.isCompleted) done.completeError(error);
  }

  subscription = request.read().listen(
    (chunk) {
      total += chunk.length;
      if (total > maxBytes) {
        fail(PayloadTooLargeError(maxBytes));
        subscription.cancel();
        return;
      }
      if (done.isCompleted) return; // failed already: read and drop
      bytes.add(chunk);
    },
    onError: fail,
    onDone: () {
      timer?.cancel();
      if (done.isCompleted) return;
      try {
        done.complete((request.encoding ?? utf8).decode(bytes.takeBytes()));
      } on FormatException catch (e) {
        // Malformed text: the caller answers it like any other bad body.
        done.completeError(e);
      }
    },
    cancelOnError: false,
  );
  if (within != null) {
    timer = Timer(
      within,
      () => fail(TimeoutException('The request body took too long.', within)),
    );
  }
  return done.future;
}
