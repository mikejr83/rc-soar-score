import 'dart:io';

import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

void main() {
  group('a database file from an older build', () {
    late Directory directory;
    late File file;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('soar_score_stale');
      file = File('${directory.path}/soar_score.db');
    });

    tearDown(() => directory.deleteSync(recursive: true));

    test('reopens when every table of the profile exists', () async {
      await createLocalDatabase(file).close();

      final reopened = createLocalDatabase(file);
      await reopened.customSelect('SELECT 1').get();
      await reopened.close();
    });

    test('is rejected with the missing tables named', () async {
      final first = createLocalDatabase(file);
      await first.customSelect('SELECT 1').get();
      await first.customStatement('DROP TABLE local_sync_positions');
      await first.close();

      final reopened = createLocalDatabase(file);
      addTearDown(reopened.close);

      expect(
        reopened.customSelect('SELECT 1').get(),
        throwsA(
          predicate(
            (error) =>
                error.toString().contains('local_sync_positions') &&
                error.toString().contains('delete the database file'),
          ),
        ),
      );
    });
  });
}
