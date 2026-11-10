import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:soar_score_data/soar_score_data.dart';

import 'config_exception.dart';

import 'package:soar_score_core/config/log_format.dart';

/// Everything the server reads from its environment.
///
/// | Variable | Meaning | Default |
/// | --- | --- | --- |
/// | `PORT` | listening port | 8080 |
/// | `LOG_LEVEL` | a `package:logging` level name | INFO |
/// | `LOG_FORMAT` | `json` or `text` | json |
/// | `AUTH0_DOMAIN` | Auth0 tenant domain, no scheme (`tenant.us.auth0.com`) | required |
/// | `API_AUDIENCE` | API identifier access tokens must be issued for | required |
/// | `CORS_ALLOWED_ORIGINS` | comma-separated browser origins allowed to call the API, such as `http://127.0.0.1:8091` | none |
/// | `INVITATION_SECRET` | at least 32 characters; signs invitation links and guest sessions. Without it the participant routes answer 409 `invitations_not_available`. Changing it ends every link and session | none |
/// | `SELF_SCORING_BASE_URL` | the self-scoring site invitation links point at, an `https://` URL (or `http://` for local use) with no path | `https://score.rcsoarscore.com` |
/// | `LOG_DB_STATEMENT_DURATIONS` | `true` logs one line per database statement with its duration, SQL text and argument count (never values); `false` or unset is off | off |
/// | `DATABASE_URL` | a `postgresql://` connection URL (authority with password, database in the path, `sslmode` optional) | none — the URL wins over the discrete variables |
/// | `POSTGRES_PASSWORD` | database password, when no `DATABASE_URL` is set | required |
/// | `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_SSLMODE` | database connection, when no `DATABASE_URL` is set | see [PostgresConfig] |
class ServerConfig {
  ServerConfig({
    required this.port,
    required this.logLevel,
    required this.logFormat,
    required this.postgres,
    required this.auth0Domain,
    required this.apiAudience,
    this.corsAllowedOrigins = const {},
    this.invitationSecret,
    this.selfScoringBaseUrl,
    this.logStatementDurations = false,
  });

  /// The variables [ServerConfig.parse] reads.
  static const environmentKeys = [
    'PORT',
    'LOG_LEVEL',
    'LOG_FORMAT',
    'AUTH0_DOMAIN',
    'API_AUDIENCE',
    'CORS_ALLOWED_ORIGINS',
    'INVITATION_SECRET',
    'SELF_SCORING_BASE_URL',
    'LOG_DB_STATEMENT_DURATIONS',
    'DATABASE_URL',
    'POSTGRES_PASSWORD',
    'POSTGRES_HOST',
    'POSTGRES_PORT',
    'POSTGRES_DB',
    'POSTGRES_USER',
    'POSTGRES_SSLMODE',
  ];

  final int port;
  final Level logLevel;
  final LogFormat logFormat;
  final PostgresConfig postgres;

  /// The Auth0 tenant whose tokens the server accepts, without a scheme.
  final String auth0Domain;

  /// The API identifier those tokens must be issued for.
  final String apiAudience;

  /// Browser origins allowed to call the API cross-origin; empty means none.
  final Set<String> corsAllowedOrigins;

  /// The secret that signs invitation links and guest sessions, or null.
  final String? invitationSecret;

  /// The self-scoring site invitation links point at, or null for the
  /// default.
  final String? selfScoringBaseUrl;

  /// Whether each database statement's duration is logged (off by default).
  final bool logStatementDurations;

