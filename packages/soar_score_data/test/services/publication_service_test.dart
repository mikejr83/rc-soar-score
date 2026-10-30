import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';
import '../support/matrix_slot.dart';

void main() => forEachBackend(_tests);

/// The publication service against the real repositories: who may publish,
/// what a publish stores, and what a refused one leaves behind.
void _tests(Backend backend) {
  group('PublicationService', () {
    late Installation inst;
    late Repository repository;
    late ResultsService results;
    late PublicationService service;
    late core.Id contestId;
    late List<MatrixSlot> firstRound;
    final actor = core.Id.create();
    var now = DateTime.utc(2026, 10, 17, 15);

    setUp(() async {
      inst = await Installation.open(backend, profile: DatabaseProfile.server);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      now = DateTime.utc(2026, 10, 17, 15);
      results = ResultsService(repository, clock: () => now);
      service = PublicationService(repository, clock: () => now);
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
      final matrix = await MatrixService(repository).current(contestId);
      final first = matrix.rounds.firstWhere((round) => round.ordinal == 1);
      firstRound = [
        for (final assignment in matrix.assignments)
          if (assignment.scheduledRoundId == first.id)
            MatrixSlot(assignment.id, assignment.contestParticipationId),
      ];
    });

    tearDown(() => inst.close());

    var mutations = 0;
    Future<void> enter(MatrixSlot slot, int seconds, {int base = 0}) =>
        ScoresService(repository, clock: () => now).enterOfficialScore(
          contestId,
          slot.assignmentId,
          clientMutationId: 'entry-${mutations++}',
          baseScoreRevision: base,
          components: {
            'time_flown': seconds,
            'launch_height': 200,
            'landing': 'points_50',
          },
          reason: base == 0 ? null : 'Timer misread',
          actorId: actor,
          metadata: core.MutationMetadata(
            clientMutationId: 'meta-${mutations++}',
            authority: core.Authority.director,
            clientTime: now,
            actorId: actor,
          ),
        );

    Future<void> scoreAndCalculate() async {
      const times = [500, 540, 580, 590];
      for (var i = 0; i < firstRound.length; i++) {
        await enter(firstRound[i], times[i]);
      }
      await results.recalculate(contestId);
    }

    Future<int> contestRevision() async =>
        (await repository.contestRepository.findById(contestId))!.revision;

    Future<PublishResult> publish({
      String id = 'p-1',
      int? revision,
      core.Id? as,
      core.Authority authority = core.Authority.director,
    }) async => service.publish(
      contestId,
      actorId: as ?? actor,
      authority: authority,
      clientMutationId: id,
      sourceContestRevision: revision ?? await contestRevision(),
    );

    Future<List<core.AuditEvent>> attempts(core.Id publicationId) =>
        repository.auditEventRepository.listForPublication(publicationId);

    test(
      'a director publishes: Unlisted, claimed, matching the results',
      () async {
        await scoreAndCalculate();

        final result = await publish();

        expect(result.created, isTrue);
        final identity = result.view.identity;
        expect(identity.visibility, core.PublicationVisibility.unlisted);
        expect(identity.claimStatus, core.ClaimStatus.claimed);
        expect(identity.contestId, contestId);
        expect(identity.publishedAt, now);
        final projection = result.view.current!;
        expect(identity.currentProjectionId, projection.id);
        expect(projection.projectionRevision, 1);
        expect(projection.scores, hasLength(4));
        final profile = await repository.accountPublicProfileRepository
            .findForAccount(actor);
        expect(profile!.displayName, 'Dana Director');
        expect(identity.ownerPublicProfileId, profile.id);
        expect(
          await repository.publicationParticipantRepository.listForPublication(
            identity.id,
          ),
          hasLength(4),
        );
        final events = await attempts(identity.id);
        expect(events, hasLength(1));
        expect(events.single.outcome, core.AuditOutcome.success);
        expect(events.single.action, core.AuditAction.publicationAttempt);
        expect(events.single.actorId, actor);
      },
    );

    test('repeating a request returns the first projection', () async {
      await scoreAndCalculate();
      final first = await publish();

      final again = await publish();

      expect(again.created, isFalse);
      expect(again.view.current!.id, first.view.current!.id);
      expect(
        await repository.publicationProjectionRepository.listForPublication(
          first.view.identity.id,
        ),
        hasLength(1),
      );
      expect(await attempts(first.view.identity.id), hasLength(1));
    });

    test(
      'a later publish adds the next revision to the same publication',
      () async {
        await scoreAndCalculate();
        final first = await publish();
        now = now.add(const Duration(hours: 1));

        final second = await publish(id: 'p-2');

        expect(second.created, isTrue);
        expect(second.view.identity.id, first.view.identity.id);
        expect(second.view.current!.projectionRevision, 2);
        expect(
          second.view.identity.currentProjectionId,
          second.view.current!.id,
        );
        expect(
          second.view.identity.publishedAt,
          first.view.identity.publishedAt,
        );
        expect(
          {
            for (final p in second.view.current!.participants!)
              (p! as Map)['pilot_key'],
          },
          {
            for (final p in first.view.current!.participants!)
              (p! as Map)['pilot_key'],
          },
        );
        expect(await attempts(first.view.identity.id), hasLength(2));
      },
    );

    test(
      'a stale source revision is refused, audited and stores nothing',
      () async {
        await scoreAndCalculate();
        final revision = await contestRevision();

        await expectLater(
          publish(revision: revision + 1),
          throwsA(
            isA<core.ContestStateError>().having(
              (e) => e.code,
              'code',
              'stale_source_revision',
            ),
          ),
        );

        expect(
          await repository.publicationIdentityRepository.findForContest(
            contestId,
          ),
          isNull,
        );
        final event = (await repository.auditEventRepository.findById(
          (await _eventIds(inst)).single,
        ))!;
        expect(event.outcome, core.AuditOutcome.rejected);
        expect(event.reason, 'stale_source_revision');
        expect(event.contestId, contestId);
        expect(event.baseRevision, revision + 1);
      },
    );

    test('someone else cannot publish, and the attempt is audited', () async {
      await scoreAndCalculate();
      final stranger = core.Id.create();

      await expectLater(
        publish(as: stranger),
        throwsA(isA<core.ForbiddenError>()),
      );
      await expectLater(
        publish(authority: core.Authority.helper),
        throwsA(isA<core.ForbiddenError>()),
      );

      expect(
        await repository.publicationIdentityRepository.findForContest(
          contestId,
        ),
        isNull,
      );
      final ids = await _eventIds(inst);
      expect(ids, hasLength(2));
      for (final id in ids) {
        final event = (await repository.auditEventRepository.findById(id))!;
        expect(event.outcome, core.AuditOutcome.rejected);
        expect(event.reason, 'not_director');
      }
    });

    test(
      'stale results are refused and audited on a published contest',
      () async {
        await scoreAndCalculate();
        final first = await publish();
        now = now.add(const Duration(minutes: 5));
        await enter(firstRound[0], 595, base: 1);

        await expectLater(
          publish(id: 'p-2'),
          throwsA(
            isA<core.ContestStateError>().having(
              (e) => e.code,
              'code',
              'results_stale',
            ),
          ),
        );

        expect(
          await repository.publicationProjectionRepository.listForPublication(
            first.view.identity.id,
          ),
          hasLength(1),
        );
        final events = await attempts(first.view.identity.id);
        expect(events.map((e) => e.outcome), [
          core.AuditOutcome.success,
          core.AuditOutcome.rejected,
        ]);
      },
    );

    test('visibility moves between Unlisted and Public only', () async {
      await scoreAndCalculate();
      final published = await publish();
      final revision = await contestRevision();

      final shown = await service.setVisibility(
        contestId,
        core.PublicationVisibility.public,
        actorId: actor,
        authority: core.Authority.director,
      );
      final hidden = await service.setVisibility(
        contestId,
        core.PublicationVisibility.unlisted,
        actorId: actor,
        authority: core.Authority.director,
      );

      expect(shown.identity.visibility, core.PublicationVisibility.public);
      expect(hidden.identity.visibility, core.PublicationVisibility.unlisted);
      expect(hidden.current, published.view.current);
      expect(await contestRevision(), revision);
      await expectLater(
        service.setVisibility(
          contestId,
          core.PublicationVisibility.delisted,
          actorId: actor,
          authority: core.Authority.director,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test(
      'a delisted publication can be neither changed nor republished',
      () async {
        await scoreAndCalculate();
        final published = await publish();
        final identity = published.view.identity;
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

        for (final action in [
          () => service.setVisibility(
            contestId,
            core.PublicationVisibility.public,
            actorId: actor,
            authority: core.Authority.director,
          ),
          () => publish(id: 'p-2'),
        ]) {
          await expectLater(
            action(),
            throwsA(
              isA<core.ContestStateError>().having(
                (e) => e.code,
                'code',
                'publication_delisted',
              ),
            ),
          );
        }
      },
    );

    test('the director reads the publication; others cannot', () async {
      await expectLater(
        service.read(
          contestId,
          actorId: actor,
          authority: core.Authority.director,
        ),
        throwsA(isA<core.EntityNotFoundError>()),
      );
      await scoreAndCalculate();
      final published = await publish();

      final view = await service.read(
        contestId,
        actorId: actor,
        authority: core.Authority.director,
      );

      expect(view, published.view);
      await expectLater(
        service.read(
          contestId,
          actorId: core.Id.create(),
          authority: core.Authority.director,
        ),
        throwsA(isA<core.ForbiddenError>()),
      );
    });

    test('a failed write leaves no part of the publish behind', () async {
      await scoreAndCalculate();
      final built = await PublicationProjectionBuilder(repository).build(
        contestId: contestId,
        publicationId: core.Id.create(),
        projectionRevision: 1,
        clientMutationId: 'x',
      );
      final identity = core.PublicationIdentity(
        id: built.projection.publicationId,
        contestId: contestId,
        verificationEmail: 'a@example.com',
        currentProjectionId: built.projection.id,
      );
      final event = core.AuditEvent(
        id: core.Id.create(),
        entityType: 'PublicationIdentity',
        entityId: identity.id,
        publicationId: identity.id,
        action: core.AuditAction.publicationAttempt,
        authority: core.Authority.director,
        serverTimestamp: now,
      );
      await repository.auditEventRepository.append(event);

      await expectLater(
        repository.publicationPublisher.publish(
          identity: identity,
          participants: built.participants,
          projection: built.projection,
          attempt: event,
        ),
        throwsA(isA<core.AlreadyStoredError>()),
      );

      expect(
        await repository.publicationIdentityRepository.findById(identity.id),
        isNull,
      );
      expect(
        await repository.publicationProjectionRepository.findById(
          built.projection.id,
        ),
        isNull,
      );
      expect(
        await repository.publicationParticipantRepository.listForPublication(
          identity.id,
        ),
        isEmpty,
      );
    });
  });
}

/// The ids of the publication-attempt audit events, excluding the
/// configuration-save and matrix-draw events the fixture leaves behind.
Future<List<core.Id>> _eventIds(Installation inst) async {
  final rows = await inst.db
      .customSelect(
        "SELECT id FROM audit_events WHERE action = 'PublicationAttempt'",
      )
      .get();
  return [for (final row in rows) core.Id.parse(row.read<String>('id'))];
}
