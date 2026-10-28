import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// A pilot with no scores removed on a client: the deletions of their slots,
/// matrix rows and participation reach the server in the order they were made.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;
  late core.ContestScopeKey scope;

  setUp(() async {
    harness = await AcceptorHarness.open(backend);
    contestId = await harness.drawContestOnClient();
    scope = core.ContestScopeKey(contestId);
    await harness.uploadAll(contestId);
  });
  tearDown(() => harness.close());

  Future<int> serverCount(String table) => harness.server.count(table);

  test('the server removes the rows with the pilot', () async {
    final pilot =
        (await harness.clientRepository.contestParticipationRepository
                .listForContest(contestId))
            .first;
    final assignments = await serverCount('matrix_assignments');
    final placeholders = await serverCount('score_placeholders');

    final removed = await ParticipationsService(harness.clientRepository)
        .remove(
          contestId,
          pilot.id,
          metadata: core.MutationMetadata(
            clientMutationId: 'remove-1',
            authority: core.Authority.director,
            clientTime: DateTime.utc(2026, 10, 14),
            actorId: harness.account,
          ),
        );
    final pending = await harness.client.syncStore.pendingMutations(scope);
    final out = await harness.exchange(
      scope,
      mutations: [for (final m in pending) AcceptorHarness.toMutation(m)],
    );

    expect(removed, 2);
    expect(
      out.results.map((r) => r.outcome),
      everyElement(core.MutationOutcome.accepted),
    );
    expect(await serverCount('matrix_assignments'), assignments - 2);
    expect(await serverCount('score_placeholders'), placeholders - 2);
    expect(await harness.stored('ContestParticipation', pilot.id), isNull);
  });

  /// Removes the first pilot on the client and returns what it queued.
  Future<List<core.MutationRecord>> removePilot() async {
    final pilot =
        (await harness.clientRepository.contestParticipationRepository
                .listForContest(contestId))
            .first;
    await ParticipationsService(harness.clientRepository).remove(
      contestId,
      pilot.id,
      metadata: core.MutationMetadata(
        clientMutationId: 'remove-guard',
        authority: core.Authority.director,
        clientTime: DateTime.utc(2026, 10, 14),
        actorId: harness.account,
      ),
    );
    return harness.client.syncStore.pendingMutations(scope);
  }

  test('a matrix row is refused when its score slot still exists', () async {
    final assignments = await serverCount('matrix_assignments');
    final pending = await removePilot();
    final rowsOnly = [
      for (final m in pending)
        if (m.entityType == 'MatrixAssignment') AcceptorHarness.toMutation(m),
    ];

    final out = await harness.exchange(scope, mutations: rowsOnly);

    expect(rowsOnly, isNotEmpty);
    expect(
      out.results.map((r) => r.outcome),
      everyElement(core.MutationOutcome.rejected),
    );
    expect(
      out.results.map((r) => r.reasonCode),
      everyElement(core.SyncReasonCode.locked.code),
    );
    expect(await serverCount('matrix_assignments'), assignments);
  });

  test('a matrix row is refused unless a director removes it', () async {
    final assignments = await serverCount('matrix_assignments');
    final pending = await removePilot();
    final mutations = [
      for (final m in pending)
        if (m.entityType == 'MatrixAssignment')
          SyncMutation(
            id: m.id,
            clientMutationId: m.clientMutationId,
            entityType: m.entityType,
            entityId: m.entityId,
            baseRevision: m.baseRevision,
            authority: core.Authority.helper,
            clientTime: m.clientTime,
            dependsOnMutationId: m.dependsOnMutationId,
            payload: m.payload,
          )
        else
          AcceptorHarness.toMutation(m),
    ];

    final out = await harness.exchange(scope, mutations: mutations);
    final refused = out.results.where(
      (r) => r.outcome == core.MutationOutcome.rejected,
    );

    expect(refused, isNotEmpty);
    expect(await serverCount('matrix_assignments'), assignments);
  });
}
