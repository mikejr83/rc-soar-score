import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

Future<Response> call(
  Handler inner,
  String path, {
  Map<String, String>? headers,
}) async => withCommonMiddleware(inner)(
  Request('GET', Uri.parse('http://localhost$path'), headers: headers),
);

Future<Map<String, Object?>> errorOf(Response response) async {
  final body =
      jsonDecode(await response.readAsString()) as Map<String, Object?>;
  return body['error'] as Map<String, Object?>;
}

void main() {
  securityHeadersTests();
  group('request id', () {
    Response ok(Request r) => Response.ok('x');

    test('generates an id and echoes it', () async {
      final response = await call(ok, '/a');
      expect(response.headers[requestIdHeader], matches(r'^[0-9a-f]{32}$'));
    });

    test('keeps a valid incoming id', () async {
      final response = await call(
        ok,
        '/a',
        headers: {requestIdHeader: 'client-id-12345'},
      );
      expect(response.headers[requestIdHeader], 'client-id-12345');
    });

    test('replaces an invalid incoming id', () async {
      final response = await call(
        ok,
        '/a',
        headers: {requestIdHeader: 'bad id\twith spaces'},
      );
      expect(response.headers[requestIdHeader], matches(r'^[0-9a-f]{32}$'));
    });

    test('the handler can read the id', () async {
      String? seen;
      final response = await call((r) {
        seen = requestIdOf(r);
        return Response.ok('x');
      }, '/a');
      expect(seen, response.headers[requestIdHeader]);
    });
  });

  group('error mapping', () {
    Future<Response> failing(Object error) => call((r) => throw error, '/a');

    test('maps a backend-only request to 409 backend_only', () async {
      final response = await failing(BackendOnlyError('Account'));
      expect(response.statusCode, 409);
      expect((await errorOf(response))['code'], 'backend_only');
    });

    test('maps a forbidden request to 403 with its code', () async {
      final response = await failing(
        ForbiddenError('not_director', 'only the director'),
      );
      expect(response.statusCode, 403);
      expect((await errorOf(response))['code'], 'not_director');
    });

    test('maps domain conflicts to 409', () async {
      final response = await failing(
        StaleRevisionError(
          entityType: 'Contest',
          entityId: Id.parse('01968c5e-7a3b-7c21-8f4d-2b6a9e1d3c50'),
          expectedRevision: 1,
          storedRevision: 2,
        ),
      );
      expect(response.statusCode, 409);
      final error = await errorOf(response);
      expect(error['code'], 'stale_revision');
      expect(error['requestId'], response.headers[requestIdHeader]);
    });

    test('maps bad input to 400', () async {
      expect((await failing(ArgumentError('nope'))).statusCode, 400);
      expect(
        (await failing(const FormatException('bad json'))).statusCode,
        400,
      );
    });

    test('maps an unknown route to a JSON 404', () async {
      final response = await call(
        (r) => Response.notFound('Route not found'),
        '/a',
      );
      expect(response.statusCode, 404);
      expect((await errorOf(response))['code'], 'not_found');
    });

    test('leaves a handler JSON 404 alone', () async {
      final response = await call(
        (r) => Response(
          404,
          body: '{"error":"x"}',
          headers: {'content-type': 'application/json'},
        ),
        '/a',
      );
      expect(await response.readAsString(), '{"error":"x"}');
    });

    test('hides details of unexpected errors from the response', () async {
      Logger.root.level = Level.ALL;
      final records = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(records.add);
      addTearDown(sub.cancel);

      final response = await failing(StateError('password=hunter2 in SQL'));

      expect(response.statusCode, 500);
      final error = await errorOf(response);
      expect(jsonEncode(error), isNot(contains('hunter2')));
      expect(error['code'], 'internal_error');
      final record = records.firstWhere(
        (r) => r.level == Level.SEVERE && r.error is StateError,
      );
      expect(record.stackTrace, isNotNull);
    });
  });

  group('handled error logging', () {
    Future<Response> failing(Object error) => call((r) => throw error, '/a');

    late List<LogRecord> records;
    late StreamSubscription<LogRecord> sub;

    setUp(() {
      Logger.root.level = Level.ALL;
      records = <LogRecord>[];
      sub = Logger.root.onRecord.listen(records.add);
      addTearDown(sub.cancel);
    });

    List<LogRecord> handled() =>
        records.where((r) => r.loggerName == 'Errors').toList();

    test(
      'writes one warning line for a handled 400, without the query',
      () async {
        final response = await call(
          (r) => throw ArgumentError('bad round number'),
          '/a/b?token=secret',
        );

        expect(response.statusCode, 400);
        expect(handled(), hasLength(1));
        final record = handled().single;
        final line = record.message;
        expect(line, contains('GET /a/b'));
        expect(line, contains('400'));
        expect(line, contains('code=invalid_request'));
        expect(line, contains('request=${response.headers[requestIdHeader]}'));
        expect(line, contains('bad round number'));
        expect(line, isNot(contains('secret')));
        expect(record.level, Level.WARNING);
        expect(record.error, isNull);
        expect(record.stackTrace, isNull);
      },
    );

    test('logs one warning line for every handled 4xx status', () async {
      final id = Id.parse('01968c5e-7a3b-7c21-8f4d-2b5a9e1d3c50');
      final cases = [
        (
          403,
          () => failing(ForbiddenError('not_director', 'only the director')),
        ),
        (
          404,
          () =>
              failing(EntityNotFoundError(entityType: 'Contest', entityId: id)),
        ),
        (
          409,
          () => failing(
            StaleRevisionError(
              entityType: 'Contest',
              entityId: id,
              expectedRevision: 1,
              storedRevision: 2,
            ),
          ),
        ),
      ];

      for (final (status, fire) in cases) {
        final response = await fire();
        expect(response.statusCode, status);
        expect(handled(), hasLength(1));
        final line = handled().single.message;
        expect(line, contains('$status on GET /a'));
        expect(line, contains('request=${response.headers[requestIdHeader]}'));
        records.clear();
      }
    });

    test('logs the unmapped route as a handled 404', () async {
      final response = await call((r) => Response.notFound('x'), '/a');

      expect(response.statusCode, 404);
      expect(handled(), hasLength(1));
      final line = handled().single.message;
      expect(line, contains('code=not_found'));
      expect(line, contains('No such route.'));
      expect(line, contains('request=${response.headers[requestIdHeader]}'));
    });

    test(
      'flattens and truncates the message so it cannot forge a log line',
      () async {
        final body = 'a' * 2000;
        await failing(FormatException('$body\n404 on GET /forge code=evil'));

        expect(handled(), hasLength(1));
        final line = handled().single.message;
        expect(line, isNot(contains('forge')));
        expect(line, isNot(contains('\n')));
      },
    );
  });

  group('request logging', () {
    test(
      'logs method, path, status and request id but not the query',
      () async {
        Logger.root.level = Level.ALL;
        final records = <LogRecord>[];
        final sub = Logger.root.onRecord.listen(records.add);
        addTearDown(sub.cancel);

        final response = await call(
          (r) => Response.ok('x'),
          '/a/b?token=secret',
        );

        final line = records
            .firstWhere((r) => r.loggerName == 'Requests')
            .message;
        expect(line, contains('GET /a/b -> 200'));
        expect(line, contains(response.headers[requestIdHeader]!));
        expect(line, isNot(contains('secret')));
      },
    );

    test('logs server errors at warning level', () async {
      Logger.root.level = Level.ALL;
      final records = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(records.add);
      addTearDown(sub.cancel);

      await call((r) => throw StateError('x'), '/a');

      expect(
        records.firstWhere((r) => r.loggerName == 'Requests').level,
        Level.WARNING,
      );
    });
  });
}

