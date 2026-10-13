import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

final _logger = Logger('EmbeddedServer');

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
  EmbeddedServer._(this._databasePath, {required this.seedDemo});

  final String _databasePath;

  /// Whether to fill an empty database with the demo data.
  final bool seedDemo;
  late HttpServer _server;
  late SoarScoreDatabase _database;
  late core.Repository _repository;
  late core.Id _localAccountId;

  /// The OS-assigned port the local socket is bound to.
  int get port => _server.port;

  /// The loopback base URL the app's `ApiClient` should target.
  Uri get baseUrl => Uri.parse('http://localhost:$port');

  core.Repository get repository => _repository;

  /// The installation's Local account, which owns the contests created here.
  core.Id get localAccountId => _localAccountId;

  Future<void> initializeDatabase() async {
    final dbPath = File(_databasePath);
    _logger.finer('Using database path: ${dbPath.path}');
    await dbPath.parent.create(recursive: true);
    _database = createLocalDatabase(dbPath);
    // First launch installs the shipped system data so a director who has
    // never synchronized can create and score contests offline. A failure
    // closes the database and reaches the startup failure page, so the app
    // never starts with partial data.
    try {
      await SystemDataSeeder(_database).seed();
      _localAccountId = await LocalAccountRepository(_database).ensure();
      if (seedDemo) {
        _logger.finer('Seeding demo data');
        await DemoDataSeeder(
          Repository(_database),
          localAccountId: _localAccountId,
        ).seed();
      }
    } catch (_) {
      await _database.close();
      rethrow;
    }
  }

  Future<void> initialize() async {
    _repository = Repository(_database);

    final handler = buildApiHandler(
      name: embeddedServerName,
      displayName: embeddedServerDisplayName,
      version: embeddedServerVersion,
      schemaRevision: _database.schemaVersion,
      repository: _repository,
      authMiddleware: fixedPrincipal(Principal(accountId: _localAccountId)),
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
/// The embedded instance never asks for a token (ticket 017). Every request
/// instead acts as the installation's Local account, through the same
/// `Principal` seam the hosted server fills from a verified token.
///
/// With [seedDemo], an empty database gets the example data of
/// `DemoDataSeeder` (development only; the app passes it for the demo
/// database).
Future<EmbeddedServer> startEmbeddedServer(
  String databasePath, {
  bool seedDemo = false,
}) async {
  final server = EmbeddedServer._(databasePath, seedDemo: seedDemo);
  await server.initializeDatabase();
  await server.initialize();
  return server;
}
