import 'package:logging/logging.dart';
import 'package:soar_score_server/config/config_exception.dart';
import 'package:soar_score_core/config/log_format.dart';
import 'package:soar_score_server/config/server_config.dart';
import 'package:test/test.dart';

void main() {
  const secret = 's3cret-pw';
  const minimal = {
    'POSTGRES_PASSWORD': secret,
    'AUTH0_DOMAIN': 'tenant.us.auth0.com',
    'API_AUDIENCE': 'https://soar-score.com/server',
  };

  group('ServerConfig.parse', () {
    test('uses defaults when only the password is set', () {
      final config = ServerConfig.parse(minimal);

      expect(config.port, 8080);
      expect(config.logLevel, Level.INFO);
      expect(config.logFormat, LogFormat.json);
      expect(config.postgres.host, 'localhost');
      expect(config.postgres.password, secret);
      expect(config.auth0Domain, 'tenant.us.auth0.com');
      expect(config.apiAudience, 'https://soar-score.com/server');
    });

    test('allows no CORS origins by default', () {
      expect(ServerConfig.parse(minimal).corsAllowedOrigins, isEmpty);
    });

    test('parses a comma-separated list of CORS origins', () {
      final config = ServerConfig.parse({
        ...minimal,
        'CORS_ALLOWED_ORIGINS':
            ' http://127.0.0.1:8091, http://localhost:8091 ,',
      });

      expect(config.corsAllowedOrigins, {
        'http://127.0.0.1:8091',
        'http://localhost:8091',
      });
    });

    test('rejects CORS origins with a path, a trailing slash or no scheme', () {
      for (final origin in [
        'http://localhost:8091/app',
        'http://localhost:8091/',
        'localhost:8091',
        '*',
      ]) {
        expect(
          () =>
              ServerConfig.parse({...minimal, 'CORS_ALLOWED_ORIGINS': origin}),
          throwsA(
            isA<ConfigException>().having(
              (e) => e.problems.join(),
              'problems',
              contains('CORS_ALLOWED_ORIGINS'),
            ),
          ),
          reason: origin,
        );
      }
    });

    test('rejects an Auth0 domain with a scheme or path', () {
      for (final domain in ['https://tenant.us.auth0.com', 'tenant/path']) {
        expect(
          () => ServerConfig.parse({...minimal, 'AUTH0_DOMAIN': domain}),
          throwsA(
            isA<ConfigException>().having(
              (e) => e.problems.join(),
              'problems',
              contains('AUTH0_DOMAIN'),
            ),
          ),
        );
      }
    });

    test('reads every setting', () {
      final config = ServerConfig.parse({
        ...minimal,
        'PORT': '9000',
        'LOG_LEVEL': 'fine',
        'LOG_FORMAT': 'TEXT',
        'POSTGRES_HOST': 'db',
        'POSTGRES_PORT': '5433',
        'POSTGRES_DB': 'soar',
        'POSTGRES_USER': 'app',
        'POSTGRES_SSLMODE': 'require',
      });

      expect(config.port, 9000);
      expect(config.logLevel, Level.FINE);
      expect(config.logFormat, LogFormat.text);
      expect(config.postgres.host, 'db');
      expect(config.postgres.port, 5433);
      expect(config.postgres.database, 'soar');
      expect(config.postgres.user, 'app');
    });

    test('treats empty values as unset', () {
      final config = ServerConfig.parse({...minimal, 'PORT': ''});
      expect(config.port, 8080);
    });

    test('reports every problem at once', () {
      try {
        ServerConfig.parse({
          'PORT': '70000',
          'LOG_LEVEL': 'loud',
          'LOG_FORMAT': 'xml',
          'POSTGRES_PORT': 'abc',
          'POSTGRES_SSLMODE': 'maybe',
        });
        fail('expected a ConfigException');
      } on ConfigException catch (e) {
        expect(e.problems, hasLength(8));
        expect(
          e.problems.join('\n'),
          allOf([
            contains('PORT'),
            contains('LOG_LEVEL'),
            contains('LOG_FORMAT'),
            contains('AUTH0_DOMAIN'),
            contains('API_AUDIENCE'),
            contains('POSTGRES_PASSWORD'),
            contains('POSTGRES_PORT'),
            contains('POSTGRES_SSLMODE'),
          ]),
        );
      }
    });

    test('never prints the password', () {
      final config = ServerConfig.parse(minimal);
      expect(config.describe(), isNot(contains(secret)));

      try {
        ServerConfig.parse({...minimal, 'PORT': 'x'});
        fail('expected a ConfigException');
      } on ConfigException catch (e) {
        expect('$e', isNot(contains(secret)));
      }
    });
  });
}
