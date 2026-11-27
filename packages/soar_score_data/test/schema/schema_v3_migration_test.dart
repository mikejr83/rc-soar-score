import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';

/// Recreates the version 2 schema exactly as 0.1.0-alpha.7 shipped it, from
/// the frozen snapshot: no `accounts.profile_refreshed_at` and no
/// participant-link indexes.
class _Version2Database extends SoarScoreDatabase {
  _Version2Database(super.executor, {required super.profile});

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      final dialect = executor.dialect == SqlDialect.sqlite
          ? 'sqlite'
          : 'postgres';
      final statements = await File('schema_snapshots/v2_$dialect.sql')
          .readAsLines();
      final tables = {for (final t in profileTables) t.actualTableName};
      for (final sql in statements) {
        final table =
            RegExp(r'^CREATE TABLE IF NOT EXISTS "([^"]+)"')
                .firstMatch(sql)
                ?.group(1) ??
            RegExp(
              r'\bON\s+"?([a-z_]+)"?',
              caseSensitive: false,
            ).firstMatch(sql)?.group(1);
        if (table == null) {
          throw StateError('Unrecognized snapshot statement: $sql');
        }
        if (tables.contains(table)) await m.database.customStatement(sql);
      }
    },
    beforeOpen: (_) async {
      if (executor.dialect == SqlDialect.sqlite) {
        await customStatement('PRAGMA foreign_keys = ON');
      }
    },
  );
}

Future<Set<String>> _indexNames(GeneratedDatabase db) async {
  final sql = db.executor.dialect == SqlDialect.sqlite
      ? "SELECT name FROM sqlite_master WHERE type = 'index'"
      : 'SELECT indexname AS name FROM pg_indexes '
            'WHERE schemaname = current_schema()';
  return {
    for (final row in await db.customSelect(sql).get())
      row.read<String>('name'),
  };
}

Future<bool> _hasColumn(
  GeneratedDatabase db,
  String table,
  String column,
) async {
  final sql = db.executor.dialect == SqlDialect.sqlite
      ? "SELECT 1 AS x FROM pragma_table_info('$table') WHERE name = '$column'"
      : "SELECT 1 AS x FROM information_schema.columns WHERE table_schema = current_schema() AND table_name = '$table' AND column_name = '$column'";
  return (await db.customSelect(sql).get()).isNotEmpty;
}

void main() => forEachBackend((backend) {
  for (final databaseProfile in DatabaseProfile.values) {
    test('${databaseProfile.name} upgrades version 2 to 3 keeping its data', () async {
      final temp = await Directory.systemTemp.createTemp('soar-v3-test-');
      pg.Connection? admin;
      String? databaseName;
      SoarScoreDatabase? openDatabase;
      QueryExecutor openExecutor() {
        if (backend == Backend.sqlite) {
          return NativeDatabase(File('${temp.path}/v2.sqlite'));
        }
        return postgresConfig!.named(databaseName!).toPgDatabase();
      }

      try {
        if (backend == Backend.postgres) {
          databaseName =
              'soar_v3_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 24)}';
          admin = await pg.Connection.open(
            postgresConfig!.named('postgres').toEndpoint(),
            settings: postgresConfig!.toSettings(),
          );
          await admin.execute('CREATE DATABASE "$databaseName"');
        }
        final server = databaseProfile.groups.contains(TableGroup.backendOnly);
        final old = _Version2Database(openExecutor(), profile: databaseProfile);
        openDatabase = old;
        expect(await _hasColumn(old, 'participant_profiles', 'id'), isTrue);
        expect(
          await _indexNames(old),
          isNot(contains('participant_profiles_lower_email')),
        );
        if (server) {
          expect(
            await _hasColumn(old, 'accounts', 'profile_refreshed_at'),
            isFalse,
          );
          expect(
            await _indexNames(old),
            isNot(contains('participant_account_links_account')),
          );
          await old.customStatement(
            "INSERT INTO accounts (id, first_name, last_name, email, email_verified, kind, status, is_system_admin, created_at, updated_at) "
            "VALUES ('acct-1', 'Ada', 'Pilot', 'ada@example.com', ${backend == Backend.sqlite ? '1' : 'TRUE'}, 'registered', 'active', ${backend == Backend.sqlite ? '0' : 'FALSE'}, '2026-01-01T00:00:00.000000Z', '2026-01-01T00:00:00.000000Z')",
          );
        }
        await old.close();
        openDatabase = null;

        for (var open = 0; open < 2; open++) {
          // The second open finds version 3 already in place and changes nothing.
          final upgraded = SoarScoreDatabase(
            openExecutor(),
            profile: databaseProfile,
          );
          openDatabase = upgraded;
          await upgraded.doWhenOpened((_) {});
          expect(
            await _indexNames(upgraded),
            contains('participant_profiles_lower_email'),
          );
          if (server) {
            expect(
              await _hasColumn(upgraded, 'accounts', 'profile_refreshed_at'),
              isTrue,
            );
            expect(
              await _indexNames(upgraded),
              contains('participant_account_links_account'),
            );
            final row = await upgraded
                .customSelect(
                  "SELECT first_name, email, profile_refreshed_at FROM accounts WHERE id = 'acct-1'",
                )
                .getSingle();
            expect(row.read<String>('first_name'), 'Ada');
            expect(row.read<String>('email'), 'ada@example.com');
            expect(row.read<String?>('profile_refreshed_at'), isNull);
          }
          await upgraded.close();
          openDatabase = null;
        }
      } finally {
        await openDatabase?.close();
        if (admin != null) {
          await admin.execute(
            'DROP DATABASE IF EXISTS "$databaseName" WITH (FORCE)',
          );
          await admin.close();
        }
        await temp.delete(recursive: true);
      }
    });
  }
});
