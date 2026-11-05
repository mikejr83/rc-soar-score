import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// Results are derived and never sync, so the service rebuilds them after it
/// accepts a contest's changes.
void _tests(Backend backend) {
  late core.Id contestId;
  late core.ContestScopeKey scope;

  Future<AcceptorHarness> open({required bool recalculates}) async {
    final harness = await AcceptorHarness.open(
      backend,
      recalculates: recalculates,
    );
    contestId = await harness.drawContestOnClient();
    scope = core.ContestScopeKey(contestId);
    final matrix = await MatrixService(harness.clientRepository)
        .current(contestId);
    final first = matrix.rounds.firstWhere((round) => round.ordinal == 1);
    final slot = matrix.assignments
        .firstWhere((assignment) => assignment.scheduledRoundId == first.id)
        .id;
    await ScoresService(harness.clientRepository).enterOfficialScore(
      contestId,
      slot,
      clientMutationId: 'entry-1',
      baseScoreRevision: 0,
      components: const {
        'time_flown': 540,
        'launch_height': 200,
        'landing': 'points_50',
      },
      actorId: harness.account,
      metadata: core.MutationMetadata(
        clientMutationId: 'entry-1',
        authority: core.Authority.director,
        clientTime: DateTime.utc(2026, 10, 14),
        actorId: harness.account,
      ),
    );
    await harness.exchange(
      core.DirectorScopeKey(harness.account),
      mutations: await harness.outbox(core.DirectorScopeKey(harness.account)),
    );
    await harness.exchange(scope, mutations: await harness.outbox(scope));
    return harness;
  }

  test(
    'a synced contest with scores has current results on the server',
    () async {
      final harness = await open(recalculates: true);
      addTearDown(harness.close);

      final results = await ResultsService(harness.serverRepository)
          .read(contestId);

      expect(results.isStale, isFalse);
      expect(results.standings, isNotEmpty);
    },
  );

  test('without the recalculation the same contest reads stale', () async {
    final harness = await open(recalculates: false);
    addTearDown(harness.close);

    final results = await ResultsService(harness.serverRepository)
        .read(contestId);

    expect(results.isStale, isTrue);
    expect(results.standings, isEmpty);
  });
}
