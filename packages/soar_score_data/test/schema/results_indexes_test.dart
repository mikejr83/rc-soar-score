import 'dart:io';

import 'package:drift/native.dart';
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

/// The plain indexes behind results, scores and report reads (#843).
const _expected = {
  'rounds_contest',
  'matrix_assignments_scheduled_round',
  'score_placeholders_contest',
  'score_placeholders_participation',
  'score_attempts_placeholder',
  'flight_results_contest_round',
  'participation_standings_contest_round',
};

void main() {
  test('a new database has the results indexes', () async {
    final db = SoarScoreDatabase(
      NativeDatabase.memory(),
      profile: DatabaseProfile.server,
    );
    addTearDown(db.close);

    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    final names = {for (final row in rows) row.read<String>('name')};
    expect(names, containsAll(_expected));
  });

  test('the one-time script for existing databases creates the same', () {
    final script = File('../../scripts/add-results-indexes.sql')
        .readAsStringSync();
    final named = RegExp(r'CREATE INDEX IF NOT EXISTS (\w+) ')
        .allMatches(script)
        .map((m) => m.group(1)!)
        .toSet();
    expect(named, equals(_expected));
  });
}
