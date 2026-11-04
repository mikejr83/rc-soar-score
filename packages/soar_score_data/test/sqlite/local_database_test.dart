import 'dart:io';

import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/fixtures.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('soar-local-db'));
  tearDown(() => dir.deleteSync(recursive: true));

  test(
    'the local database opens in the background and keeps its data',
    () async {
      final file = File('${dir.path}/soar_score.db');
      var database = createLocalDatabase(file);
      final id = core.Id.create();
      await SystemDataSeeder(database).seed();
      final repository = Repository(database);
      await repository.contestRepository.save(
        contest(id: id, name: 'Kept'),
        metadata: metadata(),
      );
      final rows = await database
          .customSelect('SELECT COUNT(*) AS c FROM contests')
          .getSingle();
      expect(rows.read<int>('c'), 1);
      await database.close();

      // What was written is on disk for the next start.
      database = createLocalDatabase(file);
      final again = await Repository(database).contestRepository.findById(id);
      expect(again?.name, 'Kept');
      await database.close();
    },
  );
}
