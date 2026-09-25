import 'dart:io';

import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart';

/// Connection details for a PostgreSQL instance.
///
/// Loaded from environment variables by [fromEnvironment] so credentials
/// never enter source control.
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
  /// Returns null when POSTGRES_PASSWORD is not set or empty, so callers
  /// (tests, tooling) can tell "not configured" from a real configuration.
  static PostgresConfig? fromEnvironment() {
    final env = Platform.environment;
    final password = env['POSTGRES_PASSWORD'];
    if (password == null || password.isEmpty) {
      return null;
    }
    return PostgresConfig(
      host: env['POSTGRES_HOST'] ?? 'localhost',
      port: int.tryParse(env['POSTGRES_PORT'] ?? '') ?? 5432,
      database: env['POSTGRES_DB'] ?? 'rc_soar_score',
      user: env['POSTGRES_USER'] ?? 'postgres',
      password: password,
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

  final String host;
  final int port;
  final String database;
  final String user;
  final String password;
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

  /// Creates a PgDatabase from this config.
  // PgDatabase toPgDatabase() => PgDatabase(
  //   endpoint: Endpoint(host: host, port: port, database: database),
  //   settings: ConnectionSettings(),
  //   user: user,
  //   password: password,
  //   sslSettings: sslMode == SslMode.require ? null : null,
  // );
  PgDatabase toPgDatabase({bool logStatements = false}) => PgDatabase(
    endpoint: this.toEndpoint(),
    settings: this.toSettings(),
    logStatements: logStatements,
  );

  /// The SSL mode for connection security.
  SslMode get ssl => sslMode;
}
