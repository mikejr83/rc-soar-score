import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/handler.dart';
import 'package:test/test.dart';

/// Wiring-level tests for the deployed server after the routing was
/// extracted to `soar_score_api_handlers` (ticket 017).
///
/// These exercise that `createServerHandler` wires the PostgreSQL database
/// into the shared factory and serves the expected response. Because the
/// deployed server is Postgres-backed, this suite skips when no instance is
/// configured (`POSTGRES_PASSWORD` unset), matching the skip convention of
/// `soar_score_data_postgres`'s integration tests. Route behavior itself
/// (payloads, 404s, the auth seam) is covered in-process by
/// `soar_score_api_handlers`' own test suite.
void main() {
  final config = PostgresConfig.fromEnvironment();

  group(
    'createServerHandler wiring',
    () {
      late Handler handler;

      setUp(() {
        handler = createServerHandler(createPostgresDatabase(config!));
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
          'schemaRevision': null,
        });
      });
    },
    skip: config == null
        ? 'no PostgreSQL instance configured (set POSTGRES_PASSWORD; see the test file doc comments in soar_score_data_postgres for local setup)'
        : null,
  );
}
