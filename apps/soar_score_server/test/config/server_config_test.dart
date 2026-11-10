import 'package:logging/logging.dart';
import 'package:postgres/postgres.dart';
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

    test('INVITATION_SECRET is optional and needs 32 characters', () {
      expect(ServerConfig.parse(minimal).invitationSecret, isNull);
      final ok = ServerConfig.parse({
        ...minimal,
        'INVITATION_SECRET': 'k' * 32,
      });
      expect(ok.invitationSecret, 'k' * 32);
      expect(
        () => ServerConfig.parse({...minimal, 'INVITATION_SECRET': 'short'}),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.toString(),
            'message',
            allOf(contains('INVITATION_SECRET'), isNot(contains('short'))),
          ),
        ),
      );
    });

    test('SELF_SCORING_BASE_URL is an http(s) origin and optional', () {
      expect(ServerConfig.parse(minimal).selfScoringBaseUrl, isNull);
      expect(
        ServerConfig.parse({
          ...minimal,
          'SELF_SCORING_BASE_URL': 'https://score.example',
        }).selfScoringBaseUrl,
        'https://score.example',
      );
      for (final bad in ['score.example', 'ftp://x', 'https://x/path?q=1']) {
        expect(
          () => ServerConfig.parse({...minimal, 'SELF_SCORING_BASE_URL': bad}),
          throwsA(isA<ConfigException>()),
          reason: bad,
        );
      }
    });

    test('LOG_DB_STATEMENT_DURATIONS is a boolean and off by default', () {
      expect(ServerConfig.parse(minimal).logStatementDurations, isFalse);
      expect(
        ServerConfig.parse({...minimal, 'LOG_DB_STATEMENT_DURATIONS': 'true'})
            .logStatementDurations,
        isTrue,
      );
      expect(
        ServerConfig.parse({...minimal, 'LOG_DB_STATEMENT_DURATIONS': 'false'})
            .logStatementDurations,
        isFalse,
      );
      expect(
        () => ServerConfig.parse({
          ...minimal,
          'LOG_DB_STATEMENT_DURATIONS': 'yes',
        }),
        throwsA(isA<ConfigException>()),
      );
    });

    test('accepts a connection URL in place of the discrete variables', () {
      final config = ServerConfig.parse({
        'DATABASE_URL': 'postgresql://urluser:urlpw@ep-db.us-east-2.aws.neon.tech/neondb?sslmode=verify-full',
        'AUTH0_DOMAIN': 'tenant.us.auth0.com',
        'API_AUDIENCE': 'https://soar-score.com/server',
      });

      expect(config.postgres.host, 'ep-db.us-east-2.aws.neon.tech');
      expect(config.postgres.port, 5432);
      expect(config.postgres.database, 'neondb');
      expect(config.postgres.user, 'urluser');
      expect(config.postgres.password, 'urlpw');
      expect(config.postgres.sslMode, SslMode.verifyFull);
    });

    test('lets the URL win when both URL and discrete variables are set', () {
      final config = ServerConfig.parse({
        ...minimal,
        'DATABASE_URL':
            'postgresql://urluser:urlpw@db:5433/soar?sslmode=disable',
      });

      expect(config.postgres.host, 'db');
      expect(config.postgres.port, 5433);
      expect(config.postgres.database, 'soar');
      expect(config.postgres.user, 'urluser');
      expect(config.postgres.password, 'urlpw');
      expect(config.postgres.sslMode, SslMode.disable);
    });

    test('requires a password when no URL is set', () {
      expect(
        () => ServerConfig.parse({
          'AUTH0_DOMAIN': 'tenant.us.auth0.com',
          'API_AUDIENCE': 'https://soar-score.com/server',
        }),
        throwsA(
          isA<ConfigException>().having(
            (e) => e.problems.join(),
            'problems',
            contains('DATABASE_URL or POSTGRES_PASSWORD is required'),
          ),
        ),
      );
    });

    test('reports an invalid URL and does not fall back to the password', () {
      try {
        ServerConfig.parse({
          'DATABASE_URL': 'mysql://u:p@h/db',
          'AUTH0_DOMAIN': 'tenant.us.auth0.com',
          'API_AUDIENCE': 'https://soar-score.com/server',
        });
        fail('expected a ConfigException');
      } on ConfigException catch (e) {
        expect(e.problems, hasLength(1));
        expect(e.problems.first, contains('DATABASE_URL'));
      }
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
        });
        fail('expected a ConfigException');
      } on ConfigException catch (e) {
        expect(e.problems, hasLength(6));
        expect(
          e.problems.join('\n'),
          allOf([
            contains('PORT'),
            contains('LOG_LEVEL'),
            contains('LOG_FORMAT'),
            contains('AUTH0_DOMAIN'),
            contains('API_AUDIENCE'),
            contains('DATABASE_URL or POSTGRES_PASSWORD is required'),
          ]),
        );
      }
    });

    test('stays silent about the discrete variables when a URL is set', () {
      final config = ServerConfig.parse({
        'DATABASE_URL': 'postgresql://u:p@h/db',
        'AUTH0_DOMAIN': 'tenant.us.auth0.com',
        'API_AUDIENCE': 'https://soar-score.com/server',
        'POSTGRES_PORT': '70000',
        'POSTGRES_SSLMODE': 'maybe',
      });
      expect(config.postgres.host, 'h');
      expect(config.postgres.port, 5432);
      expect(config.postgres.sslMode, SslMode.require);
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

      final urlConfig = ServerConfig.parse({
        'DATABASE_URL': 'postgresql://u:$secret@h/db',
        'AUTH0_DOMAIN': 'tenant.us.auth0.com',
        'API_AUDIENCE': 'https://soar-score.com/server',
      });
      expect(urlConfig.describe(), isNot(contains(secret)));
    });
  });
}
