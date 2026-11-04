import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';
import '../support/matrix_slot.dart';

void main() => forEachBackend(_tests);

/// The director's delist requests and the projection history against the
/// real repositories.
void _tests(Backend backend) {
  group('DelistRequestService', () {
    late Installation inst;
    late Repository repository;
    late PublicationService publications;
    late DelistRequestService service;
    late core.Id contestId;
    final actor = core.Id.create();
    final stranger = core.Id.create();
    var now = DateTime.utc(2026, 11, 3, 12);

    setUp(() async {
      inst = await Installation.open(backend, profile: DatabaseProfile.server);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      now = DateTime.utc(2026, 11, 3, 12);
      publications = PublicationService(repository, clock: () => now);
      service = DelistRequestService(repository, clock: () => now);
      for (final (id, last) in [(actor, 'Director'), (stranger, 'Other')]) {
        await repository.accountRepository.save(
          core.Account(
            id: id,
            firstName: 'Dana',
            lastName: last,
            kind: core.AccountKind.registered,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      contestId = await drawnContest(repository, actor);
      final matrix = await MatrixService(repository).current(contestId);
      final first = matrix.rounds.firstWhere((round) => round.ordinal == 1);
      final slots = [
        for (final a in matrix.assignments)
          if (a.scheduledRoundId == first.id)
            MatrixSlot(a.id, a.contestParticipationId),
      ];
      var n = 0;
      for (final (i, slot) in slots.indexed) {
        await ScoresService(repository, clock: () => now).enterOfficialScore(
          contestId,
          slot.assignmentId,
          clientMutationId: 'entry-${n++}',
          baseScoreRevision: 0,
          components: {
            'time_flown': 500 + i * 30,
            'launch_height': 200,
            'landing': 'points_50',
          },
          actorId: actor,
          metadata: core.MutationMetadata(
            clientMutationId: 'meta-${n++}',
            authority: core.Authority.director,
            clientTime: now,
            actorId: actor,
          ),
        );
      }
      await ResultsService(repository, clock: () => now).recalculate(contestId);
    });

    tearDown(() => inst.close());

    Future<core.PublicationIdentity> publish([String id = 'p-1']) async {
      final revision = (await repository.contestRepository.findById(contestId))!
          .revision;
      final result = await publications.publish(
        contestId,
        actorId: actor,
        authority: core.Authority.director,
        clientMutationId: id,
        sourceContestRevision: revision,
      );
      return result.view.identity;
    }

    Future<DelistRequestResult> request({String? reason}) => service.request(
      contestId,
      actorId: actor,
      authority: core.Authority.director,
      reason: reason,
    );

    test(
      'a director requests delisting, audited, and nothing else changes',
      () async {
        final identity = await publish();

        final result = await request(reason: '  Wrong contest  ');

        expect(result.created, isTrue);
        expect(result.request.state, core.DelistState.pending);
        expect(result.request.trigger, core.DelistTrigger.ownerRequest);
        expect(result.request.reason, 'Wrong contest');
        expect(result.request.requestedBy, actor);
        expect(result.request.publicationId, identity.id);
        final events = await repository.auditEventRepository.listForPublication(
          identity.id,
        );
        expect(
          events.where((e) => e.action == core.AuditAction.delistRequested),
          hasLength(1),
        );
        final stored = await repository.publicationIdentityRepository
            .findForContest(contestId);
        expect(stored!.visibility, identity.visibility);
      },
    );

    test('repeating while pending returns the same request, once', () async {
      final identity = await publish();
      final first = await request();

      final again = await request(reason: 'ignored');

      expect(again.created, isFalse);
      expect(again.request.id, first.request.id);
      expect(
        await repository.delistRequestRepository.listForPublication(
          identity.id,
        ),
        hasLength(1),
      );
      final events = await repository.auditEventRepository.listForPublication(
        identity.id,
      );
      expect(
        events.where((e) => e.action == core.AuditAction.delistRequested),
        hasLength(1),
      );
    });

    test('the director reads the latest request; none is a 404', () async {
      await publish();
      await expectLater(
        service.current(
          contestId,
          actorId: actor,
          authority: core.Authority.director,
        ),
        throwsA(isA<core.EntityNotFoundError>()),
      );
      final made = await request();

      final read = await service.current(
        contestId,
        actorId: actor,
        authority: core.Authority.director,
      );

      expect(read.id, made.request.id);
    });

    test(
      'withdrawing ends the request, audits it, and allows a new one',
      () async {
        final identity = await publish();
        final made = await request();

        final withdrawn = await service.withdraw(
          contestId,
          actorId: actor,
          authority: core.Authority.director,
        );

        expect(withdrawn.id, made.request.id);
        expect(withdrawn.state, core.DelistState.withdrawn);
        final events = await repository.auditEventRepository.listForPublication(
          identity.id,
        );
        expect(
          events.where((e) => e.action == core.AuditAction.delistWithdrawn),
          hasLength(1),
        );
        await expectLater(
          service.withdraw(
            contestId,
            actorId: actor,
            authority: core.Authority.director,
          ),
          throwsA(isA<core.EntityNotFoundError>()),
        );
        final next = await request();
        expect(next.created, isTrue);
        expect(next.request.id, isNot(made.request.id));
      },
    );

    test('anyone but the director is refused', () async {
      await publish();
      await request();
      for (final call in <Future<Object?> Function()>[
        () => service.request(
          contestId,
          actorId: stranger,
          authority: core.Authority.director,
        ),
        () => service.current(
          contestId,
          actorId: stranger,
          authority: core.Authority.director,
        ),
        () => service.withdraw(
          contestId,
          actorId: stranger,
          authority: core.Authority.director,
        ),
        () => service.withdraw(
          contestId,
          actorId: actor,
          authority: core.Authority.participant,
        ),
      ]) {
        await expectLater(call(), throwsA(isA<core.ForbiddenError>()));
      }
    });

    test('an unpublished contest is a 404', () async {
      await expectLater(request(), throwsA(isA<core.EntityNotFoundError>()));
    });

    test('a delisted publication cannot be asked for again', () async {
      final identity = await publish();
      await repository.publicationIdentityRepository.save(
        identity.withVisibility(core.PublicationVisibility.delisted),
      );

      await expectLater(
        request(),
        throwsA(
          isA<core.ContestStateError>().having(
            (e) => e.code,
            'code',
            'publication_delisted',
          ),
        ),
      );
    });

    test('history lists every projection, newest first, and pages', () async {
      await publish();
      now = now.add(const Duration(hours: 1));
      await publish('p-2');
      now = now.add(const Duration(hours: 1));
      await publish('p-3');

      final all = await publications.history(
        contestId,
        actorId: actor,
        authority: core.Authority.director,
      );
      final page = await publications.history(
        contestId,
        actorId: actor,
        authority: core.Authority.director,
        limit: 1,
        offset: 1,
      );

      expect(all.map((e) => e.projection.projectionRevision), [3, 2, 1]);
      expect(page.map((e) => e.projection.projectionRevision), [2]);
      await expectLater(
        publications.history(
          contestId,
          actorId: stranger,
          authority: core.Authority.director,
        ),
        throwsA(isA<core.ForbiddenError>()),
      );
    });

    test('two requests at once store one request and one event', () async {
      final identity = await publish();

      final results = await Future.wait([request(), request()]);

      expect(results.map((r) => r.created), unorderedEquals([true, false]));
      expect(results[0].request.id, results[1].request.id);
      expect(
        await repository.delistRequestRepository.listForPublication(
          identity.id,
        ),
        hasLength(1),
      );
      final events = await repository.auditEventRepository.listForPublication(
        identity.id,
      );
      expect(
        events.where((e) => e.action == core.AuditAction.delistRequested),
        hasLength(1),
      );
    });

    core.AuditEvent auditFor(
      core.DelistRequest request,
      core.AuditAction action, {
      core.Id? id,
    }) => core.AuditEvent(
      id: id ?? core.Id.create(),
      entityType: 'DelistRequest',
      entityId: request.id,
      publicationId: request.publicationId,
      action: action,
      actorId: actor,
      authority: core.Authority.director,
      serverTimestamp: now,
    );

    test('a failed audit write leaves no request behind', () async {
      final identity = await publish();
      final draft = core.DelistRequest(
        id: core.Id.create(),
        publicationId: identity.id,
        requestedBy: actor,
        trigger: core.DelistTrigger.ownerRequest,
        requestedAt: now,
      );
      final taken = auditFor(draft, core.AuditAction.delistRequested);
      await repository.auditEventRepository.append(taken);

      await expectLater(
        repository.delistRequestRepository.createPending(draft, taken),
        throwsA(isA<core.AlreadyStoredError>()),
      );

      expect(
        await repository.delistRequestRepository.listForPublication(
          identity.id,
        ),
        isEmpty,
      );
    });

    test('a failed audit write leaves the request pending', () async {
      await publish();
      final pending = (await request()).request;
      final taken = auditFor(pending, core.AuditAction.delistWithdrawn);
      await repository.auditEventRepository.append(taken);
      final withdrawn = core.DelistRequest(
        id: pending.id,
        publicationId: pending.publicationId,
        requestedBy: pending.requestedBy,
        trigger: pending.trigger,
        requestedAt: pending.requestedAt,
        state: core.DelistState.withdrawn,
      );

      await expectLater(
        repository.delistRequestRepository.saveWithAudit(withdrawn, taken),
        throwsA(isA<core.AlreadyStoredError>()),
      );

      expect(
        (await repository.delistRequestRepository.findById(pending.id))!.state,
        core.DelistState.pending,
      );
    });

    test('the latest request is the newest of several', () async {
      final identity = await publish();
      expect(
        await repository.delistRequestRepository.findLatestForPublication(
          identity.id,
        ),
        isNull,
      );
      await request();
      await service.withdraw(
        contestId,
        actorId: actor,
        authority: core.Authority.director,
      );
      final second = (await request()).request;
      await service.withdraw(
        contestId,
        actorId: actor,
        authority: core.Authority.director,
      );
      final third = (await request()).request;

      final latest = await repository.delistRequestRepository
          .findLatestForPublication(identity.id);

      expect(latest!.id, third.id);
      expect(latest.id, isNot(second.id));
      expect(latest.state, core.DelistState.pending);
    });

    test('history says who published each projection', () async {
      await publish();
      now = now.add(const Duration(hours: 1));
      await publications.publishAutomatically(
        contestId,
        clientMutationId: 'auto-1',
      );

      final entries = await publications.history(
        contestId,
        actorId: actor,
        authority: core.Authority.director,
      );

      expect(entries.map((e) => e.projection.projectionRevision), [2, 1]);
      expect(entries.map((e) => e.bySystem), [true, false]);
      // An automatic publish still records the owner as publisher.
      expect(entries.first.projection.publishedBy, actor);
      expect(entries.last.projection.publishedBy, actor);
    });

    test('history of an unpublished contest is a 404', () async {
      await expectLater(
        publications.history(
          contestId,
          actorId: actor,
          authority: core.Authority.director,
        ),
        throwsA(isA<core.EntityNotFoundError>()),
      );
    });
  });
}
