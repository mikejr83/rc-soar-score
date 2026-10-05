import 'dart:convert';
import 'dart:io';

import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/config/server_config.dart';
import 'package:soar_score_server/server.dart';
import 'package:test/test.dart';

/// Starts [startServer] on a free port against in-memory SQLite, so the
/// composed handler, middleware, hook and shutdown run without PostgreSQL.
void main() {
  late HttpClient client;
  final config = ServerConfig.parse({
    'POSTGRES_PASSWORD': 'unused',
    'PORT': '1',
  });

  setUp(() => client = HttpClient());
  tearDown(() => client.close(force: true));

  Future<(int, Map<String, Object?>, HttpHeaders)> get(
    RunningServer server,
    String path,
  ) async {
    final request = await client.getUrl(
      Uri.parse('http://localhost:${server.port}$path'),
    );
    final response = await request.close();
    final body = jsonDecode(await response.transform(utf8.decoder).join());
    return (
      response.statusCode,
      body as Map<String, Object?>,
      response.headers,
    );
  }

  Future<RunningServer> start({
    void Function(SoarScoreDatabase)? onDatabaseOpen,
  }) => startServer(
    ServerConfig(
      port: 0,
      logLevel: config.logLevel,
      logFormat: config.logFormat,
      postgres: config.postgres,
    ),
    database: createInMemoryDatabase(),
    onDatabaseOpen: onDatabaseOpen,
    address: InternetAddress.loopbackIPv4,
  );

  test('serves /health with a request id', () async {
    final server = await start();
    addTearDown(server.close);

    final (status, body, headers) = await get(server, '/health');

    expect(status, 200);
    expect(body['name'], 'soar_score_server');
    expect(headers.value('x-request-id'), isNotEmpty);
  });

  test('answers an unknown route with the JSON error body', () async {
    final server = await start();
    addTearDown(server.close);

    final (status, body, headers) = await get(server, '/api/v1/nope');

    expect(status, 404);
    final error = body['error'] as Map<String, Object?>;
    expect(error['code'], 'not_found');
    expect(error['requestId'], headers.value('x-request-id'));
  });

  test('runs onDatabaseOpen after the migration and before serving', () async {
    var tableCount = -1;
    final server = await start(
      onDatabaseOpen: (db) async {
        final rows = await db
            .customSelect(
              "SELECT count(*) AS n FROM sqlite_master WHERE type = 'table'",
            )
            .get();
        tableCount = rows.single.read<int>('n');
      },
    );
    addTearDown(server.close);

    expect(tableCount, greaterThan(0));
  });

  test('a failing onDatabaseOpen stops startup', () async {
    await expectLater(
      start(onDatabaseOpen: (_) => throw StateError('seed failed')),
      throwsStateError,
    );
  });

  test('close stops the listener and can be called twice', () async {
    final server = await start();
    final port = server.port;

    await server.close();
    await server.close();

    await expectLater(
      client
          .getUrl(Uri.parse('http://localhost:$port/health'))
          .then((r) => r.close()),
      throwsA(isA<SocketException>()),
    );
  });
}
