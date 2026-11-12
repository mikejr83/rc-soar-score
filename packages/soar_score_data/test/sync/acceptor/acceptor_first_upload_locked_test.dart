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

  /// Opens a client with one score entered and the contest finished: always
  /// Completed, and Locked when [lock] says so.
  Future<void> prepare(core.AdminLock lock) async {
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
        adminLock: lock,
        updatedAt: DateTime.utc(2026, 10, 15),
      ),
      metadata: core.MutationMetadata(
        clientMutationId: 'finish-1',
        authority: core.Authority.director,
        clientTime: DateTime.utc(2026, 10, 15),
        actorId: harness.account,
      ),
    );
  }

  tearDown(() => harness.close());

  test('a completed, locked contest uploads in full', () async {
    await prepare(core.AdminLock.locked);
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
    await prepare(core.AdminLock.locked);
    await harness.uploadAll(contestId);
    final participation =
        (await harness.server.stores.of('ContestParticipation').all()).first
            as core.ContestParticipation;

    final out = await harness.exchange(
      scope,
      mutations: [
        harness.save('ContestParticipation', {
          ...participation.toJson(),
          'participant_number': 99,
        }, base: participation.revision),
      ],
    );

    expect(out.results.single.outcome, core.MutationOutcome.rejected);
    expect(out.results.single.reasonCode, 'locked');
  });

  test('a completed contest that is not locked uploads in full', () async {
    await prepare(core.AdminLock.unlocked);
    await harness.uploadAll(contestId);

    final stored = await harness.stored('Contest', contestId);
    expect(stored!['admin_lock'], 'Unlocked');
    expect(stored['lifecycle_state'], 'Completed');
    expect(await harness.server.count('official_scores'), 1);
  });

  test('a later exchange is still refused for a completed contest', () async {
    await prepare(core.AdminLock.unlocked);
    await harness.uploadAll(contestId);
    final participation =
        (await harness.server.stores.of('ContestParticipation').all()).first
            as core.ContestParticipation;

    final out = await harness.exchange(
      scope,
      mutations: [
        harness.save('ContestParticipation', {
          ...participation.toJson(),
          'participant_number': 99,
        }, base: participation.revision),
      ],
    );

    expect(out.results.single.reasonCode, 'locked');
  });

  group('a first upload sent in several exchanges', () {
    late List<SyncMutation> tail;
    late int afterHead;

    /// Uploads the director's scope, then the contest's creation and a few
    /// mutations in the first exchange, leaving the rest in [tail].
    Future<void> sendHead({FirstUploadPhase? phase}) async {
      final director = core.DirectorScopeKey(harness.account);
      final owned = await harness.outbox(director);
      final accepted = await harness.exchange(director, mutations: owned);
      await harness.acknowledge(owned, accepted.results);
      final sent = await harness.outbox(scope);
      final first = await harness.exchange(
        scope,
        mutations: sent.take(3).toList(),
        firstUpload: phase,
      );
      expect(first.results.map((r) => r.outcome).toSet(), {
        core.MutationOutcome.accepted,
      });
      tail = sent.skip(3).toList();
      afterHead = first.serverSequence;
    }

    Future<SyncExchangeOutput> sendTail(FirstUploadPhase? phase) => harness
        .exchange(scope, mutations: tail, after: afterHead, firstUpload: phase);

    test('the later batches are accepted while the upload is open', () async {
      await prepare(core.AdminLock.locked);
      await sendHead(phase: FirstUploadPhase.open);
      final out = await sendTail(FirstUploadPhase.open);
      expect(out.results.map((r) => r.outcome).toSet(), {
        core.MutationOutcome.accepted,
      });
    });

    test('without the flag they are refused as locked', () async {
      await prepare(core.AdminLock.locked);
      await sendHead(phase: FirstUploadPhase.open);
      final out = await sendTail(null);
      expect(out.results.map((r) => r.reasonCode), contains('locked'));
    });

    test('finishing the upload ends the exemption', () async {
      await prepare(core.AdminLock.locked);
      await sendHead(phase: FirstUploadPhase.open);
      await harness.exchange(
        scope,
        after: afterHead,
        firstUpload: FirstUploadPhase.finish,
      );

      final out = await sendTail(FirstUploadPhase.open);

      expect(out.results.map((r) => r.reasonCode), contains('locked'));
    });

    test('an upload sent whole never opens the exemption', () async {
      await prepare(core.AdminLock.locked);
      await sendHead();
      final out = await sendTail(FirstUploadPhase.open);
      expect(out.results.map((r) => r.reasonCode), contains('locked'));
    });
  });
}
