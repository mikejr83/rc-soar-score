import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  late core.LandingTableRepository repo;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    repo = Repository(inst.db).landingTableRepository;
  });
  tearDown(() => inst.close());

  final f5j = core.SystemLandingTables.f5jStandard;

  Future<void> storeOwned(core.Id owner, String name) async {
    final id = core.Id.create();
    final table = core.LandingTable(
      id: id,
      ownerAccountId: owner,
      name: name,
      inputUnit: core.LandingInputUnit.points,
      createdAt: DateTime.utc(2026, 10, 1),
    );
    await inst.stores.of('LandingTable').upsertJson(table.toJson());
    await inst.stores
        .of('LandingResult')
        .upsertJson(
          core.LandingResult(
            id: core.Id.create(),
            landingTableId: id,
            entryKey: 'none',
            displayValue: 'None',
            pointValue: 0,
            ordinalPosition: 1,
          ).toJson(),
        );
  }

  group('LandingTableRepository', () {
    test('installs a system table and reads it back unchanged', () async {
      expect(await repo.installSystemTable(f5j), isTrue);

      expect(await repo.findById(f5j.table.id), f5j);
    });

    test('installing again is a no-op', () async {
      await repo.installSystemTable(f5j);

      expect(await repo.installSystemTable(f5j), isFalse);
      expect((await repo.findById(f5j.table.id))?.results, f5j.results);
    });

    test('refuses a table with an owner', () {
      final owned = core.LandingTableWithResults(
        table: core.LandingTable(
          id: f5j.table.id,
          ownerAccountId: core.Id.create(),
          name: 'Mine',
          inputUnit: core.LandingInputUnit.meters,
          createdAt: DateTime.utc(2026, 10, 1),
        ),
        results: f5j.results,
      );

      expect(() => repo.installSystemTable(owned), throwsArgumentError);
    });

    test('findById is null for an unknown table', () async {
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('listVisibleTo shows system tables and the director\'s own', () async {
      final mine = core.Id.create();
      final other = core.Id.create();
      for (final t in core.SystemLandingTables.all) {
        await repo.installSystemTable(t);
      }
      await storeOwned(mine, 'Mine');
      await storeOwned(other, 'Theirs');

      final names = (await repo.listVisibleTo(ownerAccountId: mine))
          .map((t) => t.table.name);
      final anonymous = (await repo.listVisibleTo()).map((t) => t.table.name);

      expect(names, [
        'F5J Landing Distance Table',
        'F5J Standard Landing Table',
        'Mine',
      ]);
      expect(anonymous, [
        'F5J Landing Distance Table',
        'F5J Standard Landing Table',
      ]);
    });
  });
}
