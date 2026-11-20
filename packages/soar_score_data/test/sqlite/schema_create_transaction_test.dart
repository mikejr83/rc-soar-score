import 'dart:io';

import 'package:drift/native.dart';
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

void main() {
  test('a first run builds the whole schema in one transaction', () async {
    // Each DDL statement outside a transaction commits and syncs to disk on
    // its own (about 120 times; seconds on a slow disk). A count, no timing.
    final dir = Directory.systemTemp.createTempSync('schema_create');
    addTearDown(() => dir.deleteSync(recursive: true));
    var commits = 0;
    final db = SoarScoreDatabase(
      NativeDatabase(
        File('${dir.path}/soar_score.db'),
        setup: (raw) => raw.commits.listen((_) => commits++),
      ),
      profile: DatabaseProfile.native,
    );
    addTearDown(db.close);

    await db.customSelect('SELECT 1').get();

    // The schema in one commit, plus the version stamp; it was 61 commits.
    expect(commits, lessThanOrEqualTo(3));
    final tables = await db
        .customSelect(
          "SELECT count(*) AS n FROM sqlite_master WHERE type = 'table'",
        )
        .getSingle();
    expect(tables.read<int>('n'), greaterThan(30));
  });
}
