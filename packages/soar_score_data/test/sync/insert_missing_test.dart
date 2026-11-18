import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;

  setUp(() async => inst = await Installation.open(backend));
  tearDown(() => inst.close());

  core.Role role(String name, core.Id id) =>
      core.Role(id: id, displayName: name, type: core.RoleType.nonFlier);

  group('insertMissing', () {
    test(
      'a batch past the variable limit goes in, around stored rows',
      () async {
        final store = inst.stores.of('Role');
        // Far more rows than one statement binds, so several chunks run.
        final ids = [for (var i = 0; i < 700; i++) core.Id.create()];
        final batch = [for (var i = 0; i < 700; i++) role('Role $i', ids[i])];
        // Two stored rows in different chunks: their values must survive.
        await store.upsertJson(role('Stored 3', ids[3]).toJson());
        await store.upsertJson(role('Stored 650', ids[650]).toJson());

        final inserted = await store.insertMissingJson([
          for (final r in batch) r.toJson(),
        ]);

        expect(inserted, 698);
        final stored = {
          for (final r in await store.all())
            (r as core.Role).id.value: r.displayName,
        };
        expect(stored, hasLength(700));
        expect(stored[ids[3].value], 'Stored 3');
        expect(stored[ids[650].value], 'Stored 650');
        expect(stored[ids[0].value], 'Role 0');
        expect(stored[ids[699].value], 'Role 699');
      },
    );

    test('an empty batch inserts nothing', () async {
      expect(await inst.stores.of('Role').insertMissingJson([]), 0);
    });
  });
}
