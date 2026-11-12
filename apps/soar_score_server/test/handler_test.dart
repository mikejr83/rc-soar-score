import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/handler.dart';
import 'package:test/test.dart';

/// Wiring-level tests for the deployed server after the routing was
/// extracted to `soar_score_api_handlers` (ticket 017).
///
/// These exercise that `createServerHandler` wires the PostgreSQL database
/// into the shared factory and serves the expected response. Because the
/// deployed server is Postgres-backed, this suite skips when no instance is
/// configured (`DATABASE_URL` and `POSTGRES_PASSWORD` unset). Route behavior
/// itself (payloads, 404s, the auth seam) is covered in-process by
/// `soar_score_api_handlers`' own test suite.
void main() {
  final config = PostgresConfig.fromEnvironment();

  test('reports and enforces the actual database schema version', () async {
    final database = createInMemoryDatabase();
    addTearDown(database.close);
    final account = Id.create();
    final handler = createServerHandler(
      database,
      authMiddleware: fixedPrincipal(Principal(accountId: account)),
    );
    final health = await handler(
      Request('GET', Uri.parse('http://localhost/health')),
    );
    expect(
      (jsonDecode(await health.readAsString()) as Map)['schemaRevision'],
      database.schemaVersion,
    );
    final versions = await handler(
      Request('GET', Uri.parse('http://localhost/api/v1/sync/info')),
    );
    expect(versions.statusCode, 200);
    final body = jsonDecode(await versions.readAsString()) as Map;
    expect(body['min_schema_version'], database.schemaVersion);
    expect(body['max_schema_version'], database.schemaVersion);
    final oldClient = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/sync/exchange'),
        body: jsonEncode({
          'protocol_version': 1,
          'schema_version': 1,
          'installation_id': Id.create().value,
          'scope': {'owner_account_id': account.value},
          'last_acknowledged_sequence': 0,
          'mutations': <Object?>[],
        }),
      ),
    );
    expect(oldClient.statusCode, 426);
    final refusal = jsonDecode(await oldClient.readAsString()) as Map;
    expect((refusal['error'] as Map)['code'], 'schema_too_old');
  });

  group(
    'createServerHandler wiring',
    () {
      late Handler handler;

      setUp(() {
        handler = createServerHandler(
          createPostgresDatabase(config!),
          authMiddleware: (inner) => inner,
        );
      });

      test('serves the /health payload through the extracted handler '
          'and PostgreSQL-backed repository', () async {
        final response = await handler(
          Request('GET', Uri.parse('http://localhost/health')),
        );

        expect(response.statusCode, 200);
        expect(response.headers['content-type'], contains('application/json'));
        expect(jsonDecode(await response.readAsString()), {
          'name': 'soar_score_server',
          'displayName': 'Soar Score API Server',
          'version': '0.1.0',
          'schemaRevision': 2,
        });
      });
    },
    skip: config == null
        ? 'no PostgreSQL instance configured (set DATABASE_URL or POSTGRES_PASSWORD for local setup)'
        : null,
  );
}
