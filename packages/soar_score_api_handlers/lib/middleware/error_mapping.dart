import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'request_id.dart';

final _logger = Logger('Errors');

/// Builds the standard JSON error response:
/// `{"error": {"code", "message", "requestId"}}`.
Response errorResponse(
  int statusCode,
  String code,
  String message, {
  String? requestId,
}) => Response(
  statusCode,
  body: jsonEncode({
    'error': {'code': code, 'message': message, 'requestId': requestId},
  }),
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Flattens [text] to a single, bounded line for the log: control characters
/// (including newlines) become spaces and the result is cut off, so a message
/// can never forge an extra log line.
String _oneLine(String text) {
  const max = 500;
  final flat = text.replaceAll(RegExp(r'[\u0000-\u001F]'), ' ').trim();
  return flat.length <= max ? flat : flat.substring(0, max);
}

/// Logs one warning line for a handled error and answers with the JSON
/// error response.
///
/// The line carries the method and path without its query string, the status,
/// the error code and the request id, so an unexpected 400 or 404 leaves a
/// trace. Query strings and headers are left out, so secrets never reach the
/// log. The message is the exception's own text, not its stack, flattened to
/// one line and truncated so it cannot forge extra log lines. Stacks stay in
/// the log only for the unexpected 500 branch, which does not use this.
Response handledError(
  Request request,
  int statusCode,
  String code,
  String message,
) {
  final requestId = requestIdOf(request);
  _logger.warning(
    '$statusCode on ${request.method} /${request.url.path} '
    'code=$code request=$requestId message=${_oneLine(message)}',
  );
  return errorResponse(statusCode, code, message, requestId: requestId);
}

/// Turns thrown errors and bare 404s into the standard JSON error body.
///
/// - `SyncRefusal`: its own status and code (426, 409, 403, 410)
/// - `AccountClaimError`: 409 with its code
/// - `GliderScoreImportError`: its own status (503, 404, 415, 422) and code
/// - `StaleRevisionError`, `AlreadyStoredError`, `AlreadySupersededError`,
///   `ContestStateError`, `BackendOnlyError` (code `backend_only`): 409
/// - `ForbiddenError`: 403
/// - `EntityNotFoundError`: 404
/// - `ArgumentError`, `FormatException`, `ScoringValidationError`: 400
/// - an unmatched route: 404
/// - anything else: 500 with a generic message. The details go to the log
///   only, so a response never leaks a stack trace or SQL.
Middleware errorMappingMiddleware() =>
    (inner) => (request) async {
      try {
        final response = await inner(request);
        if (response.statusCode == 404 &&
            !(response.headers['content-type'] ?? '').contains('json')) {
          return handledError(request, 404, 'not_found', 'No such route.');
        }
        return response;
      } on HijackException {
        rethrow;
      } on EntityNotFoundError catch (e) {
        return handledError(request, 404, 'not_found', '$e');
      } on ForbiddenError catch (e) {
        return handledError(request, 403, e.code, e.message);
      } on SyncRefusal catch (e) {
        return handledError(request, e.statusCode, e.code, e.message);
      } on AccountClaimError catch (e) {
        return handledError(request, 409, e.code, e.message);
      } on GliderScoreImportError catch (e) {
        return handledError(request, e.statusCode, e.code, e.message);
      } on BackendOnlyError catch (e) {
        return handledError(request, 409, 'backend_only', '$e');
      } on ContestStateError catch (e) {
        return handledError(request, 409, e.code, e.message);
      } on StaleRevisionError catch (e) {
        return handledError(request, 409, 'stale_revision', '$e');
      } on AlreadyStoredError catch (e) {
        return handledError(request, 409, 'already_stored', '$e');
      } on AlreadySupersededError catch (e) {
        return handledError(request, 409, 'already_superseded', '$e');
      } on ScoringValidationError catch (e) {
        return handledError(request, 400, 'invalid_request', '$e');
      } on ArgumentError catch (e) {
        return handledError(
          request,
          400,
          'invalid_request',
          e.message ?? e.toString(),
        );
      } on FormatException catch (e) {
        return handledError(request, 400, 'invalid_request', e.message);
      } catch (e, stack) {
        final requestId = requestIdOf(request);
        _logger.severe('Unhandled error (request $requestId)', e, stack);
        return errorResponse(
          500,
          'internal_error',
          'Something went wrong on the server.',
          requestId: requestId,
        );
      }
    };
