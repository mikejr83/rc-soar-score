import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

/// The configuration service against the real repositories, so the atomic
/// revision-plus-contest write and the seeded system profiles are the stored
/// ones.
void _tests(Backend backend) {
  group('ContestConfigurationService', () {
    late Installation inst;
    late ContestsService contests;
    late ContestConfigurationService service;
    final actor = core.Id.create();
    final f5jId = core.SystemDisciplineProfiles.f5jId;

    setUp(() async {
      inst = await Installation.open(backend);
      await SystemDataSeeder(inst.db).seed();
      final repository = Repository(inst.db);
      contests = ContestsService(repository);
      service = ContestConfigurationService(repository);
    });

    tearDown(() => inst.close());

    var mutations = 0;
    core.MutationMetadata meta() => core.MutationMetadata(
      clientMutationId: 'request-${mutations++}',
      authority: core.Authority.director,
      clientTime: DateTime.utc(2026, 10, 6),
      actorId: actor,
    );

    Future<core.Id> newContest() async {
      final id = core.Id.create();
      await contests.createContest(
        NewContest(
          id: id,
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
      return id;
    }

    ConfigurationInput input({
      int base = 0,
      Map<String, Object?> coreOptions = const {},
      Map<String, Object?> discipline = const {'working_time': 600},
    }) => ConfigurationInput(
      baseRevisionNumber: base,
      disciplineProfileId: f5jId,
      config: core.ContestConfig(core: coreOptions, discipline: discipline),
    );

    test('the first save stores revision 1 and moves the contest to '
        'configuring', () async {
      final id = await newContest();

      final saved = await service.save(
        id,
        input(),
        createdBy: actor,
        metadata: meta(),
      );

      expect(saved.revision.revisionNumber, 1);
      expect(saved.revision.landingTableId, isNotNull);
      expect(saved.contest.lifecycleState, core.LifecycleState.configuring);
      expect(await service.latest(id), saved.revision);
      expect(
        (await contests.getContest(id)).lifecycleState,
        core.LifecycleState.configuring,
      );
    });

    test('later saves append and stale ones store nothing', () async {
      final id = await newContest();
      await service.save(id, input(), createdBy: actor, metadata: meta());

      final second = await service.save(
        id,
        input(base: 1, discipline: const {'working_time': 480}),
        createdBy: actor,
        metadata: meta(),
      );
      await expectLater(
        service.save(id, input(base: 1), createdBy: actor, metadata: meta()),
        throwsA(isA<core.StaleRevisionError>()),
      );

      expect(second.revision.revisionNumber, 2);
      expect((await service.revisions(id)).map((r) => r.revisionNumber), [
        1,
        2,
      ]);
    });

    test('invalid settings store nothing', () async {
      final id = await newContest();

      await expectLater(
        service.save(
          id,
          input(discipline: const {'working_time': 'ten'}),
          createdBy: actor,
          metadata: meta(),
        ),
        throwsA(isA<core.ScoringValidationError>()),
      );

      expect(await service.revisions(id), isEmpty);
      expect(
        (await contests.getContest(id)).lifecycleState,
        core.LifecycleState.created,
      );
    });
  });
}
