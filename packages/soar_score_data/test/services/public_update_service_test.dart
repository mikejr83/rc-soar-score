import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';
import '../support/matrix_slot.dart';

void main() => forEachBackend(_tests);

/// When a score entry reaches the public projection, by update mode, against
/// the real repositories.
void _tests(Backend backend) {
  group('PublicUpdateService', () {
    late Installation inst;
    late Repository repository;
    late ResultsService results;
    late PublicationService publishing;
    late PublicUpdateService updates;
    late core.Id contestId;
    late core.Id publicationId;
    late List<MatrixSlot> round1;
    late List<MatrixSlot> round2;
    final actor = core.Id.create();
    var now = DateTime.utc(2026, 10, 17, 15);
    var mutations = 0;

    setUp(() async {
      inst = await Installation.open(backend, profile: DatabaseProfile.server);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      now = DateTime.utc(2026, 10, 17, 15);
      results = ResultsService(repository, clock: () => now);
      publishing = PublicationService(repository, clock: () => now);
      updates = PublicUpdateService(
        repository,
        publication: publishing,
        clock: () => now,
      );
      await repository.accountRepository.save(
        core.Account(
          id: actor,
          firstName: 'Dana',
          lastName: 'Director',
          kind: core.AccountKind.registered,
          createdAt: now,
          updatedAt: now,
        ),
      );
      contestId = await drawnContest(repository, actor);
    });

    tearDown(() => inst.close());

    core.MutationMetadata metadata(String id) => core.MutationMetadata(
      clientMutationId: '$id-${mutations++}',
      authority: core.Authority.director,
      clientTime: now,
      actorId: actor,
    );

    Future<void> useMode(core.PublicUpdateMode mode) =>
        ContestConfigurationService(repository).save(
          contestId,
          ConfigurationInput(
            baseRevisionNumber: 1,
            disciplineProfileId: core.SystemDisciplineProfiles.f5jId,
            config: core.ContestConfig(
              core: {'public_update_mode': mode.json},
              discipline: const {'working_time': 600},
            ),
          ),
          createdBy: actor,
          metadata: metadata('mode'),
        );

    /// Draws the matrix slots and publishes the empty contest once.
    Future<void> publishFirst() async {
      final matrix = await MatrixService(repository).current(contestId);
      List<MatrixSlot> slotsOf(int ordinal) {
        final round = matrix.rounds.firstWhere((r) => r.ordinal == ordinal);
        return [
          for (final a in matrix.assignments)
            if (a.scheduledRoundId == round.id)
              MatrixSlot(a.id, a.contestParticipationId),
        ];
      }

      round1 = slotsOf(1);
      round2 = slotsOf(2);
      final revision = (await repository.contestRepository.findById(
        contestId,
      ))!;
      final result = await publishing.publish(
        contestId,
        actorId: actor,
        authority: core.Authority.director,
        clientMutationId: 'first',
        sourceContestRevision: revision.revision,
      );
      publicationId = result.view.identity.id;
    }

    /// Enters a score, recalculates like the handler, and runs the update.
    Future<PublishResult?> enter(
      MatrixSlot slot,
      int seconds, {
      int base = 0,
      bool recalculate = true,
      String? mutation,
    }) async {
      final id = mutation ?? 'entry-${mutations++}';
      await ScoresService(repository, clock: () => now).enterOfficialScore(
        contestId,
        slot.assignmentId,
        clientMutationId: id,
        baseScoreRevision: base,
        components: {
          'time_flown': seconds,
          'launch_height': 200,
          'landing': 'points_50',
        },
        reason: base == 0 ? null : 'Timer misread',
        actorId: actor,
        metadata: metadata('meta'),
      );
      if (recalculate) await results.recalculate(contestId);
      now = now.add(const Duration(minutes: 1));
      return updates.afterScoreEntry(
        contestId,
        assignmentId: slot.assignmentId,
        entryMutationId: id,
      );
    }

    Future<List<core.PublicationProjection>> projections() => repository
        .publicationProjectionRepository
        .listForPublication(publicationId);

    test('a contest that was never published is never published', () async {
      final slots = await _firstRound(repository, contestId);

      final published = await enter(slots.first, 500);

      expect(published, isNull);
      expect(
        await repository.publicationIdentityRepository.findForContest(
          contestId,
        ),
        isNull,
      );
    });

    test('completing a published contest publishes it again, once', () async {
      await publishFirst();

      final first = await updates.afterCompletion(contestId, revision: 7);
      final again = await updates.afterCompletion(contestId, revision: 7);

      expect(first!.created, isTrue);
      expect(first.view.current!.projectionRevision, 2);
      expect(again!.created, isFalse);
      expect(await projections(), hasLength(2));
    });

    test(
      'completing publishes nothing in Manual or when never published',
      () async {
        expect(await updates.afterCompletion(contestId, revision: 7), isNull);

        await useMode(core.PublicUpdateMode.manual);
        await publishFirst();

        expect(await updates.afterCompletion(contestId, revision: 7), isNull);
        expect(await projections(), hasLength(1));
      },
    );

    test('Manual never publishes after an entry', () async {
      await useMode(core.PublicUpdateMode.manual);
      await publishFirst();

      for (final slot in round1) {
        expect(await enter(slot, 500), isNull);
      }

      expect(await projections(), hasLength(1));
    });

    test('Automatic publishes after every entry', () async {
      await useMode(core.PublicUpdateMode.automatic);
      await publishFirst();

      for (var i = 0; i < round1.length; i++) {
        final published = await enter(round1[i], 500 + i);
        expect(published!.created, isTrue);
        expect(published.view.current!.projectionRevision, i + 2);
        expect(published.view.current!.scores, hasLength(i + 1));
      }

      expect(await projections(), hasLength(5));
    });

    test('RoundCompletion publishes when a round has all its scores', () async {
      await publishFirst();

      for (var i = 0; i < round1.length - 1; i++) {
        expect(await enter(round1[i], 500 + i), isNull);
      }
      expect(await projections(), hasLength(1));

      final completed = await enter(round1.last, 590);
      expect(completed!.view.current!.projectionRevision, 2);
      expect(completed.view.current!.scores, hasLength(4));

      expect(await enter(round2.first, 500), isNull);
      expect(await projections(), hasLength(2));

      final corrected = await enter(round1.first, 595, base: 1);
      expect(corrected!.view.current!.projectionRevision, 3);
    });

    test('a retried entry publishes once', () async {
      await useMode(core.PublicUpdateMode.automatic);
      await publishFirst();
      final first = await enter(round1.first, 500, mutation: 'same');

      final again = await updates.afterScoreEntry(
        contestId,
        assignmentId: round1.first.assignmentId,
        entryMutationId: 'same',
      );

      expect(again!.created, isFalse);
      expect(again.view.current!.id, first!.view.current!.id);
      expect(await projections(), hasLength(2));
    });

    test(
      'a refused automatic publish is audited and changes nothing',
      () async {
        await useMode(core.PublicUpdateMode.automatic);
        await publishFirst();

        await expectLater(
          enter(round1.first, 500, recalculate: false),
          throwsA(
            isA<core.ContestStateError>().having(
              (e) => e.code,
              'code',
              'results_stale',
            ),
          ),
        );

        expect(await projections(), hasLength(1));
        final identity = await repository.publicationIdentityRepository
            .findById(publicationId);
        expect(identity!.currentProjectionId, (await projections()).single.id);
        final events = await repository.auditEventRepository.listForPublication(
          publicationId,
        );
        expect(events.last.outcome, core.AuditOutcome.rejected);
        expect(events.last.reason, 'results_stale');
        expect(events.last.authority, core.Authority.system);
        expect(events.last.actorId, isNull);
        // The score itself was kept.
        final scores = await ScoresService(repository).list(contestId);
        expect(
          scores.slots.where((s) => s.officialScore != null),
          hasLength(1),
        );
      },
    );

    test('an unexpected failure is audited as publish_failed', () async {
      await publishFirst();
      final failing = PublicUpdateService(
        repository,
        publication: _FailingPublication(repository),
        clock: () => now,
      );
      for (var i = 0; i < round1.length; i++) {
        await ScoresService(repository, clock: () => now).enterOfficialScore(
          contestId,
          round1[i].assignmentId,
          clientMutationId: 'e-$i',
          baseScoreRevision: 0,
          components: {
            'time_flown': 500 + i,
            'launch_height': 200,
            'landing': 'points_50',
          },
          actorId: actor,
          metadata: metadata('m'),
        );
      }
      await results.recalculate(contestId);

      await expectLater(
        failing.afterScoreEntry(
          contestId,
          assignmentId: round1.last.assignmentId,
          entryMutationId: 'e-3',
        ),
        throwsA(isA<StateError>()),
      );

      final events = await repository.auditEventRepository.listForPublication(
        publicationId,
      );
      expect(events.last.reason, 'publish_failed');
      expect(events.last.outcome, core.AuditOutcome.rejected);
      expect(await projections(), hasLength(1));
    });

    test('a delisted publication is left alone', () async {
      await useMode(core.PublicUpdateMode.automatic);
      await publishFirst();
      final identity = (await repository.publicationIdentityRepository.findById(
        publicationId,
      ))!;
      await repository.publicationIdentityRepository.save(
        core.PublicationIdentity(
          id: identity.id,
          contestId: identity.contestId,
          ownerPublicProfileId: identity.ownerPublicProfileId,
          claimStatus: identity.claimStatus,
          visibility: core.PublicationVisibility.delisted,
          publishedAt: identity.publishedAt,
          currentProjectionId: identity.currentProjectionId,
          revision: identity.revision,
        ),
      );

      expect(await enter(round1.first, 500), isNull);
      expect(await projections(), hasLength(1));
    });
  });
}

Future<List<MatrixSlot>> _firstRound(
  Repository repository,
  core.Id contestId,
) async {
  final matrix = await MatrixService(repository).current(contestId);
  final first = matrix.rounds.firstWhere((round) => round.ordinal == 1);
  return [
    for (final a in matrix.assignments)
      if (a.scheduledRoundId == first.id)
        MatrixSlot(a.id, a.contestParticipationId),
  ];
}

/// A publication service whose automatic publish fails the way a database
/// error would.
class _FailingPublication extends PublicationService {
  _FailingPublication(super.repository);

  @override
  Future<PublishResult?> publishAutomatically(
    core.Id contestId, {
    required String clientMutationId,
  }) => throw StateError('the database went away');
}
