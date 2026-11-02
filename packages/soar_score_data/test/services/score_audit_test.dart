import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

/// A score correction and a change of retirement each leave one audit event,
/// stored with the change; a first entry leaves none.
void _tests(Backend backend) {
  group('score correction and retirement audit events', () {
    late Installation inst;
    late Repository repository;
    late ScoresService scores;
    late core.Id contestId;
    late core.Id slot;
    late core.Id participationId;
    final actor = core.Id.create();
    var mutations = 0;

    core.MutationMetadata meta() => core.MutationMetadata(
      clientMutationId: 'audit-${mutations++}',
      authority: core.Authority.director,
      clientTime: DateTime.utc(2026, 10, 17, 15),
      actorId: actor,
    );

    Future<ScoreEntryResult> enter({
      required int base,
      required String mutation,
      int landing = 50,
      String? reason,
    }) => scores.enterOfficialScore(
      contestId,
      slot,
      clientMutationId: mutation,
      baseScoreRevision: base,
      components: {
        'time_flown': 540,
        'launch_height': 200,
        'landing': 'points_$landing',
      },
      reason: reason,
      actorId: actor,
      metadata: meta(),
    );

    Future<List<core.AuditEvent>> events(core.AuditAction action) => repository
        .auditEventRepository
        .listForContest(contestId, action: action);

    setUp(() async {
      inst = await Installation.open(backend);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      scores = ScoresService(repository);
      contestId = await drawnContest(repository, actor);
      final matrix = await MatrixService(repository).current(contestId);
      final first = matrix.rounds.firstWhere((round) => round.ordinal == 1);
      final assignment = matrix.assignments.firstWhere(
        (a) => a.scheduledRoundId == first.id,
      );
      slot = assignment.id;
      participationId = assignment.contestParticipationId;
    });

    tearDown(() => inst.close());

    test('a first entry leaves no event', () async {
      await enter(base: 0, mutation: 'first');

      expect(await events(core.AuditAction.scoreAttempt), isEmpty);
    });

    test('a correction leaves one event naming pilot, round and score', () async {
      final first = await enter(base: 0, mutation: 'first');
      final corrected = await enter(
        base: 1,
        mutation: 'fix',
        landing: 30,
        reason: 'Landing misread',
      );

      final logged = await events(core.AuditAction.scoreAttempt);
      expect(logged, hasLength(1));
      final event = logged.single;
      final participation = (await repository.contestParticipationRepository
          .findById(participationId))!;
      expect(event.entityType, 'ScoreAttempt');
      expect(event.actorId, actor);
      expect(event.baseRevision, 1);
      expect(event.resultingRevision, 2);
      expect(
        event.reason,
        'correction: pilot ${participation.participantNumber}; round 1; '
        'group ${(await repository.matrixAssignmentRepository.findById(slot))!.group}; '
        'points ${first.calculated.rawScore.toStringAsFixed(1)} → '
        '${corrected.calculated.rawScore.toStringAsFixed(1)}; '
        'reason: Landing misread',
      );
      final ref = ScoreCorrectionAudit.parse(event)!;
      expect(ref.round, 1);
      expect(ref.pilot, participation.participantNumber);
    });

    test('a refused correction leaves no event', () async {
      await enter(base: 0, mutation: 'first');

      await expectLater(
        enter(base: 0, mutation: 'stale', reason: 'late'),
        throwsA(isA<core.StaleRevisionError>()),
      );
      await expectLater(
        enter(base: 1, mutation: 'noreason'),
        throwsA(isA<ArgumentError>()),
      );

      expect(await events(core.AuditAction.scoreAttempt), isEmpty);
    });

    test(
      'a retirement, a move and a reinstatement leave one event each',
      () async {
        final service = ParticipationsService(repository);
        final owner = core.Id.create();
        var participation = (await repository.contestParticipationRepository
            .findById(participationId))!;

        Future<void> retire(int? round) async {
          final change = await service.update(
            contestId,
            owner,
            participationId,
            retiredAtRound: round,
            baseRevision: participation.revision,
            metadata: meta(),
          );
          participation = change.participation;
        }

        await retire(2);
        await retire(2); // no change, no event
        await retire(1);
        await retire(null);

        final logged = [
          for (final event in await events(core.AuditAction.stateTransition))
            if (PilotRetirementAudit.parse(event) != null) event,
        ].reversed.toList();
        final number = participation.participantNumber;
        expect(
          [for (final e in logged) e.reason],
          [
            'retire: pilot $number; from round 2',
            'retire: pilot $number; from round 2 → 1',
            'reinstate: pilot $number; was retired from round 1',
          ],
        );
        expect(logged.first.entityType, 'ContestParticipation');
        expect(logged.first.entityId, participationId);
        expect(logged.first.actorId, actor);
        final kinds = [
          for (final e in logged) PilotRetirementAudit.parse(e)!.kind,
        ];
        expect(kinds, [
          PilotRetirementKind.retire,
          PilotRetirementKind.retire,
          PilotRetirementKind.reinstate,
        ]);
        // Contest actions are not mistaken for retirements.
        expect(ContestTransitionAudit.actionOf(logged.first), isNull);
      },
    );
  });
}
