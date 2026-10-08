import 'dart:convert';

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

  group('create', () {
    final owner = core.Id.create();

    core.LandingTableWithResults owned() {
      final id = core.Id.create();
      return core.LandingTableWithResults(
        table: core.LandingTable(
          id: id,
          ownerAccountId: owner,
          name: 'Club table',
          inputUnit: core.LandingInputUnit.points,
          createdAt: DateTime.utc(2026, 10, 5),
        ),
        results: [
          for (final (i, points) in [10, 5, 0].indexed)
            core.LandingResult(
              id: core.Id.create(),
              landingTableId: id,
              entryKey: 'points_$points',
              displayValue: '$points pts',
              pointValue: points,
              ordinalPosition: i + 1,
            ),
        ],
      );
    }

    test('stores the table with its entries and one mutation', () async {
      final table = owned();
      final before = await inst.count('mutation_records');

      await repo.create(table, metadata: metadata());

      expect(await repo.findById(table.table.id), table);
      expect(await inst.count('mutation_records'), before + 1);
    });

    test('is visible to its owner only', () async {
      final table = owned();
      await repo.create(table, metadata: metadata());

      expect(await repo.listVisibleTo(ownerAccountId: owner), [table]);
      expect(await repo.listVisibleTo(), isEmpty);
    });

    test('refuses a second create of the same table', () async {
      final table = owned();
      await repo.create(table, metadata: metadata());

      await expectLater(
        repo.create(table, metadata: metadata(requestId: 'again')),
        throwsA(isA<core.AlreadyStoredError>()),
      );
    });

    test('refuses a table with no owner and stores nothing', () async {
      await expectLater(
        repo.create(f5j, metadata: metadata()),
        throwsArgumentError,
      );
      expect(await repo.findById(f5j.table.id), isNull);
    });

    test('the mutation payload replicates the whole table', () async {
      final table = owned();
      await repo.create(table, metadata: metadata());
      final row = await inst.db
          .customSelect(
            "SELECT payload FROM mutation_records "
            "WHERE entity_id = '${table.table.id.value}'",
          )
          .getSingle();
      final payload = core.VersionedPayload.fromJson(
        row.data['payload'] is String
            ? jsonDecode(row.read<String>('payload')) as Map<String, Object?>
            : row.data['payload']! as Map<String, Object?>,
      );
      await inst.db.customStatement(
        "DELETE FROM landing_results WHERE landing_table_id = "
        "'${table.table.id.value}'",
      );
      await inst.db.customStatement(
        "DELETE FROM landing_tables WHERE id = '${table.table.id.value}'",
      );

      await inst.applier.apply(
        core.ReplicatedChange(
          scope: core.DirectorScopeKey(owner),
          sequence: 1,
          entityType: 'LandingTable',
          entityId: table.table.id,
          revision: 0,
          payload: payload.data['entity']! as Map<String, Object?>,
        ),
      );

      expect(await repo.findById(table.table.id), table);
    });
  });

  group('delete', () {
    final owner = core.Id.create();

    Future<core.LandingTableWithResults> stored() async {
      final id = core.Id.create();
      final table = core.LandingTableWithResults(
        table: core.LandingTable(
          id: id,
          ownerAccountId: owner,
          name: 'Club table',
          inputUnit: core.LandingInputUnit.points,
          createdAt: DateTime.utc(2026, 10, 5),
        ),
        results: [
          core.LandingResult(
            id: core.Id.create(),
            landingTableId: id,
            entryKey: 'none',
            displayValue: 'None',
            pointValue: 0,
            ordinalPosition: 1,
          ),
        ],
      );
      await repo.create(table, metadata: metadata());
      return table;
    }

    test('removes the table and its entries with a tombstone', () async {
      final table = await stored();
      final mutations = await inst.count('mutation_records');

      expect(
        await repo.delete(table.table.id, metadata: metadata(requestId: 'd')),
        isTrue,
      );

      expect(await repo.findById(table.table.id), isNull);
      expect(await inst.count('landing_results'), 0);
      expect(await inst.count('tombstones'), 1);
      expect(await inst.count('mutation_records'), mutations + 1);
    });

    test('returns false for a table that is not stored', () async {
      expect(
        await repo.delete(core.Id.create(), metadata: metadata()),
        isFalse,
      );
    });

    test('refuses a system table and keeps it', () async {
      await repo.installSystemTable(f5j);

      await expectLater(
        repo.delete(f5j.table.id, metadata: metadata()),
        throwsArgumentError,
      );
      expect(await repo.findById(f5j.table.id), f5j);
    });

    test('a replicated delete removes the entries with the table', () async {
      final table = await stored();

      await inst.applier.apply(
        core.ReplicatedChange(
          scope: core.DirectorScopeKey(owner),
          sequence: 2,
          entityType: 'LandingTable',
          entityId: table.table.id,
          revision: 0,
          isDelete: true,
          payload: const {},
        ),
      );

      expect(await repo.findById(table.table.id), isNull);
      expect(await inst.count('landing_results'), 0);
    });
  });

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

      const shipped = [
        'ALES Standard Landing Table',
        'F3J Landing Distance Table',
        'F3J Standard Landing Table',
        'F5J Landing Distance Table',
        'F5J Standard Landing Table',
      ];
      expect(names, [...shipped, 'Mine', 'Thermal Standard Landing Table']);
      expect(anonymous, [...shipped, 'Thermal Standard Landing Table']);
    });
  });
}
