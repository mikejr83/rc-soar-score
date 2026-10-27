import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_data/soar_score_data.dart';

/// The API server the web end-to-end tests run against.
///
/// NOT for deployment: it skips token checks, so every request acts as the
/// installation's Local account, exactly like the Windows build's embedded
/// server. It serves a fresh SQLite database with the system data and the
/// demo data, and allows cross-origin calls so the browser build can reach it.
///
///     dart run tool/e2e_server.dart [--port 8080] [--database <file>]
///
/// Without `--database` it uses a new temporary file, deleted on exit. It
/// prints `E2E_SERVER_READY <port>` once it listens; `scripts/e2e` waits for
/// that line.
///
/// Matrix draws are held for a few seconds (`DelayedDrawRunner`) so a journey
/// can see their progress and cancel one.
///
/// `POST /__e2e/fail-next-write` makes the next write (any method but GET,
/// HEAD and OPTIONS) answer 503 once, so a journey can check what the app
/// does when a save fails and then succeeds on Retry. Test-only, like the
/// rest of this server.
Future<void> main(List<String> args) async {
  final port = int.parse(_option(args, '--port') ?? '8080');
  final given = _option(args, '--database');
  final directory = given == null
      ? await Directory.systemTemp.createTemp('soar_score_e2e_')
      : null;
  final file = File(given ?? '${directory!.path}/soar_score_e2e.db');
  if (given != null && file.existsSync()) file.deleteSync();

  final database = createLocalDatabase(file);
  await SystemDataSeeder(database).seed();
  final localAccountId = await LocalAccountRepository(database).ensure();
  final repository = Repository(database);
  await DemoDataSeeder(repository, localAccountId: localAccountId).seed();

  final handler = const Pipeline()
      .addMiddleware(_cors())
      .addMiddleware(_failNextWrite())
      .addHandler(
        buildApiHandler(
          name: 'soar_score_e2e',
          displayName: 'Soar Score E2E test server',
          version: '0.0.0',
          schemaRevision: database.schemaVersion,
          repository: repository,
          authMiddleware: fixedPrincipal(Principal(accountId: localAccountId)),
          // Draws are held a few seconds so a journey can see their progress
          // and cancel one.
          drawRunner: const DelayedDrawRunner(IsolateDrawRunner()),
        ),
      );
  final server = await shelf_io.serve(
    handler,
    InternetAddress.loopbackIPv4,
    port,
  );

  Future<void> stop(ProcessSignal _) async {
    await server.close(force: true);
    await database.close();
    if (directory != null) await directory.delete(recursive: true);
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(stop);
  if (!Platform.isWindows) ProcessSignal.sigterm.watch().listen(stop);
  stdout.writeln('E2E_SERVER_READY ${server.port}');
}

String? _option(List<String> args, String name) {
  final i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': '*',
};

Middleware _cors() =>
    (inner) => (request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final response = await inner(request);
      return response.change(headers: _corsHeaders);
    };

/// See `POST /__e2e/fail-next-write` in the library comment.
Middleware _failNextWrite() {
  var failNext = false;
  return (inner) => (request) async {
    if (request.method == 'POST' &&
        request.url.path == '__e2e/fail-next-write') {
      failNext = true;
      return Response.ok('The next write will fail.');
    }
    final isWrite = !{'GET', 'HEAD', 'OPTIONS'}.contains(request.method);
    if (failNext && isWrite) {
      failNext = false;
      return Response(
        503,
        headers: {'content-type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'error': {
            'code': 'unavailable',
            'message': 'The E2E server was told to fail this write.',
          },
        }),
      );
    }
    return inner(request);
  };
}
