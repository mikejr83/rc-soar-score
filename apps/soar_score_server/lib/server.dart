import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:soar_score_data/soar_score_data.dart';

import 'config/server_config.dart';
import 'handler.dart';

final _logger = Logger('Server');

/// A started server: the listener plus the database behind it.
class RunningServer {
  RunningServer._(this._server, this._database);

  final HttpServer _server;
  final SoarScoreDatabase _database;
  Future<void>? _closing;

  /// The port the server listens on.
  int get port => _server.port;

  /// Stops accepting connections, lets running requests finish for up to
  /// [grace], then closes the database. Safe to call more than once.
  Future<void> close({Duration grace = const Duration(seconds: 10)}) =>
      _closing ??= _close(grace);

  Future<void> _close(Duration grace) async {
    _logger.info('Shutting down.');
    final closing = _server.close();
    try {
      await closing.timeout(grace);
    } on TimeoutException {
      _logger.warning('Requests still running after $grace; closing them.');
      await _server.close(force: true);
    }
    await _database.close();
    _logger.info('Shutdown complete.');
  }
}

/// Installs the shipped system data (landing tables, discipline profiles and
/// roles) into [database]; pass it as `onDatabaseOpen` to [startServer].
///
/// A failure stops startup, so the server never serves partial system data.
Future<void> seedSystemData(SoarScoreDatabase database) async {
  final outcome = await SystemDataSeeder(database).seed();
  _logger.info('System data ${outcome.name}.');
}

/// Opens the database, migrates it, and starts serving.
///
/// The database is [database] when given (tests), otherwise PostgreSQL from
/// [config]. It is opened first, so a bad connection or failed migration
/// fails here, before the port opens. [onDatabaseOpen] runs after the
/// migration and before the first request, which is where startup work such
/// as seeding system data belongs.
Future<RunningServer> startServer(
  ServerConfig config, {
  SoarScoreDatabase? database,
  FutureOr<void> Function(SoarScoreDatabase database)? onDatabaseOpen,
  InternetAddress? address,
}) async {
  final db = database ?? createPostgresDatabase(config.postgres);
  try {
    await db.doWhenOpened((_) {});
    _logger.info('Database open and migrated.');
    await onDatabaseOpen?.call(db);
    final server = await shelf_io.serve(
      createServerHandler(db),
      address ?? InternetAddress.anyIPv4,
      config.port,
    );
    _logger.info('Listening on port ${server.port}.');
    return RunningServer._(server, db);
  } catch (_) {
    await db.close();
    rethrow;
  }
}
