import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';
import '../support/matrix_slot.dart';

void main() => forEachBackend(_tests);

/// Seeded rounds against the real repositories: the preliminary round is
/// drawn as usual, and the next round waits for official scores and current
/// standings, then puts the leaders in the last group.
void _tests(Backend backend) {
  group('seeded rounds', () {
    late Installation inst;
    late Repository repository;
    late core.Id contestId;
    final actor = core.Id.create();
    var now = DateTime.utc(2026, 10, 17, 15);
    var mutations = 0;

    core.MutationMetadata meta() => core.MutationMetadata(
      clientMutationId: 'seeded-${mutations++}',
      authority: core.Authority.director,
      clientTime: now,
      actorId: actor,
    );

    setUp(() async {
      now = DateTime.utc(2026, 10, 17, 15);
      inst = await Installation.open(backend);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      contestId = await drawnContest(
        repository,
        actor,
        rounds: 1,
        coreOptions: const {
          'draw_mode': 'SeededManOnMan',
          'preliminary_rounds': 1,
        },
      );
    });

    tearDown(() => inst.close());

    Future<core.CurrentMatrix> seededRound({int firstRound = 2}) async {
      final latest = await repository.matrixRevisionRepository.latestForContest(
        contestId,
      );
      return MatrixRedrawService(repository).redraw(
        contestId,
        id: core.Id.create(),
        firstRound: firstRound,
        rounds: 1,
        groupsPerRound: 2,
        randomSeed: 3,
        base: latest!.revisionNumber,
        actorId: actor,
        metadata: meta(),
      );
    }

    Future<List<MatrixSlot>> roundSlots(int ordinal) async {
      final matrix = await MatrixService(repository).current(contestId);
      final round = matrix.rounds.firstWhere((r) => r.ordinal == ordinal);
      return [
        for (final a in matrix.assignments)
          if (a.scheduledRoundId == round.id)
            MatrixSlot(a.id, a.contestParticipationId),
      ];
    }

    // Raw scores are time + 50 (landing) - 100 (height penalty).
    const times = [500, 540, 580, 590];

    Future<List<MatrixSlot>> scoreRound(int ordinal, {int count = 4}) async {
      final slots = await roundSlots(ordinal);
      final scores = ScoresService(repository, clock: () => now);
      for (var i = 0; i < count; i++) {
        await scores.enterOfficialScore(
          contestId,
          slots[i].assignmentId,
          clientMutationId: 'entry-${mutations++}',
          baseScoreRevision: 0,
          components: {
            'time_flown': times[i],
            'launch_height': 200,
            'landing': 'points_50',
          },
          actorId: actor,
          metadata: meta(),
        );
      }
      return slots;
    }

    Future<List<MatrixSlot>> scorePreliminary({int count = 4}) =>
        scoreRound(1, count: count);

    test('the first draw covers only the preliminary rounds', () async {
      await expectLater(
        drawnContest(
          repository,
          actor,
          mutationPrefix: 'second',
          rounds: 2,
          coreOptions: const {
            'draw_mode': 'SeededManOnMan',
            'preliminary_rounds': 1,
          },
        ),
        throwsA(
          isA<core.ContestStateError>().having(
            (e) => e.code,
            'code',
            'seeded_rounds_need_standings',
          ),
        ),
      );
    });

    test('team protection cannot be saved with a seeded draw', () async {
      await expectLater(
        drawnContest(
          repository,
          actor,
          mutationPrefix: 'third',
          coreOptions: const {
            'draw_mode': 'SeededManOnMan',
            'teams_enabled': true,
            'team_pilot_count': 2,
            'team_protection': true,
          },
        ),
        throwsArgumentError,
      );
    });

    test('a seeded round waits for every preliminary score', () async {
      await scorePreliminary(count: 3);

      await expectLater(
        seededRound(),
        throwsA(
          isA<core.ContestStateError>()
              .having((e) => e.code, 'code', 'scores_incomplete')
              .having((e) => e.message, 'message', contains('1 is not yet')),
        ),
      );
    });

    test('a seeded round waits for current standings', () async {
      await scorePreliminary();

      await expectLater(
        seededRound(),
        throwsA(
          isA<core.ContestStateError>().having(
            (e) => e.code,
            'code',
            'standings_missing',
          ),
        ),
      );
    });

    test('leaders fly in the last group of the seeded round', () async {
      final slots = await scorePreliminary();
      await ResultsService(repository, clock: () => now).recalculate(contestId);

      final matrix = await seededRound();

      final round = matrix.rounds.firstWhere((r) => r.ordinal == 2);
      final groupOf = {
        for (final a in matrix.assignments)
          if (a.scheduledRoundId == round.id) a.contestParticipationId: a.group,
      };
      // Times rise with the slot index, so the last two slots lead.
      expect(groupOf[slots[0].participationId], 1);
      expect(groupOf[slots[1].participationId], 1);
      expect(groupOf[slots[2].participationId], 2);
      expect(groupOf[slots[3].participationId], 2);
      expect(matrix.revision!.drawMode, core.DrawMode.seededManOnMan);
      expect(matrix.revision!.seedingSnapshot['standings'], isNotNull);
    });

    test('seeded rounds are drawn one at a time', () async {
      await scorePreliminary();
      await ResultsService(repository, clock: () => now).recalculate(contestId);

      await expectLater(
        MatrixRedrawService(repository).redraw(
          contestId,
          id: core.Id.create(),
          firstRound: 2,
          rounds: 2,
          groupsPerRound: 2,
          base: 1,
          actorId: actor,
          metadata: meta(),
        ),
        throwsA(
          isA<core.ContestStateError>().having(
            (e) => e.code,
            'code',
            'one_seeded_round',
          ),
        ),
      );
    });

    test('the preliminary and seeded rounds are drawn separately', () async {
      await expectLater(
        MatrixRedrawService(repository).redraw(
          contestId,
          id: core.Id.create(),
          firstRound: 1,
          rounds: 2,
          groupsPerRound: 2,
          base: 1,
          actorId: actor,
          metadata: meta(),
        ),
        throwsA(
          isA<core.ContestStateError>().having(
            (e) => e.code,
            'code',
            'seeded_rounds_need_standings',
          ),
        ),
      );
    });

    test('a second seeded round uses the standings after the first', () async {
      await scorePreliminary();
      await ResultsService(repository, clock: () => now).recalculate(contestId);
      await seededRound();

      // Round 2 is not scored yet.
      await expectLater(
        seededRound(firstRound: 3),
        throwsA(
          isA<core.ContestStateError>().having(
            (e) => e.code,
            'code',
            'scores_incomplete',
          ),
        ),
      );

      await scoreRound(2);
      await ResultsService(repository, clock: () => now).recalculate(contestId);
      final matrix = await seededRound(firstRound: 3);

      expect(matrix.rounds.where((r) => r.ordinal == 3), hasLength(1));
      expect(matrix.revision!.drawMode, core.DrawMode.seededManOnMan);
      final standings =
          matrix.revision!.seedingSnapshot['standings']!
              as Map<String, Object?>;
      expect(standings['as_of_round'], 2);
    });

    test('standings made stale by a later score are refused', () async {
      final slots = await scorePreliminary();
      await ResultsService(repository, clock: () => now).recalculate(contestId);

      now = now.add(const Duration(minutes: 5));
      await ScoresService(repository, clock: () => now).enterOfficialScore(
        contestId,
        slots[0].assignmentId,
        clientMutationId: 'entry-${mutations++}',
        baseScoreRevision: 1,
        components: {
          'time_flown': 595,
          'launch_height': 200,
          'landing': 'points_50',
        },
        reason: 'Timer misread',
        actorId: actor,
        metadata: meta(),
      );

      await expectLater(
        seededRound(),
        throwsA(
          isA<core.ContestStateError>().having(
            (e) => e.code,
            'code',
            'standings_not_validated',
          ),
        ),
      );
    });
  });
}
