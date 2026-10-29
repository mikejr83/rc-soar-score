import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/drawn_contest.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

/// Hide and show results against the real repositories: the round that
/// hiding records comes from the stored scores.
void _tests(Backend backend) {
  group('ContestsService results hiding', () {
    late Installation inst;
    late Repository repository;
    late ContestsService service;
    late ScoresService scores;
    late core.Id contestId;
    late Map<int, List<core.Id>> slotsByRound;
    final actor = core.Id.create();

    setUp(() async {
      inst = await Installation.open(backend);
      await SystemDataSeeder(inst.db).seed();
      repository = Repository(inst.db);
      service = ContestsService(repository);
      scores = ScoresService(repository);
      contestId = await drawnContest(repository, actor);
      final matrix = await MatrixService(repository).current(contestId);
      slotsByRound = {
        for (final round in matrix.rounds)
          round.ordinal: [
            for (final assignment in matrix.assignments)
              if (assignment.scheduledRoundId == round.id) assignment.id,
          ],
      };
    });

    tearDown(() => inst.close());

    var mutations = 0;
    core.MutationMetadata meta() => core.MutationMetadata(
      clientMutationId: 'request-${mutations++}',
      authority: core.Authority.director,
      clientTime: DateTime.utc(2026, 10, 8),
      actorId: actor,
    );

    Future<void> score(core.Id assignmentId) async {
      await scores.enterOfficialScore(
        contestId,
        assignmentId,
        clientMutationId: 'entry-${mutations++}',
        baseScoreRevision: 0,
        components: const {
          'time_flown': 540,
          'launch_height': 200,
          'landing': 'points_50',
        },
        actorId: actor,
        metadata: meta(),
      );
    }

    Future<core.Contest> apply(core.ContestAction action) async {
      final contest = await service.getContest(contestId);
      return service.applyAction(
        contestId,
        action,
        baseRevision: contest.revision,
        metadata: meta(),
      );
    }

    test('is refused before the contest is Running', () async {
      await expectLater(
        apply(core.ContestAction.hideResults),
        throwsA(isA<core.ContestStateError>()),
      );
    });

    test('records the round in progress, then the last completed', () async {
      await score(slotsByRound[1]!.first);

      final hidden = await apply(core.ContestAction.hideResults);
      expect(hidden.resultsHiddenThroughRound, 1);
      expect(hidden.resultsHiddenAt, isNotNull);

      for (final slot in slotsByRound[1]!.skip(1)) {
        await score(slot);
      }
      final again = await apply(core.ContestAction.hideResults);
      expect(again.resultsHiddenThroughRound, 1);

      await score(slotsByRound[2]!.first);
      final moved = await apply(core.ContestAction.hideResults);
      expect(moved.resultsHiddenThroughRound, 2);
      expect(moved.lifecycleState, core.LifecycleState.running);
    });

    test('show clears it and is refused when nothing is hidden', () async {
      await score(slotsByRound[1]!.first);
      await expectLater(
        apply(core.ContestAction.showResults),
        throwsA(isA<core.ContestStateError>()),
      );

      await apply(core.ContestAction.hideResults);
      final shown = await apply(core.ContestAction.showResults);

      expect(shown.resultsHidden, isFalse);
      expect(shown.resultsHiddenAt, isNull);
    });

    test('completing the contest ends hiding', () async {
      await score(slotsByRound[1]!.first);
      await apply(core.ContestAction.hideResults);

      final completed = await apply(core.ContestAction.complete);

      expect(completed.resultsHidden, isFalse);
    });

    test('leaves audit events naming the round', () async {
      await score(slotsByRound[1]!.first);
      await apply(core.ContestAction.hideResults);
      await apply(core.ContestAction.showResults);

      final reasons = [
        for (final event in await service.auditEvents(
          contestId,
          action: core.AuditAction.stateTransition,
        ))
          event.reason,
      ];

      expect(
        reasons,
        containsAll([
          'hideResults: ResultsHidden none → through round 1',
          'showResults: ResultsHidden through round 1 → none',
        ]),
      );
    });
  });
}
