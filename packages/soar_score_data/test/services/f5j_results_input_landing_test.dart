import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

/// The results read each flight's landing from the contest's landing table,
/// which is read once per calculation (#840). A landing the table does not
/// have still refuses the calculation, and a flight without a landing needs
/// no table.
void _tests(Backend backend) {
  group('results input landing', () {
    late Installation inst;
    late Repository repository;
    late core.Id contestId;
    final actor = core.Id.create();

    setUp(() async {
      inst = await Installation.open(backend);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      contestId = await drawnContest(repository, actor);
    });
    tearDown(() => inst.close());

    /// Stores an official score for the first open flight, bypassing the
    /// service that would refuse an unknown landing entry.
    Future<void> store(Map<String, Object?> components) async {
      final stores = inst.stores;
      final revision = (await repository.contestConfigurationRevisionRepository
          .latestForContest(contestId))!;
      final matrix = (await repository.matrixRevisionRepository
          .latestForContest(contestId))!;
      final placeholder =
          (await repository.scorePlaceholderRepository.listForContest(
            contestId,
          )).first;
      final attempt = core.ScoreAttempt(
        id: core.Id.create(),
        contestId: contestId,
        scorePlaceholderId: placeholder.id,
        configRevisionId: revision.id,
        matrixRevisionId: matrix.id,
        rawComponents: components,
        actorId: actor,
        authority: core.Authority.director,
        clientMutationId: 'seed-${components.hashCode}',
        baseScoreRevision: 0,
        acceptedAt: DateTime.utc(2026, 10, 17, 15),
      );
      final official = core.OfficialScore(
        id: core.Id.create(),
        contestId: contestId,
        scorePlaceholderId: placeholder.id,
        scoreAttemptId: attempt.id,
        scoreRevision: 1,
        components: components,
        setAt: DateTime.utc(2026, 10, 17, 15),
        setBy: actor,
        reason: 'Seeded',
      );
      await stores
          .of('ScoreAttempt')
          .upsertJson(stores.of('ScoreAttempt').encode(attempt));
      await stores
          .of('OfficialScore')
          .upsertJson(stores.of('OfficialScore').encode(official));
      await stores
          .of('ScorePlaceholder')
          .upsertJson(
            stores
                .of('ScorePlaceholder')
                .encode(
                  core.ScorePlaceholder(
                    id: placeholder.id,
                    contestId: contestId,
                    contestParticipationId: placeholder.contestParticipationId,
                    assignmentId: placeholder.assignmentId,
                    state: core.ScorePlaceholderState.official,
                    scoreRevision: 1,
                    revision: placeholder.revision + 1,
                  ),
                ),
          );
    }

    test('a landing entry the table lacks refuses the calculation', () async {
      await store({
        'time_flown': 500,
        'launch_height': 100,
        'landing': 'not_a_real_entry',
      });

      await expectLater(
        PreliminaryResultsService(repository).calculate(contestId),
        throwsA(isA<core.ScoringValidationError>()),
      );
      await expectLater(
        ResultsService(repository).recalculate(contestId),
        throwsA(isA<core.ScoringValidationError>()),
      );
    });

    test('a known landing entry scores, and none needs no entry', () async {
      await store({
        'time_flown': 500,
        'launch_height': 100,
        'landing': 'points_50',
      });
      final calculation = await PreliminaryResultsService(repository)
          .calculate(contestId);
      expect(calculation.input.scored, hasLength(1));
      expect(calculation.recalculation, isNotNull);
    });
  });
}
