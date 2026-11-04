import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/draw_import_fixtures.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

const _fingerprint = 'sha256:abc';

void _tests(Backend backend) {
  late Installation inst;
  late ContestImportRepository importer;
  late Repository repository;
  final owner = core.Id.create();
  final signedIn = core.ImportOwner(signedInAccountId: owner);

  setUp(() async {
    inst = await Installation.open(backend);
    await SystemDataSeeder(inst.db).seed();
    importer = ContestImportRepository(inst.db);
    repository = Repository(inst.db);
  });
  tearDown(() => inst.close());

  /// A phase B contest from competition [compNo] with pilots 1..6.
  Future<core.Id> contestFor({
    int compNo = 22,
    String fingerprint = _fingerprint,
  }) async {
    final profiles = <int, core.Id>{};
    for (var n = 1; n <= 6; n++) {
      final saved = await repository.participantProfileRepository.save(
        core.ParticipantProfile(
          id: core.Id.create(),
          ownerAccountId: owner,
          firstName: 'Pilot',
          lastName: 'Number$n',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        metadata: metadata(),
      );
      profiles[n] = saved.id;
    }
    final result = await importer.importCompetition(
      core.CompetitionImportPlan(
        draft: core.ContestImportDraft(
          sourceCompNo: compNo,
          sourceClass: 'F5J',
          status: core.ContestImportStatus.importable,
          name: 'Imported Open $compNo',
          startDate: DateTime.utc(2026, 5, 9),
          disciplineType: 'F5J',
          config: core.ContestConfig(core: const {}, discipline: const {}),
          participants: [
            for (var n = 1; n <= 6; n++)
              core.ParticipationDraft(
                sourcePilotNo: n,
                role: core.ImportedRole.pilot,
                sourceRole: 'Plt',
              ),
          ],
        ),
        profileIds: profiles,
        owner: signedIn,
        timezone: 'UTC',
        importOperationId: core.Id.create(),
        fileFingerprint: fingerprint,
        toolVersion: '1.0.0',
      ),
      metadata: metadata(),
    );
    return (result as core.CompetitionImported).contestId;
  }

  core.DrawImportPlan plan(
    core.DrawImportDraft draft,
    core.Id contestId, {
    String fingerprint = _fingerprint,
    core.ImportOwner? who,
  }) => core.DrawImportPlan(
    draft: draft,
    contestId: contestId,
    owner: who ?? signedIn,
    importOperationId: core.Id.create(),
    fileFingerprint: fingerprint,
    toolVersion: '1.0.0',
  );

  Future<core.DrawImportResult> importDraw(
    core.DrawImportDraft draft,
    core.Id contestId,
  ) => importer.importDraw(plan(draft, contestId), metadata: metadata());

  group('importDraw', () {
    test('writes the finalized draw and makes the contest Ready', () async {
      final contestId = await contestFor();
      final result = await importDraw(
        drawDraft(drawRows(22, [2, 2]), lanes: 3),
        contestId,
      );
      final done = result as core.DrawImported;
      expect(done.revisionCount, 1);
      expect(done.roundCount, 2);
      expect(done.assignmentCount, 12);

      final contest = (await repository.contestRepository.findById(contestId))!;
      expect(contest.lifecycleState, core.LifecycleState.ready);

      final revisions = await repository.matrixRevisionRepository
          .listForContest(contestId);
      final revision = revisions.single;
      expect(revision.isFinalized, isTrue);
      expect(revision.randomSeed, 0);
      expect(revision.algorithmVersion, 'import:gliderscore/1');
      expect(revision.drawMode, core.DrawMode.standardManOnMan);
      expect(revision.drawConfig['groups_per_round'], 2);
      expect(revision.seedingSnapshot['pilots'], isEmpty);
      expect(revision.fairnessSummary, isNotNull);

      final matrix = await core.MatrixService(repository).current(contestId);
      expect(matrix.rounds.map((r) => r.ordinal), [1, 2]);
      expect(matrix.rounds.every((r) => r.groupCount == 2), isTrue);
      expect(matrix.assignments, hasLength(12));
      expect(
        matrix.assignments.every(
          (a) => a.assignmentType == core.AssignmentType.original,
        ),
        isTrue,
      );
      // Lanes follow the position in the group.
      expect({for (final a in matrix.assignments) a.lane}, {1, 2, 3});
      final placeholders = await repository.scorePlaceholderRepository
          .listForContest(contestId);
      expect(placeholders, hasLength(12));
      expect(
        placeholders.every(
          (p) => p.state == core.ScorePlaceholderState.notEntered,
        ),
        isTrue,
      );
      final participations = await repository.contestParticipationRepository
          .listForContest(contestId);
      expect(participations.every((p) => p.participantNumber != null), isTrue);
    });

    test(
      'stamps the revision, with positions when there are no lanes',
      () async {
        final contestId = await contestFor();
        await importDraw(drawDraft(drawRows(22, [2, 2])), contestId);

        final matrix = await core.MatrixService(repository).current(contestId);
        expect(matrix.assignments.every((a) => a.lane == null), isTrue);

        final stamps =
            (await repository.importProvenanceRepository.listForContest(
              contestId,
            )).where((s) => s.stampedEntityType == 'MatrixRevision').toList();
        expect(stamps, hasLength(1));
        final stamp = stamps.single;
        expect(stamp.sourceKeys, {'comp_no': 22, 'task_no': 1});
        expect(stamp.ownerAccountId, owner);
        expect(stamp.dedupeKey, isNull);
        expect(stamp.stampedEntityId, matrix.revision!.id);
        expect(stamp.sourceValues!['first_round'], 1);
        expect(stamp.sourceValues!['last_round'], 2);
        expect(stamp.sourceValues!['groups_per_round'], 2);
        final positions = stamp.sourceValues!['positions']! as List<Object?>;
        expect(positions, hasLength(12));
        expect(positions.first, [1, 1, 1, 1]);
      },
    );

    test('keeps no positions when the competition has lanes', () async {
      final contestId = await contestFor();
      await importDraw(drawDraft(drawRows(22, [2]), lanes: 3), contestId);
      final stamp = (await repository.importProvenanceRepository.listForContest(
        contestId,
      )).singleWhere((s) => s.stampedEntityType == 'MatrixRevision');
      expect(stamp.sourceValues!.containsKey('positions'), isFalse);
    });

    test('a changed group count writes chained revisions', () async {
      final contestId = await contestFor();
      final result = await importDraw(
        drawDraft(drawRows(22, [2, 1, 1]), lanes: 6),
        contestId,
      );
      expect((result as core.DrawImported).revisionCount, 2);
      final revisions = await repository.matrixRevisionRepository
          .listForContest(contestId);
      expect(revisions.map((r) => r.revisionNumber), [1, 2]);
      expect(revisions.map((r) => r.firstRound), [1, 2]);
      expect(revisions.map((r) => r.lastRound), [1, 3]);
      expect(revisions[1].previousRevisionId, revisions[0].id);
      expect(revisions[1].drawConfig['groups_per_round'], 1);
      final matrix = await core.MatrixService(repository).current(contestId);
      expect(matrix.rounds.map((r) => r.groupCount), [2, 1, 1]);
      final stamps =
          (await repository.importProvenanceRepository.listForContest(
            contestId,
          )).where((s) => s.stampedEntityType == 'MatrixRevision');
      expect(stamps, hasLength(2));
    });

    test('writes Restoration audit events with the operation id', () async {
      final contestId = await contestFor();
      final p = plan(drawDraft(drawRows(22, [2])), contestId);
      await importer.importDraw(p, metadata: metadata());
      final events = await repository.auditEventRepository.listForContest(
        contestId,
        action: core.AuditAction.restoration,
      );
      expect(events.map((e) => e.entityType).toSet(), {
        'Contest',
        'MatrixRevision',
      });
      expect(events.map((e) => e.reason).toSet(), {
        'import:gliderscore:${p.importOperationId.value}',
      });
    });

    test('a tail redraw of an imported matrix still works', () async {
      final contestId = await contestFor();
      await importDraw(drawDraft(drawRows(22, [2, 2, 2])), contestId);
      final base = (await repository.matrixRevisionRepository.latestForContest(
        contestId,
      ))!;
      final matrix = await core.MatrixRedrawService(repository).redraw(
        contestId,
        id: core.Id.create(),
        firstRound: 2,
        rounds: 2,
        groupsPerRound: 3,
        randomSeed: 5,
        base: base.revisionNumber,
        actorId: owner,
        metadata: metadata(),
      );
      expect(matrix.rounds.map((r) => r.groupCount), [2, 3, 3]);
      expect(matrix.revision!.revisionNumber, 2);
    });

    test('the target reads the stamp, matrix and pilots', () async {
      final contestId = await contestFor();
      final before = await importer.drawTarget(signedIn, 22, _fingerprint);
      expect(before.stamped, isTrue);
      expect(before.contestId, contestId);
      expect(before.stampedFingerprint, _fingerprint);
      expect(before.hasMatrix, isFalse);
      expect(before.hasAcceptedScores, isFalse);
      expect(before.participantPilotNos, {1, 2, 3, 4, 5, 6});

      await importDraw(drawDraft(drawRows(22, [2])), contestId);
      final after = await importer.drawTarget(signedIn, 22, _fingerprint);
      expect(after.hasMatrix, isTrue);

      final none = await importer.drawTarget(signedIn, 99, _fingerprint);
      expect(none.stamped, isFalse);
      expect(
        (await importer.drawTarget(
          core.ImportOwner(signedInAccountId: core.Id.create()),
          22,
          _fingerprint,
        )).stamped,
        isFalse,
        reason: 'another director',
      );
    });

    test('the target prefers the stamp of the same file', () async {
      final older = await contestFor(fingerprint: 'sha256:older');
      final newer = await contestFor(fingerprint: 'sha256:newer');
      expect(
        (await importer.drawTarget(signedIn, 22, 'sha256:older')).contestId,
        older,
      );
      expect(
        (await importer.drawTarget(signedIn, 22, 'sha256:other')).contestId,
        newer,
        reason: 'else the newest',
      );
    });

    test('the draw lands in the contest of the same file only', () async {
      final older = await contestFor(fingerprint: 'sha256:older');
      final newer = await contestFor(fingerprint: 'sha256:newer');
      final target = await importer.drawTarget(signedIn, 22, 'sha256:older');
      expect(target.contestId, older);
      final result = await importer.importDraw(
        plan(
          drawDraft(drawRows(22, [2])),
          target.contestId!,
          fingerprint: 'sha256:older',
        ),
        metadata: metadata(),
      );
      expect(result, isA<core.DrawImported>());
      expect(
        (await importer.drawTarget(signedIn, 22, 'sha256:older')).hasMatrix,
        isTrue,
      );
      expect(
        (await importer.drawTarget(signedIn, 22, 'sha256:newer')).hasMatrix,
        isFalse,
        reason: 'the other contest of the competition is untouched',
      );
      expect(newer, isNot(older));
    });

    test('with no stamp of the same file the newest is offered and the '
        'transaction refuses it for the same reason', () async {
      await contestFor(fingerprint: 'sha256:older');
      final newer = await contestFor(fingerprint: 'sha256:newer');
      final target = await importer.drawTarget(signedIn, 22, 'sha256:other');
      expect(target.contestId, newer);
      expect(target.stampedFingerprint, 'sha256:newer');
      final result = await importer.importDraw(
        plan(drawDraft(drawRows(22, [2])), newer, fingerprint: 'sha256:other'),
        metadata: metadata(),
      );
      expect(result, isA<core.DrawImportFailed>());
      expect(
        (result as core.DrawImportFailed).code,
        core.DrawImportReason.fingerprintChanged,
      );
    });

    group('refuses', () {
      Future<void> expectUntouched(core.Id contestId) async {
        expect(await inst.count('matrix_revisions'), 0);
        expect(await inst.count('rounds'), 0);
        expect(await inst.count('matrix_assignments'), 0);
        expect(await inst.count('score_placeholders'), 0);
        final contest = (await repository.contestRepository.findById(
          contestId,
        ))!;
        expect(contest.lifecycleState, core.LifecycleState.configuring);
        expect(
          (await repository.importProvenanceRepository.listForContest(
            contestId,
          )).where((s) => s.stampedEntityType == 'MatrixRevision'),
          isEmpty,
        );
      }

      test('a contest that is not stamped by phase B', () async {
        await contestFor();
        final result = await importDraw(
          drawDraft(drawRows(22, [2])),
          core.Id.create(),
        );
        expect(
          (result as core.DrawImportFailed).code,
          core.DrawImportReason.notStamped,
        );
      });

      test('a contest of another comp number or director', () async {
        final contestId = await contestFor();
        final other = await importer.importDraw(
          plan(drawDraft(drawRows(23, [2]), compNo: 23), contestId),
          metadata: metadata(),
        );
        expect(
          (other as core.DrawImportFailed).code,
          core.DrawImportReason.notStamped,
        );
        final stranger = await importer.importDraw(
          plan(
            drawDraft(drawRows(22, [2])),
            contestId,
            who: core.ImportOwner(signedInAccountId: core.Id.create()),
          ),
          metadata: metadata(),
        );
        expect(
          (stranger as core.DrawImportFailed).code,
          core.DrawImportReason.notStamped,
        );
        await expectUntouched(contestId);
      });

      test('a file that differs from the stamp', () async {
        final contestId = await contestFor();
        final result = await importer.importDraw(
          plan(
            drawDraft(drawRows(22, [2]), fingerprint: 'sha256:other'),
            contestId,
            fingerprint: 'sha256:other',
          ),
          metadata: metadata(),
        );
        expect(
          (result as core.DrawImportFailed).code,
          core.DrawImportReason.fingerprintChanged,
        );
        await expectUntouched(contestId);
      });

      test('a contest that already has a matrix', () async {
        final contestId = await contestFor();
        await importDraw(drawDraft(drawRows(22, [2])), contestId);
        final revisions = await inst.count('matrix_revisions');
        final assignments = await inst.count('matrix_assignments');
        final again = await importDraw(drawDraft(drawRows(22, [2])), contestId);
        expect(
          (again as core.DrawImportFailed).code,
          core.DrawImportReason.alreadyDrawn,
        );
        expect(await inst.count('matrix_revisions'), revisions);
        expect(await inst.count('matrix_assignments'), assignments);
      });

      test('a locked contest', () async {
        final contestId = await contestFor();
        final contest = (await repository.contestRepository.findById(
          contestId,
        ))!;
        await repository.contestRepository.save(
          contest.copyWithState(
            adminLock: core.AdminLock.locked,
            updatedAt: DateTime.utc(2026, 11, 4),
          ),
          metadata: metadata(),
        );
        final result = await importDraw(
          drawDraft(drawRows(22, [2])),
          contestId,
        );
        expect(
          (result as core.DrawImportFailed).code,
          core.DrawImportFailure.contestLocked,
        );
      });

      test('a pilot with no participation', () async {
        final contestId = await contestFor();
        final rows = [
          ...drawRows(22, [2]),
          scoreRow(22, 1, 1, 7, 9),
        ];
        final result = await importDraw(
          drawDraft(rows, pilots: {1, 2, 3, 4, 5, 6, 7}),
          contestId,
        );
        final failed = result as core.DrawImportFailed;
        expect(failed.code, core.DrawImportFailure.participationMissing);
        expect(failed.detail, '7');
        await expectUntouched(contestId);
      });

      test('a refused draft and a missing account', () async {
        final contestId = await contestFor();
        final noAccount = await importer.importDraw(
          plan(
            drawDraft(drawRows(22, [2])),
            contestId,
            who: const core.ImportOwner(),
          ),
          metadata: metadata(),
        );
        expect(
          (noAccount as core.DrawImportFailed).code,
          core.DrawImportFailure.noAccount,
        );
        final bad = core.DrawImportDraft(
          sourceCompNo: 22,
          status: core.DrawImportStatus.refused,
          reason: core.DrawImportReason.creditMoved,
        );
        final notImportable = await importDraw(bad, contestId);
        expect(
          (notImportable as core.DrawImportFailed).code,
          core.DrawImportFailure.notImportable,
        );
        await expectUntouched(contestId);
      });
    });

    test('a failure part-way keeps nothing and the retry works', () async {
      final contestId = await contestFor();
      final failing = ContestImportRepository(
        inst.db,
        newId: _repeatingIds(core.Id.create(), after: 6),
      );
      final result = await failing.importDraw(
        plan(drawDraft(drawRows(22, [2, 2])), contestId),
        metadata: metadata(),
      );
      expect(result, isA<core.DrawImportFailed>());
      expect(await inst.count('matrix_revisions'), 0);
      expect(await inst.count('rounds'), 0);
      expect(await inst.count('matrix_assignments'), 0);
      expect(await inst.count('score_placeholders'), 0);
      expect(
        (await repository.contestRepository.findById(contestId))!
            .lifecycleState,
        core.LifecycleState.configuring,
      );
      expect(
        await repository.auditEventRepository.listForContest(
          contestId,
          action: core.AuditAction.restoration,
        ),
        isEmpty,
      );
      expect(
        await importDraw(drawDraft(drawRows(22, [2, 2])), contestId),
        isA<core.DrawImported>(),
      );
    });

    test('two runs at once leave exactly one draw', () async {
      final contestId = await contestFor();
      final results = await Future.wait([
        importDraw(drawDraft(drawRows(22, [2, 2])), contestId),
        importDraw(drawDraft(drawRows(22, [2, 2])), contestId),
      ]);
      expect(results.whereType<core.DrawImported>(), hasLength(1));
      expect(await inst.count('matrix_revisions'), 1);
      expect(await inst.count('rounds'), 2);
    });
  });
}

core.Id Function() _repeatingIds(core.Id same, {required int after}) {
  var calls = 0;
  return () => calls++ < after ? core.Id.create() : same;
}
