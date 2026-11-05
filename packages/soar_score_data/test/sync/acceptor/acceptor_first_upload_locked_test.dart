import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// A contest that is Completed and Locked when it first reaches the service
/// (a restored GliderScore competition, or one finished offline) uploads in
/// full: the rest of the first upload is its history.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;
  late core.ContestScopeKey scope;

  setUp(() async {
    harness = await AcceptorHarness.open(backend, recalculates: true);
    contestId = await harness.drawContestOnClient();
    scope = core.ContestScopeKey(contestId);
    final matrix = await MatrixService(harness.clientRepository)
        .current(contestId);
    final first = matrix.rounds.firstWhere((round) => round.ordinal == 1);
    final slot = matrix.assignments
        .firstWhere((assignment) => assignment.scheduledRoundId == first.id)
        .id;
    final metadata = core.MutationMetadata(
      clientMutationId: 'entry-1',
      authority: core.Authority.director,
      clientTime: DateTime.utc(2026, 10, 14),
      actorId: harness.account,
    );
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
      metadata: metadata,
    );
    final contest = (await harness.clientRepository.contestRepository.findById(
      contestId,
    ))!;
    await harness.clientRepository.contestRepository.save(
      contest.copyWithState(
        lifecycleState: core.LifecycleState.completed,
        adminLock: core.AdminLock.locked,
        updatedAt: DateTime.utc(2026, 10, 15),
      ),
      metadata: core.MutationMetadata(
        clientMutationId: 'finish-1',
        authority: core.Authority.director,
        clientTime: DateTime.utc(2026, 10, 15),
        actorId: harness.account,
      ),
    );
  });
  tearDown(() => harness.close());

  test('a completed, locked contest uploads in full', () async {
    await harness.uploadAll(
      contestId,
    ); // throws unless every change is accepted

    final stored = await harness.stored('Contest', contestId);
    expect(stored!['admin_lock'], 'Locked');
    expect(stored['lifecycle_state'], 'Completed');
    expect(await harness.server.count('official_scores'), 1);
    final results = await ResultsService(harness.serverRepository)
        .read(contestId);
    expect(results.isStale, isFalse);
    expect(results.standings, isNotEmpty);
  });

  test('a later exchange is still refused for a locked contest', () async {
    await harness.uploadAll(contestId);
    final participation =
        (await harness.server.stores.of('ContestParticipation').all()).first
            as core.ContestParticipation;

    final out = await harness.exchange(
      scope,
      mutations: [
        harness.save('ContestParticipation', {
          ...participation.toJson(),
          'number': 99,
        }, base: participation.revision),
      ],
    );

    expect(out.results.single.outcome, core.MutationOutcome.rejected);
    expect(out.results.single.reasonCode, 'locked');
  });
}
