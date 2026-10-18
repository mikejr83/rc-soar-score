import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' show Pipeline;
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

import 'embedded_guard.dart';

final _logger = Logger('EmbeddedServer');

const String embeddedServerName = 'soar_score_contest';
const String embeddedServerDisplayName = 'Soar Score Contest (Offline)';
const String embeddedServerVersion = '0.1.0';

/// An in-process instance of the Soar Score API served by the Windows build
/// of `soar_score_contest` (ticket 018).
///
/// Bound to the IPv4 loopback address on an OS-assigned free port so
/// concurrent instances can never conflict; [baseUrl] is the loopback address
/// the app's own `ApiClient` (from `soar_score_api`) is pointed at. Every
/// request but `GET /health` must carry [secret] as a bearer token (see
/// `embeddedGuard`).
class EmbeddedServer {
  EmbeddedServer._(this._databasePath, {required this.seedDemo});

  final String _databasePath;

  /// Whether to fill an empty database with the demo data.
  final bool seedDemo;
  late HttpServer _server;

  /// The per-launch bearer secret, held in memory only. The app's own client
  /// gets it through its `tokenProvider`.
  final String secret = generateEmbeddedSecret();
  late SoarScoreDatabase _database;
  late core.Repository _repository;
  late core.Id _localAccountId;
  late core.Id _actingAccountId;

  /// The OS-assigned port the local socket is bound to.
  int get port => _server.port;

  /// The loopback base URL the app's `ApiClient` should target.
  Uri get baseUrl => Uri.parse('http://127.0.0.1:$port');

  core.Repository get repository => _repository;

  /// The local database, for the sync engine's store and applier.
  SoarScoreDatabase get database => _database;

  /// The installation's Local account, which owns the contests created here.
  core.Id get localAccountId => _localAccountId;

  /// The account every request acts as: the owner of what it creates and the
  /// actor of its mutations. The Local account until [actAs] says otherwise.
  core.Id get actingAccountId => _actingAccountId;

  /// Acts as the signed-in [accountId] from now on, so new contests and
  /// roles belong to it from the start and sync at once.
  void actAs(core.Id accountId) => _actingAccountId = accountId;

  /// Acts as the installation's Local account again (signed out).
  void actAsLocal() => _actingAccountId = _localAccountId;

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
      _actingAccountId = _localAccountId;
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
      authMiddleware: (inner) =>
          (request) => inner(
            request.change(
              context: {
                principalContextKey: Principal(accountId: _actingAccountId),
              },
            ),
          ),
      gliderScoreImport: GliderScoreImportProcessRunner(),
    );
    final guarded = const Pipeline()
        .addMiddleware(embeddedGuard(secret: secret, port: () => port))
        .addHandler(handler);
    _server = await shelf_io.serve(guarded, InternetAddress.loopbackIPv4, 0);
  }

  /// Shuts down the HTTP server and closes the local database, releasing the
  /// port and the SQLite file handle.
  Future<void> close() async {
    await _server.close(force: true);
    await _database.close();
  }
}

/// Opens the local SQLite database at [databasePath] (parent directories are
/// created if needed) and starts the embedded API on `127.0.0.1` with an
/// OS-assigned free port (port `0` is passed to `shelf_io.serve`).
///
/// The embedded instance has no sign-in (ticket 017) but requires the
/// per-launch [EmbeddedServer.secret] on every request but `GET /health`,
/// and refuses foreign `Host` and any `Origin` (#425, `docs/embedded-api-security.md`).
/// Every request that passes acts as an account chosen by the app, through the
/// same `Principal` seam the hosted server fills from a verified token: the installation's
/// Local account, or the signed-in account once the Local account is claimed
/// (see [EmbeddedServer.actAs]).
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
