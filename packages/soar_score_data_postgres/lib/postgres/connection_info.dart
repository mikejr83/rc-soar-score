import 'package:dotenv/dotenv.dart' show DotEnv;
import 'package:postgres/postgres.dart'
    show ConnectionSettings, Endpoint, SslMode;

import 'package:logging/logging.dart';

final _logger = Logger('PostgresConfig');

/// Connection details for a PostgreSQL instance.
///
/// Loaded from environment variables by [fromEnvironment] so credentials
/// never enter source control; consistent with how `soar_score_server` reads
/// `PORT` from its process environment (ticket 016).
class PostgresConfig {
  PostgresConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.user,
    required this.password,
    this.sslMode = SslMode.disable,
  });

  /// Reads connection details from the process environment.
  ///
  /// Returns `null` when `POSTGRES_PASSWORD` is not set or empty, so callers
  /// (tests, tooling) can tell "not configured" from a real configuration.
  static PostgresConfig? fromEnvironment() {
    final env = DotEnv(includePlatformEnvironment: true)..load();
    final password = env['POSTGRES_PASSWORD'];
    if (password?.isEmpty ?? true) {
      _logger.warning(
        'POSTGRES_PASSWORD is empty; using it to create PostgresConfig anyway.',
      );
      _logger.info('Returning null config.');
      return null;
    } else {
      _logger.info(
        'Using POSTGRES_PASSWORD from environment to create PostgresConfig.',
      );
    }

    return PostgresConfig(
      host: env['POSTGRES_HOST'] ?? 'localhost',
      port: int.tryParse(env['POSTGRES_PORT'] ?? '') ?? 5432,
      database: env['POSTGRES_DB'] ?? 'postgres',
      user: env['POSTGRES_USER'] ?? 'postgres',
      password: password!,
      sslMode: _sslModeFromEnv(env['POSTGRES_SSLMODE']),
    );
  }

  static SslMode _sslModeFromEnv(String? value) {
    if (value == null || value.isEmpty) {
      return SslMode.disable;
    }
    switch (value) {
      case 'disable':
        return SslMode.disable;
      case 'require':
        return SslMode.require;
      case 'verifyFull':
        return SslMode.verifyFull;
      default:
        throw ArgumentError.value(
          value,
          'POSTGRES_SSLMODE',
          'must be one of: disable, require, verifyFull',
        );
    }
  }

  /// Instance host (`POSTGRES_HOST`, default `localhost`).
  final String host;

  /// Instance port (`POSTGRES_PORT`, default `5432`).
  final int port;

  /// Database name (`POSTGRES_DB`, default `postgres`).
  final String database;

  /// Database user (`POSTGRES_USER`, default `postgres`).
  final String user;

  /// Database password (`POSTGRES_PASSWORD`).
  final String password;

  /// TLS mode (`POSTGRES_SSLMODE`: `disable`/`require`/`verifyFull`;
  /// defaults to `disable` for local/dev instances).
  final SslMode sslMode;

  /// A copy of this config that targets [database].
  PostgresConfig named(String database) => PostgresConfig(
    host: host,
    port: port,
    database: database,
    user: user,
    password: password,
    sslMode: sslMode,
  );

  /// Endpoint for `package:postgres`.
  Endpoint toEndpoint() => Endpoint(
    host: host,
    port: port,
    database: database,
    username: user,
    password: password,
  );

  /// Connection settings for `package:postgres`.
  ConnectionSettings toSettings() => ConnectionSettings(sslMode: sslMode);
}
