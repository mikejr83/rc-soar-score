import 'dart:async';

import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';
import '../../support/overlap_support.dart';

void main() {
  forEachBackend(_tests);

  test('a gated operation that fails before it is ready surfaces its own '
      'error, and both gates open', () async {
    final gateA = Completer<void>();
    final gateB = Completer<void>();
    final neverReady = Completer<void>();
    final failing = Future<void>.error(StateError('failed early'))..ignore();

    await expectLater(
      readyOrDone(neverReady.future, failing),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', 'failed early'),
      ),
    );
    await settleStarted([gateA, gateB], [failing]);

    expect(gateA.isCompleted, isTrue);
    expect(gateB.isCompleted, isTrue);
  });

  test('an operation that ends without signalling ready is reported', () async {
    final neverReady = Completer<void>();

    await expectLater(
      readyOrDone(neverReady.future, Future<void>.value()),
      throwsA(isA<StateError>()),
    );
  });
}

/// Builds a projection, then waits to be released before handing it back, so a
/// test decides when each publish stores.
class _GatedBuilder extends PublicationProjectionBuilder {
  _GatedBuilder(super.repository);

  final built = Completer<void>();
  final release = Completer<void>();
  var _gated = false;

  @override
  Future<PublicationBuild> build({
    required core.Id contestId,
    required core.Id publicationId,
    required int projectionRevision,
    required String clientMutationId,
    core.Id? publishedBy,
  }) async {
    final result = await super.build(
      contestId: contestId,
      publicationId: publicationId,
      projectionRevision: projectionRevision,
      clientMutationId: clientMutationId,
      publishedBy: publishedBy,
    );
    if (!_gated) {
      _gated = true;
      built.complete();
      await release.future;
    }
    return result;
  }
}

/// A manual publish that built from the old configuration wins the store
/// while a synced configuration edit is publishing: the sync publish must
/// rebuild, not leave the old configuration public.
void _tests(Backend backend) {
  test('a manual publish that wins the revision race does not leave the old '
      'configuration public', () async {
    late _GatedBuilder syncBuilder;
    final harness = await AcceptorHarness.open(
      backend,
      recalculates: true,
      publicUpdates: (server) {
        syncBuilder = _GatedBuilder(server);
        return PublicUpdateService(
          server,
          publication: PublicationService(server, builder: syncBuilder),
        );
      },
    );
    addTearDown(harness.close);
    final contestId = await harness.drawContestOnClient();
    final scope = core.ContestScopeKey(contestId);
    await harness.uploadAll(contestId);
    final contest = (await harness.serverRepository.contestRepository.findById(
      contestId,
    ))!;
    await PublicationService(harness.serverRepository).publish(
      contestId,
      actorId: harness.account,
      authority: core.Authority.director,
      clientMutationId: 'first',
      sourceContestRevision: contest.revision,
    );

    final manualBuilder = _GatedBuilder(harness.serverRepository);
    Future<PublishResult>? manual;
    Future<SyncExchangeOutput>? sync;
    try {
      // The manual publish builds from the old configuration and waits.
      final startedManual = manual =
          PublicationService(
              harness.serverRepository,
              builder: manualBuilder,
            ).publish(
              contestId,
              actorId: harness.account,
              authority: core.Authority.director,
              clientMutationId: 'manual',
              sourceContestRevision: contest.revision,
            )
            ..ignore();
      await readyOrDone(manualBuilder.built.future, startedManual);

      // The director's configuration edit syncs; its publish builds and waits.
      await ContestConfigurationService(harness.clientRepository).save(
        contestId,
        ConfigurationInput(
          baseRevisionNumber: 1,
          disciplineProfileId: core.SystemDisciplineProfiles.f5jId,
          config: core.ContestConfig(
            core: const {
              'drop_after_rounds': [1],
            },
            discipline: const {'working_time': 600},
          ),
        ),
        createdBy: harness.account,
        metadata: core.MutationMetadata(
          clientMutationId: 'drop-rounds',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 10, 15),
          actorId: harness.account,
        ),
      );
      final sent = await harness.outbox(scope);
      final startedSync = sync = harness.exchange(scope, mutations: sent)
        ..ignore();
      await readyOrDone(syncBuilder.built.future, startedSync);

      // The manual store wins, then the sync publish finds the revision
      // moved.
      manualBuilder.release.complete();
      await startedManual;
      syncBuilder.release.complete();
      final out = await startedSync;
      await harness.acknowledge(sent, out.results);
    } finally {
      // Whatever failed above, open both gates and let both operations end
      // before the database closes; the original failure is the one reported.
      await settleStarted(
        [manualBuilder.release, syncBuilder.release],
        [manual, sync],
      );
    }

    final identity = (await harness
        .serverRepository
        .publicationIdentityRepository
        .findForContest(contestId))!;
    final current = (await harness
        .serverRepository
        .publicationProjectionRepository
        .findById(identity.currentProjectionId!))!;
    expect(current.configRevision, 2);
    expect(current.clientMutationId, 'auto-sync-drop-rounds');
  });
}
