import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

const _systemTables = [
  'landing_tables',
  'landing_results',
  'discipline_profiles',
  'discipline_config_fields',
  'discipline_score_fields',
  'discipline_validations',
  'discipline_formulas',
  'discipline_rules',
  'roles',
];

void _tests(Backend backend) {
  late Installation inst;
  late Repository repository;

  setUp(() async {
    inst = await Installation.open(backend);
    repository = Repository(inst.db);
  });
  tearDown(() => inst.close());

  Future<int> count(String table) async =>
      (await inst.db
              .customSelect('SELECT count(*) AS n FROM $table')
              .getSingle())
          .read<int>('n');

  Future<List<int>> counts() async => [
    for (final table in [..._systemTables, 'mutation_records'])
      await count(table),
  ];

  const systemScope = core.SystemScopeKey();

  group('SystemDataSeeder', () {
    test('a fresh database holds all the shipped system data', () async {
      final outcome = await SystemDataSeeder(inst.db).seed();

      expect(outcome, SystemSeedOutcome.installed);
      expect(
        await repository.landingTableRepository.listVisibleTo(),
        unorderedEquals(core.SystemLandingTables.all),
      );
      expect(
        await repository.disciplineProfileRepository.listPublished(),
        unorderedEquals(core.SystemDisciplineProfiles.all),
      );
      expect(
        await repository.roleRepository.listVisibleTo(),
        unorderedEquals(core.SystemRoles.all),
      );
      expect(await count('mutation_records'), 0);
    });

    test('a native database records the shipped sequence', () async {
      if (!inst.hasClientTables) {
        markTestSkipped('the server keeps no system-data position');
        return;
      }

      await SystemDataSeeder(inst.db).seed();

      expect(
        await inst.syncStore.readCursor(systemScope),
        core.SystemSeed.sequence,
      );
    });

    test('a second run changes nothing and writes no mutation', () async {
      await SystemDataSeeder(inst.db).seed();
      final before = await counts();

      final outcome = await SystemDataSeeder(inst.db).seed();

      expect(
        outcome,
        inst.hasClientTables
            ? SystemSeedOutcome.upToDate
            : SystemSeedOutcome.installed,
      );
      expect(await counts(), before);
      expect(before.last, 0);
    });

    test('a database with a higher sequence is left untouched', () async {
      if (!inst.hasClientTables) {
        markTestSkipped('the server keeps no system-data position');
        return;
      }
      await inst.syncStore.writeCursor(
        systemScope,
        core.SystemSeed.sequence + 4,
      );

      final outcome = await SystemDataSeeder(inst.db).seed();

      expect(outcome, SystemSeedOutcome.upToDate);
      expect(await counts(), everyElement(0));
      expect(
        await inst.syncStore.readCursor(systemScope),
        core.SystemSeed.sequence + 4,
      );
    });

    test('a later version installs again and raises the sequence', () async {
      if (!inst.hasClientTables) {
        markTestSkipped('the server keeps no system-data position');
        return;
      }
      await SystemDataSeeder(inst.db).seed();
      final before = await counts();

      final outcome = await SystemDataSeeder(inst.db, sequence: 2).seed();

      expect(outcome, SystemSeedOutcome.installed);
      expect(await inst.syncStore.readCursor(systemScope), 2);
      expect(await counts(), before);
      expect(
        await SystemDataSeeder(inst.db, sequence: 1).seed(),
        SystemSeedOutcome.upToDate,
      );
      expect(await inst.syncStore.readCursor(systemScope), 2);
    });

    test('a failure partway leaves no partial data', () async {
      // The profile names a default table that is not in the data, so the
      // landing table is installed before the profile fails.
      final seeder = SystemDataSeeder(
        inst.db,
        landingTables: [core.SystemLandingTables.f5jStandard],
        profiles: [core.SystemDisciplineProfiles.f3j],
      );

      await expectLater(seeder.seed(), throwsStateError);

      expect(await counts(), everyElement(0));
      if (inst.hasClientTables) {
        expect(await inst.syncStore.readCursor(systemScope), 0);
      }
    });

    test('rejects a sequence below 1', () {
      expect(() => SystemDataSeeder(inst.db, sequence: 0), throwsArgumentError);
    });
  });
}
