import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

/// The landing table service against the real repositories, so the in-use
/// check sees the stored contest configurations.
void _tests(Backend backend) {
  group('LandingTablesService', () {
    late Installation inst;
    late LandingTablesService service;
    late ContestsService contests;
    late ContestConfigurationService configurations;
    final actor = core.Id.create();

    setUp(() async {
      inst = await Installation.open(backend);
      await SystemDataSeeder(inst.db).seed();
      final repository = Repository(inst.db);
      service = LandingTablesService(repository);
      contests = ContestsService(repository);
      configurations = ContestConfigurationService(repository);
    });

    tearDown(() => inst.close());

    var requests = 0;
    core.MutationMetadata meta() =>
        metadata(requestId: 'landing-${requests++}');

    const entries = [
      LandingEntryInput(
        entryKey: 'within_1m',
        displayValue: '',
        pointValue: 10,
      ),
      LandingEntryInput(
        entryKey: 'within_2m',
        displayValue: '2 m',
        pointValue: 5,
      ),
    ];

    Future<LandingTableView> create({
      core.Id? owner,
      core.Id? id,
      String name = 'Club table',
      List<LandingEntryInput> with_ = entries,
    }) => service.create(
      owner ?? actor,
      id ?? core.Id.create(),
      name: name,
      inputUnit: core.LandingInputUnit.meters,
      entries: with_,
      metadata: meta(),
    );

    Future<void> useInContest(core.Id tableId) async {
      final contestId = core.Id.create();
      await contests.createContest(
        NewContest(
          id: contestId,
          timezone: 'America/Denver',
          details: ContestDetails(
            name: 'Spring Open',
            startDateTime: DateTime.utc(2026, 10, 17, 14),
            endDateTime: DateTime.utc(2026, 10, 18, 22),
          ),
        ),
        ownerAccountId: actor,
        metadata: meta(),
      );
      await configurations.save(
        contestId,
        ConfigurationInput(
          baseRevisionNumber: 0,
          disciplineProfileId: core.SystemDisciplineProfiles.f5jId,
          config: core.ContestConfig(
            core: const {},
            discipline: const {'working_time': 600},
          ),
          landingTableId: tableId,
        ),
        createdBy: actor,
        metadata: meta(),
      );
    }

    test('creates a table whose entries follow the typed order', () async {
      final view = await create();

      expect(view.inUse, isFalse);
      expect(view.table.ownerAccountId, actor);
      expect(
        [for (final r in view.results) r.entryKey],
        ['within_1m', 'within_2m'],
      );
      expect([for (final r in view.results) r.ordinalPosition], [1, 2]);
      // A blank label falls back to the key.
      expect(view.results.first.displayValue, 'within_1m');
    });

    test('derives internal keys from the labels when none are given', () async {
      final view = await create(
        with_: const [
          LandingEntryInput(displayValue: 'Within 1 m', pointValue: 10),
          LandingEntryInput(displayValue: 'within 1 M!', pointValue: 5),
          LandingEntryInput(displayValue: '---', pointValue: 0),
        ],
      );

      expect(
        [for (final r in view.results) r.entryKey],
        ['within_1_m', 'within_1_m_2', 'entry'],
      );
      expect(view.results.first.displayValue, 'Within 1 m');
    });

    test('an entry with neither key nor label is refused', () async {
      await expectLater(
        create(
          with_: const [LandingEntryInput(displayValue: ' ', pointValue: 1)],
        ),
        throwsArgumentError,
      );
    });

    test('repeating a create returns the stored table', () async {
      final id = core.Id.create();
      final first = await create(id: id);

      expect(await create(id: id), first);
    });

    test('the same id with other content is refused', () async {
      final id = core.Id.create();
      await create(id: id);

      await expectLater(
        create(id: id, name: 'Other'),
        throwsA(isA<core.AlreadyStoredError>()),
      );
    });

    test('refuses a repeated key, no entries, a blank name and negative '
        'points', () async {
      await expectLater(
        create(
          with_: const [
            LandingEntryInput(entryKey: 'a', displayValue: '', pointValue: 1),
            LandingEntryInput(entryKey: 'a', displayValue: '', pointValue: 2),
          ],
        ),
        throwsArgumentError,
      );
      await expectLater(create(with_: const []), throwsArgumentError);
      await expectLater(create(name: '  '), throwsArgumentError);
      await expectLater(
        create(
          with_: const [
            LandingEntryInput(entryKey: 'a', displayValue: '', pointValue: -1),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('lists the system tables and only the caller\'s own', () async {
      await create(name: 'Mine');
      await create(owner: core.Id.create(), name: 'Theirs');

      final names = [for (final v in await service.list(actor)) v.table.name];

      expect(names, contains('Mine'));
      expect(names, contains('F5J Standard Landing Table'));
      expect(names, isNot(contains('Theirs')));
    });

    test('a table a contest configuration uses is in use and cannot be '
        'removed', () async {
      final view = await create();
      await useInContest(view.table.id);

      final listed = (await service.list(actor))
          .firstWhere((v) => v.table.id == view.table.id);
      expect(listed.inUse, isTrue);
      await expectLater(
        service.delete(actor, view.table.id, metadata: meta()),
        throwsA(
          isA<core.ContestStateError>().having((e) => e.code, 'code', 'in_use'),
        ),
      );
      expect(
        await Repository(inst.db).landingTableRepository
            .findById(view.table.id),
        isNotNull,
      );
    });

    test(
      'removes an unused table with its entries, leaving a tombstone',
      () async {
        final view = await create();
        final repository = Repository(inst.db).landingTableRepository;

        await service.delete(actor, view.table.id, metadata: meta());

        expect(await repository.findById(view.table.id), isNull);
        expect(await inst.count('landing_results'), greaterThan(0)); // system
        final remaining = await inst.db
            .customSelect(
              "SELECT COUNT(*) AS n FROM landing_results "
              "WHERE landing_table_id = '${view.table.id.value}'",
            )
            .getSingle();
        expect(remaining.read<int>('n'), 0);
        final tombstones = await inst.db
            .customSelect(
              "SELECT COUNT(*) AS n FROM tombstones "
              "WHERE entity_id = '${view.table.id.value}'",
            )
            .getSingle();
        expect(tombstones.read<int>('n'), 1);
      },
    );

    test('refuses a system table', () async {
      await expectLater(
        service.delete(
          actor,
          core.SystemLandingTables.f5jStandard.table.id,
          metadata: meta(),
        ),
        throwsA(
          isA<core.ContestStateError>().having(
            (e) => e.code,
            'code',
            'system_table',
          ),
        ),
      );
    });

    test('another director\'s table is not found', () async {
      final view = await create(owner: core.Id.create());

      await expectLater(
        service.delete(actor, view.table.id, metadata: meta()),
        throwsA(isA<core.EntityNotFoundError>()),
      );
    });
  });
}
