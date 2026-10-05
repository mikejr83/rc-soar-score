import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  late Repository repository;
  late core.DisciplineProfileRepository repo;

  setUp(() async {
    inst = await Installation.open(backend, profile: DatabaseProfile.server);
    repository = Repository(inst.db);
    repo = repository.disciplineProfileRepository;
  });
  tearDown(() => inst.close());

  Future<void> installTables() async {
    for (final table in core.SystemLandingTables.all) {
      await repository.landingTableRepository.installSystemTable(table);
    }
  }

  Future<int> rowCount(String table) async =>
      (await inst.db
              .customSelect('SELECT count(*) AS n FROM $table')
              .getSingle())
          .read<int>('n');

  final f5j = core.SystemDisciplineProfiles.f5j;

  group('DisciplineProfileRepository', () {
    test(
      'installs every shipped profile and reads each back unchanged',
      () async {
        await installTables();

        for (final shipped in core.SystemDisciplineProfiles.all) {
          expect(await repo.installSystemProfile(shipped), isTrue);
          expect(await repo.findById(shipped.profile.id), shipped);
        }
      },
    );

    test('installing twice stores the profile and its rows once', () async {
      await installTables();
      await repo.installSystemProfile(f5j);
      final counts = [
        for (final table in [
          'discipline_profiles',
          'discipline_config_fields',
          'discipline_score_fields',
          'discipline_validations',
          'discipline_formulas',
          'discipline_rules',
        ])
          await rowCount(table),
      ];

      expect(await repo.installSystemProfile(f5j), isFalse);
      expect([
        for (final table in [
          'discipline_profiles',
          'discipline_config_fields',
          'discipline_score_fields',
          'discipline_validations',
          'discipline_formulas',
          'discipline_rules',
        ])
          await rowCount(table),
      ], counts);
      expect(counts.first, 1);
      expect(counts.skip(1), everyElement(greaterThan(0)));
      expect(await repo.findById(f5j.profile.id), f5j);
    });

    test('fails clearly, storing nothing, without the landing table', () async {
      await expectLater(
        repo.installSystemProfile(f5j),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('landing table'),
          ),
        ),
      );

      expect(await repo.findById(f5j.profile.id), isNull);
      expect(await rowCount('discipline_profiles'), 0);
    });

    test('listPublished lists the published profiles by type', () async {
      await installTables();
      for (final shipped in core.SystemDisciplineProfiles.all) {
        await repo.installSystemProfile(shipped);
      }

      final listed = await repo.listPublished();

      expect(listed.map((p) => p.profile.type.name), [
        'ales',
        'f3j',
        'f5j',
        'thermalDuration',
      ]);
      expect(listed, containsAll(core.SystemDisciplineProfiles.all));
    });

    test('listPublished leaves out a profile that is not published', () async {
      await installTables();
      await repo.installSystemProfile(f5j);
      final draftId = core.Id.create();
      final head = f5j.profile;
      await inst.stores
          .of('DisciplineProfile')
          .upsertJson(
            core.DisciplineProfile(
              id: draftId,
              type: head.type,
              version: 2,
              name: head.name,
              category: head.category,
              defaultLandingTableId: head.defaultLandingTableId,
              createdBy: head.createdBy,
              createdAt: head.createdAt,
            ).toJson(),
          );

      expect((await repo.listPublished()).map((p) => p.profile.id), [head.id]);
      expect(await repo.findById(draftId), isNotNull);
    });

    test('findById is null for an unknown profile', () async {
      expect(await repo.findById(core.Id.create()), isNull);
    });
  });
}
