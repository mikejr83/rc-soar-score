import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_data/soar_score_data.dart';

const String serverName = 'soar_score_server';
const String serverDisplayName = 'Soar Score API Server';
const String serverVersion = '0.1.0';

/// Builds the top-level [Handler] for the deployed API server.
///
/// Wires the shared routing from `soar_score_api_handlers` to the
/// PostgreSQL-backed [ContestRepository] (schema migrations run lazily on
/// the first query) and reports the server's identity for the `/health`
/// and `/api/v1/meta` payloads.
Handler createServerHandler(PostgresConfig config) {
  final database = createPostgresDatabase(config);
  
  return buildApiHandler(
    name: serverName,
    displayName: serverDisplayName,
    version: serverVersion,
    repository: Repository(ContestRepository(database)),
  );
}
