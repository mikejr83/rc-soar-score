import 'dart:io';

import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart';

/// Connection details for a PostgreSQL instance.
///
/// Loaded from environment variables by [fromEnvironment] or a connection
/// URL by [fromUrl], so credentials never enter source control.
class PostgresConfig {
  PostgresConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.user,
    required this.password,
    this.sslMode = SslMode.disable,
  });

  /// Reads connection details from [environment], or from the process
  /// environment when none is given. [urlKey] names the connection-URL
  /// variable.
  ///
  /// Returns null when neither [urlKey] nor the discrete `POSTGRES_*`
  /// variables are set, so callers (tests, tooling) can tell "not
  /// configured" from a real configuration. When [urlKey] is present and
  /// non-empty it takes precedence over the discrete variables, so a host
  /// that injects both is always described by the URL.
  static PostgresConfig? fromEnvironment([
    Map<String, String>? environment,
    String urlKey = 'DATABASE_URL',
  ]) {
    final env = environment ?? Platform.environment;
    final url = env[urlKey];
    if (url != null && url.isNotEmpty) {
      return fromUrl(url);
    }
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

  /// Parses [url] into a connection config.
  ///
  /// Accepts the libpq-style connection URL, `postgresql://` or `postgres://`
  /// (single host only; a comma-separated multi-host authority is rejected):
  ///
  /// ```
  /// postgresql://[username][:password]@host[:port][/database][?params]
  /// ```
  ///
  /// Honors the libpq connection-URI parameters this configuration needs:
  /// `host`, `port`, `user`/`username`, `password`, `database` and
  /// `sslmode`; a query parameter overrides the same value in the URL's
  /// authority or path. Every other recognized libpq parameter
  /// (`sslcert`, `sslkey`, `sslrootcert`, `connect_timeout`,
  /// `application_name`, `client_encoding`, `replication`) and any
  /// unrecognized parameter are rejected with a named error, so a URL is
  /// never silently altered.
  ///
  /// `sslmode` follows libpq's vocabulary and maps onto this package's
  /// [SslMode] (`allow`/`prefer` become `require`, `verify-ca`/`verify-full`
  /// become `verifyFull`). When the URL carries no `sslmode`, [sslMode] is
  /// used: TLS is required (`SslMode.require`) because production hosts such
  /// as Neon reject unencrypted connections, while a local development URL
  /// can opt out with `?sslmode=disable`.
  ///
  /// Throws [ArgumentError] for any malformed URL. Error messages never
  /// contain the password.
  static PostgresConfig fromUrl(String url, {SslMode sslMode = SslMode.require}) {
    final Uri uri;
    try {
      uri = Uri.parse(url);
    } on FormatException catch (e) {
      throw ArgumentError.value(url, 'url', 'is not a valid URI ($e)');
    }
    if (uri.scheme != 'postgresql' && uri.scheme != 'postgres') {
      throw ArgumentError.value(
        uri.scheme,
        'url',
        'must use the postgres or postgresql scheme',
      );
    }

    final params = <String, String>{};
    for (final key in uri.queryParametersAll.keys) {
      final values = uri.queryParametersAll[key] ?? const <String>[];
      if (values.length > 1) {
        throw ArgumentError.value(
          key,
          'url',
          'repeats the query parameter "$key"',
        );
      }
      if (values.isNotEmpty) params[key] = values.single;
    }

    const honored = {
      'host',
      'port',
      'user',
      'username',
      'password',
      'database',
      'sslmode',
    };
    const libpqOnly = {
      'sslcert',
      'sslkey',
      'sslrootcert',
      'connect_timeout',
      'application_name',
      'client_encoding',
      'replication',
    };
    for (final key in params.keys) {
      if (!honored.contains(key)) {
        throw ArgumentError.value(
          key,
          'url',
          libpqOnly.contains(key)
              ? 'uses the parameter "$key", which is not supported'
              : 'uses the unrecognized query parameter "$key"',
        );
      }
    }

    if (uri.host.contains(',')) {
      throw ArgumentError.value(
        uri.host,
        'url',
        'names multiple hosts (unsupported; name exactly one)',
      );
    }

    final host = params['host'] ?? (uri.host.isEmpty ? 'localhost' : uri.host);
    var port = uri.port;
    final rawPort = params['port'];
    if (rawPort != null) {
      final parsedPort = int.tryParse(rawPort);
      if (parsedPort == null || parsedPort < 1 || parsedPort > 65535) {
        throw ArgumentError.value(rawPort, 'url', 'has an invalid "port"');
      }
      port = parsedPort;
    }
    if (port == 0) port = 5432;

    final database = params['database'] ?? uri.pathSegments.firstOrNull;
    if (database == null || database.isEmpty) {
      throw ArgumentError.value(
        url,
        'url',
        'must include the database in its path, e.g. postgresql://user@host/db',
      );
    }

    String? authorityUser;
    String? authorityPassword;
    if (uri.userInfo.isNotEmpty) {
      final colonIndex = uri.userInfo.indexOf(':');
      if (colonIndex == -1) {
        authorityUser = Uri.decodeComponent(uri.userInfo);
      } else {
        authorityUser = Uri.decodeComponent(uri.userInfo.substring(0, colonIndex));
        authorityPassword =
            Uri.decodeComponent(uri.userInfo.substring(colonIndex + 1));
      }
    }

    final user =
        params['user'] ?? params['username'] ?? authorityUser ?? 'postgres';
    final password = params['password'] ?? authorityPassword;
    if (password == null || password.isEmpty) {
      throw ArgumentError.value(
        url,
        'url',
        'must include the password, e.g. postgresql://user:password@host/db',
      );
    }

    final rawSslmode = params['sslmode'];
    return PostgresConfig(
      host: host,
      port: port,
      database: database,
      user: user,
      password: password,
      sslMode: rawSslmode == null ? sslMode : _sslModeFromUrl(rawSslmode),
    );
  }

  static SslMode _sslModeFromUrl(String value) {
    switch (value) {
      case 'disable':
        return SslMode.disable;
      case 'allow':
      case 'prefer':
      case 'require':
        return SslMode.require;
      case 'verify-ca':
      case 'verify-full':
        return SslMode.verifyFull;
      default:
        throw ArgumentError.value(
          value,
          'sslmode',
          'must be one of: disable, allow, prefer, require, verify-ca, '
          'verify-full',
        );
    }
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
