import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

/// The score service against the real repositories, so the one-transaction
/// entry, the revision checks and the stored history are the real ones.
void _tests(Backend backend) {
  group('ScoresService', () {
    late Installation inst;
    late Repository repository;
    late ScoresService service;
    late core.Id contestId;
    late List<core.Id> slots;
    late int slotCount;
    final actor = core.Id.create();

    setUp(() async {
      inst = await Installation.open(backend);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      service = ScoresService(repository);
      contestId = await drawnContest(repository, actor);
      final matrix = await MatrixService(repository).current(contestId);
      slotCount = matrix.assignments.length;
      final first = matrix.rounds.firstWhere((round) => round.ordinal == 1);
      slots = [
        for (final assignment in matrix.assignments)
          if (assignment.scheduledRoundId == first.id) assignment.id,
      ];
    });

    tearDown(() => inst.close());

    var mutations = 0;
    core.MutationMetadata meta() => core.MutationMetadata(
      clientMutationId: 'request-${mutations++}',
      authority: core.Authority.director,
      clientTime: DateTime.utc(2026, 10, 8),
      actorId: actor,
    );

    Future<ScoreEntryResult> enter(
      core.Id assignmentId, {
      int base = 0,
      String mutation = 'entry-1',
      Map<String, Object?> components = const {
        'time_flown': 540,
        'launch_height': 200,
        'landing': 'points_50',
      },
      String? reason,
    }) => service.enterOfficialScore(
      contestId,
      assignmentId,
      clientMutationId: mutation,
      baseScoreRevision: base,
      components: components,
      reason: reason,
      actorId: actor,
      metadata: meta(),
    );

    test('the first score is stored whole and starts the contest', () async {
      final slot = slots.first;

      final result = await enter(slot);

      expect(result.officialScore.scoreRevision, 1);
      expect(result.placeholder.state, core.ScorePlaceholderState.official);
      expect(result.placeholder.scoreRevision, 1);
      expect(result.calculated.rawScore, 490);
      expect(result.contest.lifecycleState, core.LifecycleState.running);
      expect(
        (await repository.contestRepository.findById(contestId))!
            .lifecycleState,
        core.LifecycleState.running,
      );
      final attempt = await repository.scoreAttemptRepository
          .findByClientMutationId(contestId, 'entry-1');
      expect(attempt, isNotNull);
      expect(result.officialScore.scoreAttemptId, attempt!.id);
      expect(
        await repository.officialScoreRepository.currentForPlaceholder(
          result.placeholder.id,
        ),
        result.officialScore,
      );
    });

    test('repeating the client mutation id stores nothing more', () async {
      final slot = slots.first;
      final first = await enter(slot);

      final again = await enter(slot);

      expect(again.officialScore, first.officialScore);
      expect(
        await repository.officialScoreRepository.listForPlaceholder(
          first.placeholder.id,
        ),
        hasLength(1),
      );
    });

    test(
      'a correction keeps the first score and a stale one is refused',
      () async {
        final slot = slots.first;
        final first = await enter(slot);

        final corrected = await enter(
          slot,
          base: 1,
          mutation: 'entry-2',
          components: const {'time_flown': 500, 'launch_height': 200},
          reason: 'Timer misread',
        );
        await expectLater(
          enter(slot, base: 1, mutation: 'entry-3', reason: 'Late'),
          throwsA(isA<core.StaleRevisionError>()),
        );

        expect(corrected.officialScore.scoreRevision, 2);
        final history = await repository.officialScoreRepository
            .listForPlaceholder(first.placeholder.id);
        expect(history.map((score) => score.scoreRevision), [1, 2]);
        expect(history.first, first.officialScore);
        expect(
          (await repository.scorePlaceholderRepository.findById(
            first.placeholder.id,
          ))!.scoreRevision,
          2,
        );
      },
    );

    test(
      'a refused entry stores nothing and leaves the contest alone',
      () async {
        await expectLater(
          enter(slots.first, components: const {'time_flown': 540}),
          throwsA(isA<core.ScoringValidationError>()),
        );

        expect(
          (await repository.contestRepository.findById(contestId))!
              .lifecycleState,
          core.LifecycleState.ready,
        );
        expect(
          await repository.scoreAttemptRepository.findByClientMutationId(
            contestId,
            'entry-1',
          ),
          isNull,
        );
      },
    );

    test(
      'a stale placeholder rolls back the attempt, score and contest',
      () async {
        final placeholder = (await repository.scorePlaceholderRepository
            .findForAssignment(slots.first))!;
        final contest = (await repository.contestRepository.findById(
          contestId,
        ))!;
        final attempt = core.ScoreAttempt(
          id: core.Id.create(),
          contestId: contestId,
          scorePlaceholderId: placeholder.id,
          configRevisionId:
              (await repository.contestConfigurationRevisionRepository
                      .latestForContest(contestId))!
                  .id,
          matrixRevisionId:
              (await repository.matrixAssignmentRepository.findById(
                slots.first,
              ))!.matrixRevisionId,
          rawComponents: const {'motor_restart': true},
          actorId: actor,
          authority: core.Authority.director,
          clientMutationId: 'direct',
          baseScoreRevision: 0,
        );
        final entry = core.RecordedScore(
          attempt: attempt,
          officialScore: core.OfficialScore(
            id: core.Id.create(),
            contestId: contestId,
            scorePlaceholderId: placeholder.id,
            scoreAttemptId: attempt.id,
            scoreRevision: 1,
            components: const {'motor_restart': true},
            setAt: DateTime.utc(2026, 10, 8),
            setBy: actor,
            reason: 'Direct',
          ),
          placeholder: core.ScorePlaceholder(
            id: placeholder.id,
            contestId: contestId,
            contestParticipationId: placeholder.contestParticipationId,
            assignmentId: placeholder.assignmentId,
            state: core.ScorePlaceholderState.official,
            scoreRevision: 1,
            revision: placeholder.revision + 5,
          ),
          contest: contest.copyWithState(
            lifecycleState: core.LifecycleState.running,
            updatedAt: DateTime.utc(2026, 10, 8),
          ),
        );

        await expectLater(
          repository.officialScoreRepository.recordEntry(
            entry,
            metadata: meta(),
          ),
          throwsA(isA<core.StaleRevisionError>()),
        );

        expect(
          await repository.scoreAttemptRepository.findByClientMutationId(
            contestId,
            'direct',
          ),
          isNull,
        );
        expect(
          await repository.officialScoreRepository.listForPlaceholder(
            placeholder.id,
          ),
          isEmpty,
        );
        expect(
          (await repository.contestRepository.findById(contestId))!
              .lifecycleState,
          core.LifecycleState.ready,
        );
      },
    );

    group('the history of a slot', () {
      test('is empty before any score', () async {
        final history = await service.history(contestId, slots.first);

        expect(history.entries, isEmpty);
      });

      test(
        'lists every revision with its reason, the last as current',
        () async {
          final slot = slots.first;
          await enter(slot);
          await enter(
            slot,
            base: 1,
            mutation: 'entry-2',
            components: const {'time_flown': 500, 'launch_height': 200},
            reason: 'Timer misread',
          );

          final history = (await service.history(contestId, slot)).entries;

          expect(history.map((e) => e.scoreRevision), [1, 2]);
          expect(history.map((e) => e.outcome), [
            ScoreHistoryOutcome.superseded,
            ScoreHistoryOutcome.current,
          ]);
          expect(history.map((e) => e.reason), [
            ScoresService.defaultReason,
            'Timer misread',
          ]);
          expect(history.first.components['time_flown'], 540);
          expect(history.last.components['time_flown'], 500);
          expect(history.every((e) => e.actorId == actor), isTrue);
          expect(
            history.every((e) => e.authority == core.Authority.director),
            isTrue,
          );
          expect(history.every((e) => e.at != null), isTrue);
        },
      );

      test('lists an attempt that never became official', () async {
        final slot = slots.first;
        final first = await enter(slot);
        final lost = core.ScoreAttempt(
          id: core.Id.create(),
          contestId: contestId,
          scorePlaceholderId: first.placeholder.id,
          configRevisionId:
              (await repository.contestConfigurationRevisionRepository
                      .latestForContest(contestId))!
                  .id,
          matrixRevisionId:
              (await repository.scoreAttemptRepository.latestForPlaceholder(
                first.placeholder.id,
              ))!.matrixRevisionId,
          rawComponents: const {'time_flown': 600, 'launch_height': 100},
          actorId: core.Id.create(),
          authority: core.Authority.participant,
          clientMutationId: 'participant-1',
          baseScoreRevision: 0,
        );
        await repository.scoreAttemptRepository.append(lost, metadata: meta());

        final history = (await service.history(contestId, slot)).entries;

        expect(history.map((e) => e.outcome), [
          ScoreHistoryOutcome.current,
          ScoreHistoryOutcome.notAdopted,
        ]);
        final notAdopted = history.last;
        expect(notAdopted.scoreRevision, isNull);
        expect(notAdopted.authority, core.Authority.participant);
        expect(notAdopted.components['time_flown'], 600);
        expect(notAdopted.at, isNull);
      });

      test('shows a submission awaiting a decision as pending', () async {
        final slot = slots.first;
        final placeholder = (await repository.scorePlaceholderRepository
            .findForAssignment(slot))!;
        final assignment = (await repository.matrixAssignmentRepository
            .findById(slot))!;
        final attempt = core.ScoreAttempt(
          id: core.Id.create(),
          contestId: contestId,
          scorePlaceholderId: placeholder.id,
          configRevisionId:
              (await repository.contestConfigurationRevisionRepository
                      .latestForContest(contestId))!
                  .id,
          matrixRevisionId: assignment.matrixRevisionId,
          rawComponents: const {'time_flown': 600, 'launch_height': 100},
          actorId: core.Id.create(),
          authority: core.Authority.participant,
          clientMutationId: 'participant-2',
          baseScoreRevision: 0,
        );
        await repository.scoreAttemptRepository.recordAttempt(
          attempt,
          core.ScorePlaceholder(
            id: placeholder.id,
            contestId: contestId,
            contestParticipationId: placeholder.contestParticipationId,
            assignmentId: placeholder.assignmentId,
            state: core.ScorePlaceholderState.submitted,
            scoreRevision: 0,
            revision: placeholder.revision,
          ),
          metadata: meta(),
        );

        final history = (await service.history(contestId, slot)).entries;

        expect(history.map((e) => e.outcome), [ScoreHistoryOutcome.pending]);
      });

      test('refuses an unknown slot', () async {
        await expectLater(
          service.history(contestId, core.Id.create()),
          throwsA(isA<core.EntityNotFoundError>()),
        );
      });
    });

    test('lists the slots and how far each round is scored', () async {
      await enter(slots.first);

      final scores = await service.list(contestId);

      expect(scores.slots, hasLength(slotCount));
      expect(scores.slots.where((s) => s.officialScore != null), hasLength(1));
      expect(scores.rounds.map((r) => (r.ordinal, r.scored, r.total)), [
        (1, 1, 4),
        (2, 0, 4),
      ]);
    });

    test('the matrix counts the scored flights of each round', () async {
      await enter(slots.first);

      final matrix = await MatrixService(repository).current(contestId);

      expect(matrix.progress.map((r) => (r.ordinal, r.scored, r.total)), [
        (1, 1, 4),
        (2, 0, 4),
      ]);
    });

    group('a retired pilot', () {
      Future<void> retire(core.Id assignmentId, int round) async {
        final assignment = (await repository.matrixAssignmentRepository
            .findById(assignmentId))!;
        final participation = (await repository.contestParticipationRepository
            .findById(assignment.contestParticipationId))!;
        await ParticipationsService(repository).update(
          contestId,
          actor,
          participation.id,
          retiredAtRound: round,
          baseRevision: participation.revision,
          metadata: meta(),
        );
      }

      Future<List<core.Id>> secondRound() async {
        final matrix = await MatrixService(repository).current(contestId);
        final second = matrix.rounds.firstWhere((round) => round.ordinal == 2);
        return [
          for (final assignment in matrix.assignments)
            if (assignment.scheduledRoundId == second.id) assignment.id,
        ];
      }

      Future<List<(int, int, int)>> counts() async => [
        for (final r in (await service.list(contestId)).rounds)
          (r.ordinal, r.scored, r.total),
      ];

      test('is not counted as missing in the rounds they miss', () async {
        await retire(slots.first, 2);

        // Round 1 is unaffected; round 2 expects three pilots.
        expect(await counts(), [(1, 0, 4), (2, 0, 3)]);
      });

      test('leaves the round complete once the others are scored', () async {
        await retire(slots.first, 2);
        final round2 = await secondRound();
        var n = 0;
        for (final slot in round2) {
          final assignment = (await repository.matrixAssignmentRepository
              .findById(slot))!;
          final participation = (await repository.contestParticipationRepository
              .findById(assignment.contestParticipationId))!;
          if (participation.hasRetiredBy(2)) continue;
          await enter(slot, mutation: 'round2-${n++}');
        }

        final progress = (await service.list(contestId)).rounds.last;

        expect((progress.scored, progress.total), (3, 3));
        expect(progress.isComplete, isTrue);
      });

      test('keeps a score they entered before retiring', () async {
        await enter(slots.first);
        await retire(slots.first, 1);

        expect(await counts(), [(1, 1, 4), (2, 0, 3)]);
      });

      test('leaves a round nobody can fly empty, not complete', () async {
        for (final slot in slots) {
          await retire(slot, 1);
        }

        final scores = await service.list(contestId);

        expect(scores.rounds.map((r) => (r.ordinal, r.scored, r.total)), [
          (1, 0, 0),
          (2, 0, 0),
        ]);
        expect(scores.rounds.any((r) => r.isComplete), isFalse);
        expect(scores.slots, hasLength(slotCount));
      });

      test('is left out of the matrix page counts too', () async {
        await retire(slots.first, 2);

        final matrix = await MatrixService(repository).current(contestId);

        expect(matrix.progress.map((r) => (r.ordinal, r.scored, r.total)), [
          (1, 0, 4),
          (2, 0, 3),
        ]);
      });
    });
  });
}

/// A configured F5J contest of four pilots, drawn in 2 rounds of 1 group.
