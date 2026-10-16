import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/engine_app_sync.dart';
import 'package:soar_score_contest/services/sync/open_conflict.dart';
import 'package:soar_score_contest/services/sync/sync_problem.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_sync/soar_score_sync.dart';

final _scope = core.ContestScopeKey(
  core.Id.parse('019c0000-0000-7000-8000-000000000020'),
);
final _conflict = OpenConflict(
  id: core.Id.parse('019c0000-0000-7000-8000-000000000030'),
  entityType: 'OfficialScore',
  entityId: core.Id.parse('019c0000-0000-7000-8000-000000000031'),
  createdAt: DateTime.utc(2026, 10, 13),
);

/// Only what a conflict decision and the sync after it touch.
class _Store implements core.SyncStore {
  @override
  Future<List<core.MutationRecord>> pendingMutations(
    core.SyncScopeKey scope,
  ) async => const [];

  @override
  Future<List<core.MutationRecord>> rejectedMutations(
    core.SyncScopeKey scope,
  ) async => const [];

  @override
  Future<core.SyncStatus> status(core.SyncScopeKey scope) async =>
      const core.SyncStatus(
        pendingMutations: 0,
        conflictsNeedingAction: 1,
        rejectedMutations: 0,
        lastSyncedSequence: 0,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Applier implements core.ReplicatedChangeApplier {
  @override
  Future<void> apply(core.ReplicatedChange change) async {}
}

/// Answers a conflict decision with [answer]; every other call fails as the
/// service being unreachable.
class _Gateway implements SyncGateway {
  _Gateway(this.answer);

  final SyncMutationResult? answer;

  @override
  Future<SyncMutationResult> resolveConflict(
    core.Id conflictId,
    ResolveConflictRequest request, {
    required core.SyncScopeKey scope,
  }) async =>
      answer ??
      SyncMutationResult(
        clientMutationId: request.clientMutationId,
        outcome: core.MutationOutcome.accepted,
        revision: 2,
        sequence: 9,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw ApiHttpError(
    'unavailable',
    statusCode: 503,
    body: '{"error":{"code":"unavailable","message":"m"}}',
    requestUri: Uri.parse('http://localhost/x'),
  );
}

EngineAppSync _sync(_Gateway gateway) => EngineAppSync(
  SyncEngine(
    store: _Store(),
    applier: _Applier(),
    gateway: gateway,
    config: SyncEngineConfig(
      installationId: core.Id.parse('019c0000-0000-7000-8000-000000000070'),
      label: 'Field laptop',
      platform: core.Platform.windows,
      schemaVersion: 1,
    ),
  ),
);

void main() {
  test(
    'an accepted decision is resolved even when the follow-up sync fails',
    () async {
      final sync = _sync(_Gateway(null));
      addTearDown(sync.close);

      final answer = await sync.resolveConflict(
        _scope,
        _conflict,
        core.ConflictResolutionChoice.keptAccepted,
      );

      expect(answer.resolved, isTrue);
      expect(answer.refreshProblem, isNotNull);
      expect(answer.refreshProblem, isA<SyncProblem>());
    },
  );

  test('a decision the service rejects is not resolved and says why', () async {
    final sync = _sync(
      _Gateway(
        SyncMutationResult(
          clientMutationId: 'x',
          outcome: core.MutationOutcome.rejected,
          reasonCode: 'locked',
        ),
      ),
    );
    addTearDown(sync.close);

    final answer = await sync.resolveConflict(
      _scope,
      _conflict,
      core.ConflictResolutionChoice.tookCompeting,
    );

    expect(answer.resolved, isFalse);
    expect(answer.refusal, 'The service did not accept the decision. Locked.');
  });
}
