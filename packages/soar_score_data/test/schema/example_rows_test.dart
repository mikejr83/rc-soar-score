import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import 'package:soar_score_data/soar_score_data.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  test('every example file is on the list', () {
    expect(
      [for (final (_, file) in exampleEntities) file]..sort(),
      equals(exampleFileNames()),
    );
  });

  late Installation inst;
  setUp(
    () async => inst = await Installation.open(
      backend,
      profile: DatabaseProfile.server,
    ),
  );
  tearDown(() => inst.close());

  test('every example row persists and reads back as written', () async {
    for (final (entity, file) in exampleEntities) {
      final rows = exampleRows(file);
      final store = inst.stores.of(entity);
      for (final (i, row) in rows.indexed) {
        await store.upsertJson(row);
        final back = await store.findJson(core.Id.parse(row['id']! as String));
        expect(
          store.encode(store.decode(back!)),
          equals(row),
          reason: '$entity #$i',
        );
      }
    }
  });
}
