import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';
import '../support/matrix_slot.dart';

void main() => forEachBackend(_tests);

/// The results service against the real repositories: what it stores, what
/// it reads back, and when it calls the stored results stale.
void _tests(Backend backend) {
  group('ResultsService', () {
    late Installation inst;
    late Repository repository;
    late ScoresService scores;
    late ResultsService results;
    late core.Id contestId;
    late List<MatrixSlot> firstRound;
    final actor = core.Id.create();
    var now = DateTime.utc(2026, 10, 17, 15);

    setUp(() async {
      inst = await Installation.open(backend);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      now = DateTime.utc(2026, 10, 17, 15);
      scores = ScoresService(repository, clock: () => now);
      results = ResultsService(repository, clock: () => now);
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
        scores.enterOfficialScore(
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

    // Raw scores are time + 50 (landing) - 100 (height penalty).
    const times = [500, 540, 580, 590];

    Future<void> scoreRoundOne() async {
      for (var i = 0; i < firstRound.length; i++) {
        await enter(firstRound[i], times[i]);
      }
    }

    test(
      'a contest with no scores has no standings and is not stale',
      () async {
        final read = await results.read(contestId);

        expect(read.asOfRound, isNull);
        expect(read.standings, isEmpty);
        expect(read.isStale, isFalse);
        expect(read.isPreliminary, isFalse);
      },
    );

    test('scores nobody has calculated yet read as stale', () async {
      await scoreRoundOne();

      final read = await results.read(contestId);

      expect(read.standings, isEmpty);
      expect(read.isStale, isTrue);
      expect(read.isPreliminary, isTrue);
    });

    test('standings match the scoring engine for a scored round', () async {
      await scoreRoundOne();

      final read = await results.recalculate(contestId);

      expect(read.asOfRound, 1);
      expect(read.isStale, isFalse);
      expect(read.isPreliminary, isFalse);
      expect(read.standings, hasLength(4));
      final byPlace = {
        for (final standing in read.standings)
          standing.contestParticipationId: standing,
      };
      // The winner of the only group scores 1000; the others are scaled by
      // their raw score against the winner's.
      const raw = [450.0, 490.0, 530.0, 540.0];
      for (var i = 0; i < 4; i++) {
        final standing = byPlace[firstRound[i].participationId]!;
        expect(standing.place, 4 - i, reason: 'pilot $i');
        expect(
          standing.overallScore,
          closeTo(raw[i] / 540 * 1000, 0.05),
          reason: 'pilot $i',
        );
        expect(standing.calculationVersion, 'f5j-1');
      }
      expect([for (final s in read.standings) s.place], [1, 2, 3, 4]);
    });

    test('the flights of a round are listed with their group', () async {
      await scoreRoundOne();
      await results.recalculate(contestId);

      final round = await results.round(contestId, 1);

      expect(round.ordinal, 1);
      expect(round.isStale, isFalse);
      expect(round.flights, hasLength(4));
      expect({for (final f in round.flights) f.group}, {1});
      expect(
        {for (final f in round.flights) f.result.rawPoints},
        {450.0, 490.0, 530.0, 540.0},
      );
    });

    test('a round with missing scores is preliminary', () async {
      await enter(firstRound[0], times[0]);
      await enter(firstRound[1], times[1]);

      final read = await results.recalculate(contestId);

      expect(read.asOfRound, 1);
      expect(read.isStale, isFalse);
      expect(read.isPreliminary, isTrue);
    });

    test('a score entered after the calculation makes it stale', () async {
      await scoreRoundOne();
      await results.recalculate(contestId);

      now = now.add(const Duration(minutes: 5));
      await enter(firstRound[0], 595, base: 1);

      final stale = await results.read(contestId);
      expect(stale.isStale, isTrue);
      expect(stale.isPreliminary, isTrue);

      now = now.add(const Duration(minutes: 1));
      final fresh = await results.recalculate(contestId);
      expect(fresh.isStale, isFalse);
      final winner = fresh.standings.firstWhere((s) => s.place == 1);
      expect(winner.contestParticipationId, firstRound[0].participationId);
    });

    test('results of another calculation version read as stale', () async {
      await scoreRoundOne();
      await results.recalculate(contestId);
      final stored = await repository.participationStandingRepository
          .listForContest(contestId);
      await repository.participationStandingRepository.replaceForContest(
        contestId,
        [
          for (final standing in stored)
            core.ParticipationStanding.fromJson({
              ...standing.toJson(),
              'calculation_version': 'f5j-0',
            }),
        ],
      );

      expect((await results.read(contestId)).isStale, isTrue);
    });

    test('a round that does not exist is refused', () async {
      await expectLater(
        results.round(contestId, 9),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('a contest that does not exist is refused', () async {
      await expectLater(
        results.read(core.Id.create()),
        throwsA(isA<core.EntityNotFoundError>()),
      );
    });
  });
}
