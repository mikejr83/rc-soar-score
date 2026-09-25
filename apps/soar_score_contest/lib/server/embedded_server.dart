import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

const String embeddedServerName = 'soar_score_contest';
const String embeddedServerDisplayName = 'Soar Score Contest (Offline)';
const String embeddedServerVersion = '0.1.0';

/// An in-process instance of the Soar Score API served by the Windows build
/// of `soar_score_contest` (ticket 018).
///
/// Bound to `localhost` on an OS-assigned free port so concurrent instances
/// can never conflict; [baseUrl] is the loopback address the app's own
/// `ApiClient` (from `soar_score_api`) is pointed at.
class EmbeddedServer {
  EmbeddedServer._(this._databasePath);

  final String _databasePath;
  late HttpServer _server;
  late SoarScoreDatabase _database;
  late core.Repository _repository;

  /// The OS-assigned port the local socket is bound to.
  int get port => _server.port;

  /// The loopback base URL the app's `ApiClient` should target.
  Uri get baseUrl => Uri.parse('http://localhost:$port');

  core.Repository get repository => _repository;

  Future<void> initializeDatabase() async {
    final dbPath = File(_databasePath);
    await dbPath.parent.create(recursive: true);
    _database = createLocalDatabase(dbPath);
  }

  Future<void> initialize() async {
    _repository = Repository(ContestRepository(_database));

    final handler = buildApiHandler(
      name: embeddedServerName,
      displayName: embeddedServerDisplayName,
      version: embeddedServerVersion,
      schemaRevision: _database.schemaVersion,
      repository: _repository,
    );
    _server = await shelf_io.serve(handler, 'localhost', 0);
  }

  /// Shuts down the HTTP server and closes the local database, releasing the
  /// port and the SQLite file handle.
  Future<void> close() async {
    await _server.close(force: true);
    await _database.close();
  }
}

/// Opens the local SQLite database at [databasePath] (parent directories are
/// created if needed) and starts the embedded API on `localhost` with an
/// OS-assigned free port (port `0` is passed to `shelf_io.serve`).
///
/// The embedded instance is always unauthenticated: the shared
/// `buildApiHandler` factory is called without an `authMiddleware`, per the
/// decision recorded on ticket 017.
Future<EmbeddedServer> startEmbeddedServer(String databasePath) async {
  final server = EmbeddedServer._(databasePath);
  await server.initializeDatabase();
  await server.initialize();
  return server;
}
