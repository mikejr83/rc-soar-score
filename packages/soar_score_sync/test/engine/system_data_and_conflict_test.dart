import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_sync/soar_score_sync.dart';
import 'package:test/test.dart';

import '../support/fake_gateway.dart';
import '../support/fixtures.dart';

void main() {
  group('system data', () {
    test('pulls after the stored position and stores each page', () async {
      final rig = Rig();
      rig.store.cursors[const SystemScopeKey()] = 4;
      rig.gateway.onSystemData = (after, token) async => token == null
          ? SystemDataResponse(
              changes: [change(5), change(6)],
              systemDataSeq: 6,
              nextPageToken: 't',
            )
          : SystemDataResponse(changes: [change(7)], systemDataSeq: 7);

      expect(await rig.engine.syncSystemData(), isNull);

      expect(rig.applier.applied.map((c) => c.sequence), [5, 6, 7]);
      expect(rig.applier.applied.first.scope, const SystemScopeKey());
      expect(rig.store.cursors[const SystemScopeKey()], 7);
      expect(rig.log.where((e) => e.startsWith('system')).toList(), [
        'system:4',
        'system:6',
      ]);
    });

    test('a failure is reported, not thrown', () async {
      final rig = Rig();
      rig.gateway.onSystemData = (_, _) async => throw httpError(500);

      expect(await rig.engine.syncSystemData(), SyncFailureKind.serverError);
    });
  });

  group('conflict resolution', () {
    test(
      'sends the choice, then syncs the scope to store the answer',
      () async {
        final rig = Rig();

        final outcome = await rig.engine.resolveConflict(
          scope,
          idN(77),
          clientMutationId: 'r-1',
          choice: ConflictResolutionChoice.merged,
          payload: {'time_flown': 545},
        );

        expect(outcome.failure, isNull);
        expect(outcome.accepted, isTrue);
        expect(
          rig.gateway.resolutions.single.choice,
          ConflictResolutionChoice.merged,
        );
        expect(rig.gateway.resolutions.single.payload, {'time_flown': 545});
        expect(
          rig.log.indexOf('resolve'),
          lessThan(rig.log.indexOf('exchange:0')),
        );
      },
    );

    test('a failed resolution is reported and nothing else is sent', () async {
      final rig = Rig();
      rig.gateway.resolveError = httpError(401);

      final outcome = await rig.engine.resolveConflict(
        scope,
        idN(77),
        clientMutationId: 'r-2',
        choice: ConflictResolutionChoice.keptAccepted,
      );

      expect(outcome.failure, SyncFailureKind.tokenExpired);
      expect(outcome.accepted, isFalse);
      expect(rig.gateway.exchanges, isEmpty);
      expect(
        rig.engine.state.scopes[scope]!.failure,
        SyncFailureKind.tokenExpired,
      );
    });

    for (final outcome in [
      MutationOutcome.rejected,
      MutationOutcome.conflict,
      MutationOutcome.skipped,
    ]) {
      test('a $outcome answer is not success and is not synced', () async {
        final rig = Rig();
        rig.gateway.resolveResult = SyncMutationResult(
          clientMutationId: 'r-3',
          outcome: outcome,
          reasonCode: 'stale_base',
        );

        final result = await rig.engine.resolveConflict(
          scope,
          idN(77),
          clientMutationId: 'r-3',
          choice: ConflictResolutionChoice.keptAccepted,
        );

        expect(result.accepted, isFalse);
        expect(result.failure, isNull);
        expect(result.reason, SyncReasonCode.staleBase);
        expect(rig.gateway.exchanges, isEmpty);
      });
    }
  });
}
