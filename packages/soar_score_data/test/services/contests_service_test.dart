import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

/// The contest service against the real repository, so the revision checks
/// and mutation records are the stored ones.
void _tests(Backend backend) {
  group('ContestsService writes', () {
    late Installation inst;
    late ContestsService service;
    final actor = core.Id.create();

    setUp(() async {
      inst = await Installation.open(backend);
      service = ContestsService(Repository(inst.db));
    });

    tearDown(() => inst.close());

    var mutations = 0;
    core.MutationMetadata meta() => core.MutationMetadata(
      clientMutationId: 'request-${mutations++}',
      authority: core.Authority.director,
      clientTime: DateTime.utc(2026, 10, 6),
      actorId: actor,
    );

    NewContest newContest() => NewContest(
      id: core.Id.create(),
      timezone: 'America/Denver',
      details: ContestDetails(
        name: 'Spring Open',
        startDateTime: DateTime.utc(2026, 10, 17, 14),
        endDateTime: DateTime.utc(2026, 10, 18, 22),
      ),
    );

    test('creates, reads back and is idempotent on the id', () async {
      final input = newContest();

      final created = await service.createContest(
        input,
        ownerAccountId: actor,
        metadata: meta(),
      );
      final again = await service.createContest(
        input,
        ownerAccountId: actor,
        metadata: meta(),
      );

      expect(created.ownerAccountId, actor);
      expect(created.lifecycleState, core.LifecycleState.created);
      expect(again, created);
      expect(await service.getContest(input.id), created);
    });

    test(
      'update and actions bump the revision and refuse stale ones',
      () async {
        final input = newContest();
        final created = await service.createContest(
          input,
          ownerAccountId: actor,
          metadata: meta(),
        );

        final renamed = await service.updateContest(
          input.id,
          ContestDetails(
            name: 'Renamed',
            startDateTime: created.startDateTime,
            endDateTime: created.endDateTime,
            city: 'Boulder',
          ),
          baseRevision: created.revision,
          metadata: meta(),
        );
        final locked = await service.applyAction(
          input.id,
          core.ContestAction.lock,
          baseRevision: renamed.revision,
          metadata: meta(),
        );

        expect(renamed.revision, created.revision + 1);
        expect(renamed.city, 'Boulder');
        expect(locked.revision, renamed.revision + 1);
        expect(locked.adminLock, core.AdminLock.locked);
        expect(locked.name, 'Renamed');

        await expectLater(
          service.applyAction(
            input.id,
            core.ContestAction.unlock,
            baseRevision: created.revision,
            metadata: meta(),
          ),
          throwsA(isA<core.StaleRevisionError>()),
        );
        await expectLater(
          service.updateContest(
            input.id,
            ContestDetails(
              name: 'Late',
              startDateTime: created.startDateTime,
              endDateTime: created.endDateTime,
            ),
            baseRevision: created.revision,
            metadata: meta(),
          ),
          throwsA(isA<core.StaleRevisionError>()),
        );
        expect((await service.getContest(input.id)).name, 'Renamed');
      },
    );
  });
}
