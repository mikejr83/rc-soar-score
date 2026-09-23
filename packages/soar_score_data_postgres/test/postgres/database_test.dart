import 'package:drift/drift.dart';
import 'package:postgres/postgres.dart' show ServerException;
import 'package:soar_score_data_postgres/soar_score_data_postgres.dart';
import 'package:test/test.dart';

/// Integration tests against a real PostgreSQL instance (ticket 016).
///
/// Runs only when a reachable instance is configured through the environment:
/// `POSTGRES_PASSWORD` is required; `POSTGRES_HOST` (default `localhost`),
/// `POSTGRES_PORT` (default `5432`), `POSTGRES_DB` (default `postgres`),
/// `POSTGRES_USER` (default `postgres`), and `POSTGRES_SSLMODE`
/// (`disable`/`require`/`verifyFull`, default `disable`) are optional. When
/// no instance is configured or reachable, the tests are skipped and
/// `melos test` stays green — including on CI machines without a Postgres
/// service. To make these tests run for real, provision an instance first and
/// export the variables, e.g.:
///
/// ```sh
/// docker run --rm -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres
/// export POSTGRES_PASSWORD=postgres POSTGRES_DB=postgres POSTGRES_USER=postgres
/// ```
///
/// Each test uses its own throwaway database (created in `setUp`, dropped in
/// `tearDown`), so runs never share state.
void main() {
  final config = PostgresConfig.fromEnvironment();
  const db = 'soar_score_postgres_db';

  group(
    'ContestDatabase (PostgreSQL integration)',
    () {
      late ContestDatabase database;

      setUp(() async {
        final admin = ContestDatabase.open(config!.named('postgres'));
        try {
          await admin.customStatement('CREATE DATABASE "$db"');
        } on ServerException catch (e) {
          // 42P04 = database already exists; anything else rethrow.
          if (e.code != '42P04') rethrow;
        }
        await admin.close();

        database = ContestDatabase.open(config.named(db));
        // First use opens the connection and runs the initial migration.
        await database.select(database.contests).get();
      });

      tearDown(() async {
        try {
          await database.close();
        } catch (_) {
          /* best effort; the admin drop below is authoritative */
        }

        final admin = ContestDatabase.open(config!.named('postgres'));
        await admin.customStatement('DROP DATABASE IF EXISTS "$db"');
        await admin.close();
      });

      test(
        'performs a trivial query against a real Postgres instance',
        () async {
          final rows = await database
              .customSelect('SELECT 1 AS one, version() AS version')
              .get();
          expect(rows, hasLength(1));
          expect(rows.first.read<int>('one'), 1);
          expect(rows.first.read<String>('version'), isNotEmpty);
        },
      );

      test('runs the initial schema migration on open', () async {
        final versionRow = await database
            .customSelect('SELECT version FROM __schema')
            .get()
            .then((rows) => rows.single);
        expect(versionRow.read<int>('version'), 1);

        final tables = await database
            .customSelect(
              "SELECT tablename FROM pg_tables WHERE schemaname = 'public' "
              'ORDER BY tablename',
            )
            .get();
        final names = tables.map((t) => t.read<String>('tablename')).toList();
        expect(names, containsAll(['contests', '__schema']));
      });

      test('supports raw inserts into the migrated schema', () async {
        await database.customInsert(
          'INSERT INTO contests (id, name, started_at) VALUES (?, ?, ?)',
          variables: const [
            Variable('0195a123-4567-7890-abcd-ef0123456789'),
            Variable('Raw query contest'),
            Variable('2026-01-02T03:04:05.000Z'),
          ],
        );
        final rows = await database
            .customSelect('SELECT COUNT(*) AS n FROM contests')
            .get();
        expect(rows.first.read<int>('n'), 1);
      });
    },
    skip: config == null
        ? 'no PostgreSQL instance configured (set POSTGRES_PASSWORD; see the doc comment of this test)'
        : null,
  );
}
