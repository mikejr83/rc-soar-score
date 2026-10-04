import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

void main() {
  group('ContestDatabase (in-memory SQLite)', () {
    late SoarScoreDatabase database;

    setUp(() {
      database = SoarScoreDatabase(
        NativeDatabase.memory(),
        profile: DatabaseProfile.native,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'performs a trivial query without the Flutter SQLite plugin',
      () async {
        final rows = await database
            .customSelect('SELECT 1 AS one, sqlite_version() AS version')
            .get();
        expect(rows, hasLength(1));
        expect(rows.first.read<int>('one'), 1);
        expect(rows.first.read<String>('version'), isNotEmpty);
      },
    );

    test('runs the initial schema migration on open', () async {
      final versionRow = await database
          .customSelect('PRAGMA user_version')
          .get()
          .then((rows) => rows.single);
      expect(versionRow.read<int>('user_version'), 1);

      final tables = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
          )
          .get();
      final names = tables.map((t) => t.read<String>('name')).toList();
      expect(names, containsAll(['contests']));
    });

    test('supports raw inserts into the migrated schema', () async {
      await database.customInsert(
        'INSERT INTO contests (id, name, start_date_time, end_date_time, '
        'timezone, lifecycle_state, scoring_access, admin_lock, created_at, '
        'updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        variables: const [
          Variable('0195a123-4567-7890-abcd-ef0123456789'),
          Variable('Raw query contest'),
          Variable('2026-01-02T03:04:05Z'),
          Variable('2026-01-03T03:04:05Z'),
          Variable('UTC'),
          Variable('Created'),
          Variable('Closed'),
          Variable('Unlocked'),
          Variable('2026-01-01T00:00:00Z'),
          Variable('2026-01-01T00:00:00Z'),
        ],
      );
      final rows = await database
          .customSelect('SELECT COUNT(*) AS n FROM contests')
          .get();
      expect(rows.first.read<int>('n'), 1);
    });
  });
}
