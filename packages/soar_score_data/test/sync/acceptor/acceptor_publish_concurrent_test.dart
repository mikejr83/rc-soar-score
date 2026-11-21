import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forPostgresOnly(_tests);

/// Two PostgreSQL sessions publish the same contest at once: a manual publish
/// built from the old configuration commits first while the synced
/// configuration edit's publish is already waiting to store. The database
/// compares the publication revision in the update itself, so the sync
/// publish is refused as stale (not by the projection's unique key), rebuilds
/// and leaves the synced configuration public.
void _tests(Backend backend) {
  test('overlapping publishes: the older manual commit does not win', () async {
    final harness = await AcceptorHarness.open(
      backend,
      recalculates: true,
      publishes: true,
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

    // A second, independent session on the same database.
    final manualDb = SoarScoreDatabase(
      postgresConfig!.named(harness.server.databaseName!).toPgDatabase(),
      profile: DatabaseProfile.server,
    );
    addTearDown(manualDb.close);
    final manualRepository = Repository(manualDb);

    // The manual publish stores (the identity row is now locked) and stays
    // uncommitted.
    final observerDb = SoarScoreDatabase(
      postgresConfig!.named(harness.server.databaseName!).toPgDatabase(),
      profile: DatabaseProfile.server,
    );
    addTearDown(observerDb.close);
    late final int manualPid;
    final stored = Completer<void>();
    final commit = Completer<void>();
    final manual = manualDb.transaction(() async {
      await PublicationService(manualRepository).publish(
        contestId,
        actorId: harness.account,
        authority: core.Authority.director,
        clientMutationId: 'manual',
        sourceContestRevision: contest.revision,
      );
      manualPid =
          (await manualDb
                  .customSelect('SELECT pg_backend_pid() AS pid')
                  .getSingle())
              .read<int>('pid');
      stored.complete();
      await commit.future;
    });
    await stored.future;

    // The configuration edit syncs; its publish has to wait for that row.
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
    final sync = harness.exchange(scope, mutations: sent);
    try {
      // PostgreSQL itself says when the sync publish waits on the manual
      // transaction's lock, so the two overlap whatever the runner's speed.
      await _waitUntilBlockedBy(observerDb, manualPid);
    } finally {
      commit.complete();
      await manual;
    }
    final out = await sync;
    await harness.acknowledge(sent, out.results);

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
    expect(current.projectionRevision, 3);
  });
}

/// Polls until a session waits for a lock held by [blockerPid].
Future<void> _waitUntilBlockedBy(
  SoarScoreDatabase observer,
  int blockerPid,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (DateTime.now().isBefore(deadline)) {
    final rows = await observer
        .customSelect(
          'SELECT count(*) AS waiting FROM pg_stat_activity '
          r'WHERE $1 = ANY(pg_blocking_pids(pid))',
          variables: [Variable<int>(blockerPid)],
        )
        .get();
    if (rows.single.read<int>('waiting') > 0) return;
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
  fail('no session waited for the manual publish within 15 seconds');
}
