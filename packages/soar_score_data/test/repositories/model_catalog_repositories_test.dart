import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/example_entities.dart';
import '../support/example_rows.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  late Repository repository;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    await loadExamples(inst);
    repository = Repository(inst.db);
  });
  tearDown(() => inst.close());

  group('ModelCatalogRepository', () {
    late core.ModelCatalogRepository repo;
    setUp(() => repo = repository.modelCatalogRepository);

    final examples = [
      for (final row in exampleRows('model_catalog'))
        core.ModelCatalog.fromJson(row),
    ];

    test('reads back the example entries unchanged', () async {
      for (final entry in examples) {
        expect(await repo.findById(entry.id), entry);
      }
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test(
      'listForOwner returns only that director\'s entries by name',
      () async {
        final owner = examples.first.ownerAccountId;
        final owned = examples.where((e) => e.ownerAccountId == owner).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        expect(await repo.listForOwner(owner), owned);
        expect(await repo.listForOwner(core.Id.create()), isEmpty);
      },
    );

    test('listForProfile returns that profile\'s models by name', () async {
      final profile = examples.first.participantProfileId;
      final owned =
          examples.where((e) => e.participantProfileId == profile).toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      expect(await repo.listForProfile(profile), owned);
      expect(await repo.listForProfile(core.Id.create()), isEmpty);
    });

    test('save inserts, then bumps the revision on update', () async {
      final fresh = core.ModelCatalog.fromJson({
        ...examples.first.toJson(),
        'id': core.Id.create().value,
        'name': 'Fresh ${core.Id.create().value}',
        'revision': 0,
      });

      final inserted = await repo.save(fresh, metadata: metadata());
      expect(inserted.revision, 0);

      final renamed = core.ModelCatalog.fromJson({
        ...inserted.toJson(),
        'name': 'Renamed',
      });
      final updated = await repo.save(renamed, metadata: metadata());
      expect(updated.revision, 1);
      expect((await repo.findById(fresh.id))?.name, 'Renamed');
    });

    test('save refuses an entry read at an older revision', () async {
      final stale = core.ModelCatalog.fromJson({
        ...examples.first.toJson(),
        'revision': 0,
      });

      await expectLater(
        repo.save(stale, metadata: metadata()),
        throwsA(isA<core.StaleRevisionError>()),
      );
    });

    test('delete records a tombstone and leaves contest links alone', () async {
      final links = repository.contestModelLinkRepository;
      final catalogId = examples.first.id;
      final before = await links.findById(
        core.ContestModelLink.fromJson(exampleRows('contest_model_link').first)
            .id,
      );
      final tombstones = await inst.count('tombstones');

      expect(await repo.delete(catalogId, metadata: metadata()), isTrue);

      expect(await repo.findById(catalogId), isNull);
      expect(await inst.count('tombstones'), tombstones + 1);
      expect(await repo.delete(catalogId, metadata: metadata()), isFalse);
      final after = await links.findById(before!.id);
      expect(after?.modelName, before.modelName);
    });
  });

  group('ContestModelLinkRepository', () {
    late core.ContestModelLinkRepository repo;
    setUp(() => repo = repository.contestModelLinkRepository);

    final examples = [
      for (final row in exampleRows('contest_model_link'))
        core.ContestModelLink.fromJson(row),
    ];

    test('reads back the example links unchanged', () async {
      for (final link in examples) {
        expect(await repo.findById(link.id), link);
      }
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('lists the links of a participation, any number', () async {
      final link = examples.first;
      final expected = examples.where(
        (l) => l.contestParticipationId == link.contestParticipationId,
      );

      expect(expected.length, greaterThan(1));
      expect(
        await repo.listForParticipation(link.contestParticipationId),
        unorderedEquals(expected),
      );
      expect(await repo.listForParticipation(core.Id.create()), isEmpty);
    });

    test('listForContest returns that contest\'s links', () async {
      final contestId = examples.first.contestId;
      final expected = examples.where((l) => l.contestId == contestId);

      expect(await repo.listForContest(contestId), unorderedEquals(expected));
      expect(await repo.listForContest(core.Id.create()), isEmpty);
    });

    test('save bumps the revision and refuses a stale link', () async {
      final link = examples.first;
      final changed = core.ContestModelLink.fromJson({
        ...link.toJson(),
        'contest_specific_identifier': 'S9',
      });

      final saved = await repo.save(changed, metadata: metadata());
      expect(saved.revision, link.revision + 1);
      expect((await repo.findById(link.id))?.contestSpecificIdentifier, 'S9');
      await expectLater(
        repo.save(changed, metadata: metadata()),
        throwsA(isA<core.StaleRevisionError>()),
      );
    });

    test('delete records a tombstone', () async {
      final id = examples.first.id;
      final tombstones = await inst.count('tombstones');

      expect(await repo.delete(id, metadata: metadata()), isTrue);

      expect(await repo.findById(id), isNull);
      expect(await inst.count('tombstones'), tombstones + 1);
      expect(await repo.delete(id, metadata: metadata()), isFalse);
    });
  });

  group('ContestConfigurationPresetRepository', () {
    late core.ContestConfigurationPresetRepository repo;
    setUp(() => repo = repository.contestConfigurationPresetRepository);

    final examples = [
      for (final row in exampleRows('contest_configuration_preset'))
        core.ContestConfigurationPreset.fromJson(row),
    ];

    test('reads back the example presets unchanged', () async {
      for (final preset in examples) {
        expect(await repo.findById(preset.id), preset);
      }
      expect(await repo.findById(core.Id.create()), isNull);
    });

    test('listForOwner returns only that director\'s presets', () async {
      final owner = examples.first.ownerAccountId;
      final owned = examples.where((p) => p.ownerAccountId == owner).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      expect(await repo.listForOwner(owner), owned);
      expect(await repo.listForOwner(core.Id.create()), isEmpty);
    });

    test('save inserts, bumps the revision and refuses a stale one', () async {
      final fresh = core.ContestConfigurationPreset.fromJson({
        ...examples.first.toJson(),
        'id': core.Id.create().value,
        'name': 'Fresh ${core.Id.create().value}',
        'revision': 0,
      });
      final inserted = await repo.save(fresh, metadata: metadata());
      final renamed = core.ContestConfigurationPreset.fromJson({
        ...inserted.toJson(),
        'name': 'Renamed',
      });

      expect((await repo.save(renamed, metadata: metadata())).revision, 1);
      expect((await repo.findById(fresh.id))?.name, 'Renamed');
      await expectLater(
        repo.save(renamed, metadata: metadata()),
        throwsA(isA<core.StaleRevisionError>()),
      );
    });

    test('delete records a tombstone', () async {
      final id = examples.first.id;
      final tombstones = await inst.count('tombstones');

      expect(await repo.delete(id, metadata: metadata()), isTrue);

      expect(await repo.findById(id), isNull);
      expect(await inst.count('tombstones'), tombstones + 1);
      expect(await repo.delete(id, metadata: metadata()), isFalse);
    });
  });
}
