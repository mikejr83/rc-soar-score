import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

/// A configuration save and a matrix draw each leave one audit event, in the
/// same transaction as the change.
void _tests(Backend backend) {
  group('configuration and matrix audit events', () {
    late Installation inst;
    late Repository repository;
    late core.Id contestId;
    final actor = core.Id.create();
    var mutations = 0;

    core.MutationMetadata meta() => core.MutationMetadata(
      clientMutationId: 'audit-${mutations++}',
      authority: core.Authority.director,
      clientTime: DateTime.utc(2026, 10, 17, 15),
      actorId: actor,
    );

    Future<List<core.AuditEvent>> events(core.AuditAction action) => repository
        .auditEventRepository
        .listForContest(contestId, action: action);

    setUp(() async {
      inst = await Installation.open(backend);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      contestId = await drawnContest(repository, actor, rounds: 2);
    });

    tearDown(() => inst.close());

    test('the first save and the first draw leave one event each', () async {
      final saved = await events(core.AuditAction.configurationSaved);
      expect(saved, hasLength(1));
      expect(saved.single.entityType, 'ContestConfigurationRevision');
      expect(saved.single.actorId, actor);
      expect(saved.single.baseRevision, isNull);
      expect(saved.single.resultingRevision, 1);

      final revisions = await repository.matrixRevisionRepository
          .listForContest(contestId);
      final drawn = await events(core.AuditAction.matrixDrawn);
      expect(drawn, hasLength(1));
      expect(drawn.single.entityType, 'MatrixRevision');
      expect(drawn.single.entityId, revisions.single.id);
      expect(drawn.single.reason, 'initial draw');
      expect(drawn.single.baseRevision, isNull);
      expect(drawn.single.resultingRevision, 1);
    });

    test('a redraw leaves an event with its matrix revision', () async {
      await MatrixRedrawService(repository).redraw(
        contestId,
        id: core.Id.create(),
        firstRound: 2,
        base: 1,
        rounds: 1,
        groupsPerRound: 1,
        randomSeed: 3,
        actorId: actor,
        metadata: meta(),
      );

      final drawn = await events(core.AuditAction.matrixDrawn);
      expect(drawn, hasLength(2));
      expect(drawn.first.reason, 'redraw from round 2');
      expect(drawn.first.baseRevision, 1);
      expect(drawn.first.resultingRevision, 2);
    });

    test('a refused save leaves no event', () async {
      final latest = await ContestConfigurationService(repository)
          .latest(contestId);
      await expectLater(
        ContestConfigurationService(repository).save(
          contestId,
          ConfigurationInput(
            baseRevisionNumber: latest.revisionNumber + 5,
            disciplineProfileId: latest.disciplineProfileId,
            config: latest.config,
          ),
          createdBy: actor,
          metadata: meta(),
        ),
        throwsA(isA<core.StaleRevisionError>()),
      );

      expect(await events(core.AuditAction.configurationSaved), hasLength(1));
    });

    test('a refused draw leaves no event', () async {
      await expectLater(
        MatrixRedrawService(repository).redraw(
          contestId,
          id: core.Id.create(),
          firstRound: 9,
          base: 1,
          rounds: 1,
          groupsPerRound: 1,
          actorId: actor,
          metadata: meta(),
        ),
        throwsArgumentError,
      );

      expect(await events(core.AuditAction.matrixDrawn), hasLength(1));
    });
  });
}