  /// Parses [environment].
  ///
  /// Throws a [ConfigException] listing every invalid or missing value, so
  /// one failed start shows everything to fix. Error messages never contain
  /// the database password.
  factory ServerConfig.parse(Map<String, String> environment) {
    final problems = <String>[];
    String? value(String key) {
      final v = environment[key];
      return v == null || v.isEmpty ? null : v;
    }

    var port = 8080;
    final rawPort = value('PORT');
    if (rawPort != null) {
      final parsed = int.tryParse(rawPort);
      if (parsed == null || parsed < 1 || parsed > 65535) {
        problems.add('PORT must be a number from 1 to 65535, got "$rawPort".');
      } else {
        port = parsed;
      }
    }

    var logLevel = Level.INFO;
    final rawLevel = value('LOG_LEVEL');
    if (rawLevel != null) {
      final match = Level.LEVELS.where((l) => l.name == rawLevel.toUpperCase());
      if (match.isEmpty) {
        problems.add(
          'LOG_LEVEL must be one of '
          '${Level.LEVELS.map((l) => l.name).join(', ')}, got "$rawLevel".',
        );
      } else {
        logLevel = match.first;
      }
    }

    var logFormat = LogFormat.json;
    final rawFormat = value('LOG_FORMAT');
    if (rawFormat != null) {
      final match = LogFormat.values.where(
        (f) => f.name == rawFormat.toLowerCase(),
      );
      if (match.isEmpty) {
        problems.add('LOG_FORMAT must be json or text, got "$rawFormat".');
      } else {
        logFormat = match.first;
      }
    }

    final domain = value('AUTH0_DOMAIN');
    if (domain == null) {
      problems.add('AUTH0_DOMAIN is required.');
    } else if (domain.contains('://') ||
        domain.contains('/') ||
        domain.contains(' ')) {
      problems.add(
        'AUTH0_DOMAIN must be a host name without a scheme or path, '
        'for example tenant.us.auth0.com, got "$domain".',
      );
    }
    final audience = value('API_AUDIENCE');
    if (audience == null) {
      problems.add('API_AUDIENCE is required.');
    }

    final origins = <String>{};
    for (final raw in (value('CORS_ALLOWED_ORIGINS') ?? '').split(',')) {
      final origin = raw.trim();
      if (origin.isEmpty) continue;
      final uri = Uri.tryParse(origin);
      if (uri == null ||
          !{'http', 'https'}.contains(uri.scheme) ||
          uri.host.isEmpty ||
          (uri.path.isNotEmpty && uri.path != '/') ||
          uri.hasQuery ||
          uri.hasFragment ||
          origin.endsWith('/')) {
        problems.add(
          'CORS_ALLOWED_ORIGINS entries must be origins such as '
          'http://127.0.0.1:8091 (scheme, host, optional port; no path), '
          'got "$origin".',
        );
      } else {
        origins.add(origin);
      }
    }

    final secret = value('INVITATION_SECRET');
    if (secret != null && utf8.encode(secret).length < 32) {
      problems.add('INVITATION_SECRET must be at least 32 characters.');
    }

    final selfScoring = value('SELF_SCORING_BASE_URL');
    if (selfScoring != null) {
      final uri = Uri.tryParse(selfScoring);
      if (uri == null ||
          !(uri.isScheme('https') || uri.isScheme('http')) ||
          uri.host.isEmpty ||
          (uri.path.isNotEmpty && uri.path != '/') ||
          uri.hasQuery ||
          uri.hasFragment) {
        problems.add(
          'SELF_SCORING_BASE_URL must be an http(s) URL with no path, query '
          'or fragment.',
        );
      }
    }

    var logStatementDurations = false;
    final rawDurations = value('LOG_DB_STATEMENT_DURATIONS');
    if (rawDurations != null) {
      switch (rawDurations.toLowerCase()) {
        case 'true':
          logStatementDurations = true;
        case 'false':
          break;
        default:
          problems.add(
            'LOG_DB_STATEMENT_DURATIONS must be true or false, '
            'got "$rawDurations".',
          );
      }
    }

    final rawDbUrl = value('DATABASE_URL');
    var databaseConfigured = rawDbUrl != null;
    if (databaseConfigured) {
      try {
        PostgresConfig.fromUrl(rawDbUrl);
      } on ArgumentError catch (e) {
        problems.add('DATABASE_URL ${e.message ?? e}');
      }
    } else {
      databaseConfigured = value('POSTGRES_PASSWORD') != null;
      if (!databaseConfigured) {
        problems.add('DATABASE_URL or POSTGRES_PASSWORD is required.');
      } else {
        final rawDbPort = value('POSTGRES_PORT');
        if (rawDbPort != null) {
          final parsed = int.tryParse(rawDbPort);
          if (parsed == null || parsed < 1 || parsed > 65535) {
            problems.add(
              'POSTGRES_PORT must be a number from 1 to 65535, got "$rawDbPort".',
            );
          }
        }
        final rawSsl = value('POSTGRES_SSLMODE');
        if (rawSsl != null &&
            !{'disable', 'require', 'verifyFull'}.contains(rawSsl)) {
          problems.add(
            'POSTGRES_SSLMODE must be one of: disable, require, verifyFull, '
            'got "$rawSsl".',
          );
        }
      }
    }

    if (problems.isNotEmpty) {
      throw ConfigException(problems);
    }
    return ServerConfig(
      port: port,
      logLevel: logLevel,
      logFormat: logFormat,
      postgres: PostgresConfig.fromEnvironment(environment)!,
      auth0Domain: domain!,
      apiAudience: audience!,
      corsAllowedOrigins: origins,
      invitationSecret: secret,
      selfScoringBaseUrl: selfScoring,
      logStatementDurations: logStatementDurations,
    );
  }

  /// A one-line summary that is safe to log (no password).
  String describe() =>
      'port=$port auth0=$auth0Domain audience=$apiAudience logLevel=${logLevel.name} logFormat=${logFormat.name} '
      'database=${postgres.user}@${postgres.host}:${postgres.port}/'
      '${postgres.database} ssl=${postgres.sslMode.name}';
}
