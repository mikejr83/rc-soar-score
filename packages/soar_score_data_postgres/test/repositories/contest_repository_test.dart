import 'package:postgres/postgres.dart' show ServerException;
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_data_postgres/soar_score_data_postgres.dart';
import 'package:test/test.dart';

/// Integration tests for [ContestPostgresRepository] against a real PostgreSQL
/// instance.
///
/// Runs only when `POSTGRES_PASSWORD` (and optionally `POSTGRES_HOST`,
/// `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_SSLMODE`) is
/// configured; otherwise the tests are skipped and `melos test` stays green.
/// To provision an instance locally:
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
  const db = 'soar_score_postgres_repo_db';

  group(
    'ContestPostgresRepository (integration)',
    () {
      late ContestDatabase database;
      late ContestPostgresRepository repository;

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
        repository = ContestPostgresRepository(database);
        // First use opens the connection and runs the initial migration.
        await repository.getAll();
      });

      tearDown(() async {
        try {
          await repository.close();
        } catch (_) {
          /* best effort; the admin drop below is authoritative */
        }

        final admin = ContestDatabase.open(config!.named('postgres'));
        await admin.customStatement('DROP DATABASE IF EXISTS "$db"');
        await admin.close();
      });

      Contest makeContest({String? name, DateTime? startedAt}) => Contest(
        id: Id.create(),
        name: name ?? 'Spring Meet',
        startedAt: startedAt ?? DateTime.utc(2026, 4, 15, 10, 30),
      );

      test('save then findById round-trips the domain type', () async {
        final saved = await repository.save(makeContest());

        final loaded = await repository.findById(saved.id);
        expect(loaded, isNotNull);
        expect(loaded, saved);
      });

      test('findById returns null for unknown ids', () async {
        expect(await repository.findById(Id.create()), isNull);
      });

      test('getAll returns every stored contest', () async {
        final first = await repository.save(makeContest(name: 'First'));
        final second = await repository.save(makeContest(name: 'Second'));

        expect(await repository.getAll(), unorderedEquals([first, second]));
      });

      test('save updates the existing row for the same id', () async {
        final original = makeContest();
        await repository.save(original);

        final updated = Contest(
          id: original.id,
          name: 'Renamed',
          startedAt: original.startedAt,
        );
        await repository.save(updated);

        expect(await repository.getAll(), [updated]);
        expect((await repository.findById(updated.id))?.name, 'Renamed');
      });

      test('startedAt is stored and read back in UTC', () async {
        final localStart = DateTime(2026, 4, 15, 10, 30);
        final saved = await repository.save(makeContest(startedAt: localStart));

        final loaded = await repository.findById(saved.id);
        expect(loaded?.startedAt, saved.startedAt.toUtc());
        expect(loaded?.startedAt.isUtc, isTrue);
      });

      test('delete removes the row and reports accordingly', () async {
        final saved = await repository.save(makeContest());

        expect(await repository.delete(saved.id), isTrue);
        expect(await repository.delete(saved.id), isFalse);
        expect(await repository.findById(saved.id), isNull);
      });
    },
    skip: config == null
        ? 'no PostgreSQL instance configured (set POSTGRES_PASSWORD; see the doc comment of this test)'
        : null,
  );
}
