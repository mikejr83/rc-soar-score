import 'package:postgres/postgres.dart';
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

void main() {
  group('PostgresConfig.fromUrl', () {
    test('parses a Neon-style connection URL', () {
      final config = PostgresConfig.fromUrl(
        'postgresql://neondb_owner:NeonP%40ss@ep-quiet-dawn-ad5970d5-pooler.'
        'us-east-2.aws.neon.tech/neondb?sslmode=verify-full',
      );

      expect(config.host, 'ep-quiet-dawn-ad5970d5-pooler.us-east-2.aws.neon.tech');
      expect(config.port, 5432);
      expect(config.database, 'neondb');
      expect(config.user, 'neondb_owner');
      expect(config.password, 'NeonP@ss');
      expect(config.sslMode, SslMode.verifyFull);
    });

    test('accepts the postgres scheme and a host port', () {
      final config = PostgresConfig.fromUrl('postgres://app:password@db:5433/soar');

      expect(config.host, 'db');
      expect(config.port, 5433);
      expect(config.database, 'soar');
      expect(config.user, 'app');
      expect(config.password, 'password');
      expect(config.sslMode, SslMode.require);
    });

    test('requires TLS unless the URL opts out', () {
      expect(PostgresConfig.fromUrl('postgresql://u:p@h/db').sslMode,
          SslMode.require);
      expect(PostgresConfig.fromUrl('postgresql://u:p@h/db?sslmode=disable')
          .sslMode, SslMode.disable);
    });

    test('maps the libpq sslmode vocabulary', () {
      final mapped = {
        'disable': SslMode.disable,
        'allow': SslMode.require,
        'prefer': SslMode.require,
        'require': SslMode.require,
        'verify-ca': SslMode.verifyFull,
        'verify-full': SslMode.verifyFull,
      };
      for (final entry in mapped.entries) {
        expect(
          PostgresConfig.fromUrl(
            'postgresql://u:p@h/db?sslmode=${entry.key}',
          ).sslMode,
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('takes credentials from the authority by default', () {
      final config = PostgresConfig.fromUrl('postgresql://u:p@h/db');
      expect(config.user, 'u');
      expect(config.password, 'p');
    });

    test('lets query parameters override the authority and path', () {
      final config = PostgresConfig.fromUrl(
        'postgresql://ignored:pw@h1:1111/ignored?host=h2&port=2222'
        '&user=override&password=secret&database=soar',
      );

      expect(config.host, 'h2');
      expect(config.port, 2222);
      expect(config.database, 'soar');
      expect(config.user, 'override');
      expect(config.password, 'secret');
    });

    test('accepts a user without a password only via a query parameter', () {
      final config =
          PostgresConfig.fromUrl('postgresql://u@h/db?password=from-query');
      expect(config.user, 'u');
      expect(config.password, 'from-query');
    });

    test('rejects a URL without a password', () {
      expect(
        () => PostgresConfig.fromUrl('postgresql://u@h/db'),
        throwsA(
          isA<ArgumentError>().having((e) => e.message.toString(), 'message',
              isNot(contains('secret')),
            ),
        ),
      );
    });

    test('rejects a URL without a database', () {
      expect(() => PostgresConfig.fromUrl('postgresql://u:p@h'),
          throwsA(isA<ArgumentError>()));
    });

    test('rejects an unknown scheme', () {
      expect(() => PostgresConfig.fromUrl('mysql://u:p@h/db'),
          throwsA(isA<ArgumentError>()));
    });

    test('rejects an invalid port', () {
      for (final port in ['0', '70000', 'abc']) {
        expect(
          () => PostgresConfig.fromUrl('postgresql://u:p@h/db?port=$port'),
          throwsA(isA<ArgumentError>()),
          reason: port,
        );
      }
    });

    test('rejects an invalid sslmode', () {
      expect(
        () => PostgresConfig.fromUrl('postgresql://u:p@h/db?sslmode=maybe'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects a repeated query parameter', () {
      expect(
        () => PostgresConfig.fromUrl('postgresql://u:p@h/db?sslmode=disable&sslmode=require'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects an unsupported libpq parameter instead of ignoring it', () {
      for (final param in ['connect_timeout', 'sslcert', 'client_encoding']) {
        expect(
          () => PostgresConfig.fromUrl('postgresql://u:p@h/db?$param=1'),
          throwsA(isA<ArgumentError>()),
          reason: param,
        );
      }
    });

    test('rejects an unrecognized query parameter', () {
      expect(() => PostgresConfig.fromUrl('postgresql://u:p@h/db?keepalive=1'),
          throwsA(isA<ArgumentError>()));
    });

    test('rejects a multi-host authority', () {
      expect(() => PostgresConfig.fromUrl('postgresql://u:p@h1,h2/db'),
          throwsA(isA<ArgumentError>()));
    });
  });

  group('PostgresConfig.fromEnvironment', () {
    test('prefers the URL over the discrete variables', () {
      final config = PostgresConfig.fromEnvironment({
        'DATABASE_URL': 'postgresql://urluser:urlpw@urldb:5555/urldb',
        'POSTGRES_PASSWORD': 'other',
        'POSTGRES_HOST': 'discretehost',
        'POSTGRES_DB': 'otherdb',
      });

      expect(config, isNotNull);
      expect(config!.host, 'urldb');
      expect(config.port, 5555);
      expect(config.database, 'urldb');
      expect(config.user, 'urluser');
      expect(config.password, 'urlpw');
    });

    test('falls back to the discrete variables when there is no URL', () {
      final config = PostgresConfig.fromEnvironment({
        'POSTGRES_PASSWORD': 'secret',
        'POSTGRES_HOST': 'db1',
      });

      expect(config, isNotNull);
      expect(config!.host, 'db1');
      expect(config.password, 'secret');
    });

    test('reports neither as configured', () {
      expect(PostgresConfig.fromEnvironment({}), isNull);
    });

    test('an invalid URL is rejected, not silently ignored', () {
      expect(
        () => PostgresConfig.fromEnvironment({
          'DATABASE_URL': 'not-a-url',
          'POSTGRES_PASSWORD': 'secret',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
