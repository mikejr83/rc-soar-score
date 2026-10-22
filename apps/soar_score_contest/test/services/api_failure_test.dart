import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/services/api_failure.dart';

ApiHttpError _http(int status, {String? code, String message = 'Nope.'}) =>
    ApiHttpError(
      'failed',
      statusCode: status,
      body: code == null
          ? 'not json'
          : '{"error":{"code":"$code","message":"$message"}}',
      requestUri: Uri.parse('http://localhost/x'),
    );

void main() {
  group('by the server code first', () {
    const byCode = {
      'not_found': ApiFailureKind.notFound,
      'invalid_request': ApiFailureKind.validation,
      'stale_revision': ApiFailureKind.conflict,
      'already_stored': ApiFailureKind.conflict,
      'already_superseded': ApiFailureKind.conflict,
      'internal_error': ApiFailureKind.unavailable,
    };
    byCode.forEach((code, kind) {
      test('$code is $kind whatever the status', () {
        expect(ApiFailure.of(_http(418, code: code)).kind, kind);
      });
    });

    test('keeps the server message', () {
      final failure = ApiFailure.of(_http(409, code: 'stale_revision'));
      expect(failure.message, 'Nope.');
    });
  });

  group('by status without a known code', () {
    test('401 is unauthorized and 403 forbidden', () {
      expect(ApiFailure.of(_http(401)).kind, ApiFailureKind.unauthorized);
      expect(ApiFailure.of(_http(403)).kind, ApiFailureKind.forbidden);
      expect(
        ApiFailure.of(_http(403, code: 'contest_locked')).kind,
        ApiFailureKind.forbidden,
      );
    });

    test('404 is not found and 5xx unavailable', () {
      expect(ApiFailure.of(_http(404)).kind, ApiFailureKind.notFound);
      expect(ApiFailure.of(_http(503)).kind, ApiFailureKind.unavailable);
    });

    test('an unknown 400 or 409 code stays other', () {
      expect(
        ApiFailure.of(_http(409, code: 'publishing_not_available')).kind,
        ApiFailureKind.other,
      );
      expect(ApiFailure.of(_http(400)).kind, ApiFailureKind.other);
    });

    test('a body that is not an error object gets a generic message', () {
      expect(ApiFailure.of(_http(502)).message, 'The request failed (502).');
    });
  });

  test('a network error is unavailable and retryable', () {
    final failure = ApiFailure.of(
      ApiNetworkError('down', requestUri: Uri.parse('http://localhost/x')),
    );
    expect(failure.kind, ApiFailureKind.unavailable);
    expect(failure.retryable, isTrue);
    expect(failure.message, 'The server could not be reached.');
  });

  test('only unavailable failures are retryable', () {
    expect(
      ApiFailure.of(_http(400, code: 'invalid_request')).retryable,
      isFalse,
    );
    expect(ApiFailure.of(_http(401)).retryable, isFalse);
  });

  test('anything else is other with its text', () {
    final failure = ApiFailure.of(StateError('boom'));
    expect(failure.kind, ApiFailureKind.other);
    expect(failure.message, contains('boom'));
  });
}
