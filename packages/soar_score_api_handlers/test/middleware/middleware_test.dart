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
      final records = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(records.add);
      addTearDown(sub.cancel);

      final response = await failing(StateError('password=hunter2 in SQL'));

      expect(response.statusCode, 500);
      final error = await errorOf(response);
      expect(jsonEncode(error), isNot(contains('hunter2')));
      expect(error['code'], 'internal_error');
      expect(
        records.any((r) => r.level == Level.SEVERE && r.error is StateError),
        isTrue,
      );
    });
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
