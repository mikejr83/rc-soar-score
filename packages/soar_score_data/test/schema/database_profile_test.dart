import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

Future<Set<String>> _tableNames(SoarScoreDatabase db) async {
  final rows = await db
      .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
      .get();
  return {for (final row in rows) row.read<String>('name')};
}

void main() {
  group('DatabaseProfile', () {
    test('native has every group except backend only', () {
      expect(
        DatabaseProfile.native.groups,
        equals(TableGroup.values.toSet()..remove(TableGroup.backendOnly)),
      );
    });

    test('server has every group except client only', () {
      expect(
        DatabaseProfile.server.groups,
        equals(TableGroup.values.toSet()..remove(TableGroup.clientOnly)),
      );
    });
  });

  group('table groups', () {
    late SoarScoreDatabase db;

    setUp(
      () => db = SoarScoreDatabase(
        NativeDatabase.memory(),
        profile: DatabaseProfile.server,
      ),
    );
    tearDown(() => db.close());

    test('every table of the database has a group', () {
      for (final table in db.allTables) {
        expect(
          tableGroupByName,
          contains(table.actualTableName),
          reason: '${table.actualTableName} needs a table group',
        );
      }
    });

    test('no group is listed for a table that does not exist', () {
      expect(
        tableGroupByName.keys.toSet(),
        equals({for (final t in db.allTables) t.actualTableName}),
      );
    });

    test('tablesFor refuses a table without a group', () {
      expect(
        () => tablesFor(DatabaseProfile.native, db.allTables, groups: {}),
        throwsStateError,
      );
    });
  });

  group('creation by profile', () {
    for (final profile in DatabaseProfile.values) {
      test('${profile.name} creates the tables of its groups', () async {
        final db = SoarScoreDatabase(NativeDatabase.memory(), profile: profile);
        addTearDown(db.close);

        final created = await _tableNames(db);
        final expected = {
          for (final t in db.allTables)
            if (profile.groups.contains(tableGroupByName[t.actualTableName]))
              t.actualTableName,
        };
        expect(created.where((n) => !n.startsWith('sqlite_')), expected);
        expect(created, contains('contests'));
        expect(
          created.contains('local_sync_positions'),
          profile == DatabaseProfile.native,
        );
      });
    }
  });

  group('enum check constraints', () {
    late SoarScoreDatabase db;

    setUp(
      () => db = SoarScoreDatabase(
        NativeDatabase.memory(),
        profile: DatabaseProfile.native,
      ),
    );
    tearDown(() => db.close());

    Future<void> insert({String lifecycle = 'Created'}) => db.customInsert(
      'INSERT INTO contests (id, name, start_date_time, end_date_time, '
      'timezone, lifecycle_state, scoring_access, admin_lock, created_at, '
      'updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        const Variable('0195a123-4567-7890-abcd-ef0123456789'),
        const Variable('Meet'),
        const Variable('2026-01-02T03:04:05Z'),
        const Variable('2026-01-03T03:04:05Z'),
        const Variable('UTC'),
        Variable(lifecycle),
        const Variable('Closed'),
        const Variable('Unlocked'),
        const Variable('2026-01-01T00:00:00Z'),
        const Variable('2026-01-01T00:00:00Z'),
      ],
    );

    test('accepts a documented value', () async {
      await insert(lifecycle: 'Running');
    });

    test('rejects text that is not a documented value', () {
      expect(() => insert(lifecycle: 'running'), throwsA(anything));
    });
  });
}
