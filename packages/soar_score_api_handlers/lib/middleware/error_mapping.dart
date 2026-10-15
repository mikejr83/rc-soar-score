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
      final requestId = requestIdOf(request);
      try {
        final response = await inner(request);
        if (response.statusCode == 404 &&
            !(response.headers['content-type'] ?? '').contains('json')) {
          return errorResponse(
            404,
            'not_found',
            'No such route.',
            requestId: requestId,
          );
        }
        return response;
      } on HijackException {
        rethrow;
      } on EntityNotFoundError catch (e) {
        return errorResponse(404, 'not_found', '$e', requestId: requestId);
      } on ForbiddenError catch (e) {
        return errorResponse(403, e.code, e.message, requestId: requestId);
      } on SyncRefusal catch (e) {
        return errorResponse(
          e.statusCode,
          e.code,
          e.message,
          requestId: requestId,
        );
      } on AccountClaimError catch (e) {
        return errorResponse(409, e.code, e.message, requestId: requestId);
      } on GliderScoreImportError catch (e) {
        return errorResponse(
          e.statusCode,
          e.code,
          e.message,
          requestId: requestId,
        );
      } on BackendOnlyError catch (e) {
        return errorResponse(409, 'backend_only', '$e', requestId: requestId);
      } on ContestStateError catch (e) {
        return errorResponse(409, e.code, e.message, requestId: requestId);
      } on StaleRevisionError catch (e) {
        return errorResponse(409, 'stale_revision', '$e', requestId: requestId);
      } on AlreadyStoredError catch (e) {
        return errorResponse(409, 'already_stored', '$e', requestId: requestId);
      } on AlreadySupersededError catch (e) {
        return errorResponse(
          409,
          'already_superseded',
          '$e',
          requestId: requestId,
        );
      } on ScoringValidationError catch (e) {
        return errorResponse(
          400,
          'invalid_request',
          '$e',
          requestId: requestId,
        );
      } on ArgumentError catch (e) {
        return errorResponse(
          400,
          'invalid_request',
          '${e.message}',
          requestId: requestId,
        );
      } on FormatException catch (e) {
        return errorResponse(
          400,
          'invalid_request',
          e.message,
          requestId: requestId,
        );
      } catch (e, stack) {
        _logger.severe('Unhandled error (request $requestId)', e, stack);
        return errorResponse(
          500,
          'internal_error',
          'Something went wrong on the server.',
          requestId: requestId,
        );
      }
    };
