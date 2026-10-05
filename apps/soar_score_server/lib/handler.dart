import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_data/soar_score_data.dart';

const String serverName = 'soar_score_server';
const String serverDisplayName = 'Soar Score API Server';
const String serverVersion = '0.1.0';

/// Builds the top-level [Handler] for the deployed API server.
///
/// Wires the shared routing and middleware from `soar_score_api_handlers` to
/// the repositories of [database] and reports the server's identity for the
/// `/health` payload.
Handler createServerHandler(SoarScoreDatabase database) {
  return buildApiHandler(
    name: serverName,
    displayName: serverDisplayName,
    version: serverVersion,
    repository: Repository(database),
  );
}
