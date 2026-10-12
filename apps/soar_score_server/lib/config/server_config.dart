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
/// | `POSTGRES_PASSWORD` | database password | required |
/// | `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_SSLMODE` | database connection | see [PostgresConfig] |
class ServerConfig {
  ServerConfig({
    required this.port,
    required this.logLevel,
    required this.logFormat,
    required this.postgres,
  });

  /// The variables [ServerConfig.parse] reads.
  static const environmentKeys = [
    'PORT',
    'LOG_LEVEL',
    'LOG_FORMAT',
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

    if (value('POSTGRES_PASSWORD') == null) {
      problems.add('POSTGRES_PASSWORD is required.');
    }
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

    if (problems.isNotEmpty) {
      throw ConfigException(problems);
    }
    return ServerConfig(
      port: port,
      logLevel: logLevel,
      logFormat: logFormat,
      postgres: PostgresConfig.fromEnvironment(environment)!,
    );
  }

  /// A one-line summary that is safe to log (no password).
  String describe() =>
      'port=$port logLevel=${logLevel.name} logFormat=${logFormat.name} '
      'database=${postgres.user}@${postgres.host}:${postgres.port}/'
      '${postgres.database} ssl=${postgres.sslMode.name}';
}