void securityHeadersTests() {
  group('security headers', () {
    Response ok(Request r) => Response.ok('x');

    test('every response is nosniff and noindex', () async {
      final response = await call(ok, '/a');
      expect(response.headers['x-content-type-options'], 'nosniff');
      expect(response.headers['x-robots-tag'], 'noindex, nofollow');
    });

    test('also on mapped errors', () async {
      final response = await call((r) => throw StateError('x'), '/a');
      expect(response.statusCode, 500);
      expect(response.headers['x-content-type-options'], 'nosniff');
    });

    test('/api/v1 is no-store, /public keeps its own cache header', () async {
      expect(
        (await call(ok, '/api/v1/x')).headers['cache-control'],
        'no-store',
      );
      expect((await call(ok, '/public/x')).headers['cache-control'], isNull);
      final cached = await call(
        (r) =>
            Response.ok('x', headers: {'cache-control': 'public, max-age=30'}),
        '/api/v1/x',
      );
      expect(cached.headers['cache-control'], 'public, max-age=30');
    });

    test('robots.txt disallows everything', () async {
      final response = robotsTxtHandler(
        Request('GET', Uri.parse('http://localhost/robots.txt')),
      );
      expect(await response.readAsString(), contains('Disallow: /'));
    });

    test('unknown routes answer a JSON 404', () async {
      final response = await call((r) => Response.notFound('x'), '/nope');
      expect(response.statusCode, 404);
      expect((await errorOf(response))['code'], 'not_found');
    });
  });
}
