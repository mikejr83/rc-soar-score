import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_sync/soar_score_sync.dart';
import 'package:test/test.dart';

import '../support/fake_gateway.dart';
import '../support/fixtures.dart';

void main() {
  test('pulls before it pushes', () async {
    final rig = Rig();
    rig.store.mutations.add(mutation(1));
    rig.gateway.onExchange = (request) async => request.mutations.isEmpty
        ? FakeGateway.response(changes: [change(5)], serverSequence: 5)
        : FakeGateway.response(
            results: [accepted('m-1', 6)],
            changes: [change(6)],
          );

    expect(await rig.engine.syncScope(scope), isNull);

    expect(rig.gateway.exchanges.map((r) => r.mutations.length), [0, 1]);
    expect(rig.log, [
      'register',
      'exchange:0',
      'apply:5',
      'cursor:5',
      'exchange:1',
      'outcome:accepted',
      'apply:6',
      'cursor:6',
      'cursor:6',
    ]);
    expect(rig.gateway.exchanges.last.lastAcknowledgedSequence, 5);
  });

  test('checks versions and registers the installation once', () async {
    final rig = Rig();

    await rig.engine.syncScope(scope);
    await rig.engine.syncScope(scope);

    expect(rig.gateway.infoCalls, 1);
    expect(rig.gateway.registrations, hasLength(1));
    expect(rig.gateway.registrations.single.id, installationId);
    expect(rig.gateway.registrations.single.platform, Platform.windows);
  });

  test('sends mutations in dependency order', () async {
    final rig = Rig();
    final matrix = mutation(2);
    rig.store.mutations
      ..add(mutation(1, dependsOn: matrix.id))
      ..add(matrix);

    await rig.engine.syncScope(scope);

    final sent = rig.gateway.exchanges.last.mutations;
    expect(sent.map((m) => m.clientMutationId), ['m-2', 'm-1']);
    expect(sent.last.dependsOnMutationId, matrix.id);
  });

  test('an accepted mutation leaves the outbox with its sequence', () async {
    final rig = Rig();
    rig.store.mutations.add(mutation(1));
    rig.gateway.onExchange = (request) async => request.mutations.isEmpty
        ? FakeGateway.response()
        : FakeGateway.response(results: [accepted('m-1', 7)]);

    await rig.engine.syncScope(scope);

    expect(rig.store.mutations.single.outcome, MutationOutcome.accepted);
    expect(rig.store.mutations.single.sequence, 7);
    expect(rig.engine.state.scopes[scope]!.pendingMutations, 0);
  });

  test(
    'a rejected mutation keeps its reason and does not block siblings',
    () async {
      final rig = Rig();
      rig.store.mutations
        ..add(mutation(1))
        ..add(mutation(2));
      rig.gateway.onExchange = (request) async => request.mutations.isEmpty
          ? FakeGateway.response()
          : FakeGateway.response(
              results: [
                const SyncMutationResult(
                  clientMutationId: 'm-1',
                  outcome: MutationOutcome.rejected,
                  reasonCode: 'locked',
                  currentRevision: 4,
                ),
                accepted('m-2', 8),
              ],
            );

      await rig.engine.syncScope(scope);

      expect(rig.store.mutations[0].outcome, MutationOutcome.rejected);
      expect(rig.store.mutations[0].reasonCode, 'locked');
      expect(rig.store.mutations[1].outcome, MutationOutcome.accepted);
      expect(rig.engine.state.scopes[scope]!.rejectedMutations, 1);
      final rejected = await rig.engine.rejectedMutations(scope);
      expect(rejected.single.clientMutationId, 'm-1');
    },
  );

  test('a conflict is recorded with its reason', () async {
    final rig = Rig();
    rig.store.mutations.add(mutation(1));
    rig.gateway.onExchange = (request) async => request.mutations.isEmpty
        ? FakeGateway.response()
        : FakeGateway.response(
            results: [
              const SyncMutationResult(
                clientMutationId: 'm-1',
                outcome: MutationOutcome.conflict,
                reasonCode: 'stale_base',
                currentRevision: 5,
              ),
            ],
          );

    await rig.engine.syncScope(scope);

    expect(rig.store.mutations.single.outcome, MutationOutcome.conflict);
    expect(rig.store.mutations.single.reasonCode, 'stale_base');
  });

  test('a skipped mutation stays pending and is sent again', () async {
    final rig = Rig();
    rig.store.mutations.add(mutation(1));
    var round = 0;
    rig.gateway.onExchange = (request) async {
      if (request.mutations.isEmpty) return FakeGateway.response();
      round++;
      return FakeGateway.response(
        results: [
          round == 1
              ? const SyncMutationResult(
                  clientMutationId: 'm-1',
                  outcome: MutationOutcome.skipped,
                  reasonCode: 'dependency_failed',
                  dependsOn: 'm-0',
                )
              : accepted('m-1', 3),
        ],
      );
    };

    await rig.engine.syncScope(scope);
    expect(rig.store.mutations.single.outcome, MutationOutcome.pending);

    await rig.engine.syncScope(scope);
    expect(rig.store.mutations.single.outcome, MutationOutcome.accepted);
  });

  test('a repeated sync resends the same client mutation ids', () async {
    final rig = Rig();
    rig.store.mutations.add(mutation(1));
    var calls = 0;
    rig.gateway.onExchange = (request) async {
      if (request.mutations.isEmpty) return FakeGateway.response();
      calls++;
      // The first answer is lost on the way back.
      if (calls == 1) throw httpError(503);
      return FakeGateway.response(results: [accepted('m-1', 4)]);
    };

    expect(await rig.engine.syncScope(scope), SyncFailureKind.serverError);
    expect(await rig.engine.syncScope(scope), isNull);

    final pushes = rig.gateway.exchanges.where((r) => r.mutations.isNotEmpty);
    expect(pushes.map((r) => r.mutations.single.clientMutationId), [
      'm-1',
      'm-1',
    ]);
    expect(rig.store.mutations.single.outcome, MutationOutcome.accepted);
  });

  test('follows page tokens and stores each page before moving on', () async {
    final rig = Rig();
    rig.gateway.onExchange = (request) async {
      if (request.pageToken == null) {
        return FakeGateway.response(
          changes: [change(1), change(2)],
          nextPageToken: 'p2',
        );
      }
      return FakeGateway.response(changes: [change(3)]);
    };

    await rig.engine.syncScope(scope);

    expect(rig.gateway.exchanges.map((r) => r.pageToken), [null, 'p2']);
    expect(
      rig.gateway.exchanges.every((r) => r.lastAcknowledgedSequence == 0),
      isTrue,
    );
    expect(rig.log.where((e) => e.startsWith('cursor')).toList(), [
      'cursor:2',
      'cursor:3',
      'cursor:3',
    ]);
    expect(rig.store.cursors[scope], 3);
  });

  test('the cursor does not move past a change that failed to store', () async {
    final rig = Rig();
    rig.applier.failOnSequence = 2;
    rig.gateway.onExchange = (request) async =>
        FakeGateway.response(changes: [change(1), change(2)]);

    await expectLater(rig.engine.syncScope(scope), throwsStateError);

    expect(rig.store.cursors[scope] ?? 0, 0);
    expect(rig.log, isNot(contains('cursor:2')));
  });

  test(
    'a change the applier has no store for stops the pull, not the app',
    () async {
      final rig = Rig();
      rig.applier.unsupportedOnSequence = 2;
      rig.gateway.onExchange = (request) async =>
          FakeGateway.response(changes: [change(1), change(2)]);

      final failure = await rig.engine.syncScope(scope);

      expect(failure, SyncFailureKind.unsupportedChange);
      expect(rig.store.cursors[scope] ?? 0, 0);
      expect(
        rig.engine.state.scopes[scope]!.failure,
        SyncFailureKind.unsupportedChange,
      );
    },
  );

  test('other argument errors are not reported as unsupported', () async {
    final rig = Rig();
    rig.applier.invalidOnSequence = 1;
    rig.gateway.onExchange = (request) async =>
        FakeGateway.response(changes: [change(1)]);

    await expectLater(
      rig.engine.syncScope(scope),
      throwsA(isA<ArgumentError>()),
    );
    expect(rig.store.cursors[scope] ?? 0, 0);
  });

  test('changes are applied in sequence order', () async {
    final rig = Rig();
    rig.gateway.onExchange = (request) async =>
        FakeGateway.response(changes: [change(3), change(1), change(2)]);

    await rig.engine.syncScope(scope);

    expect(rig.applier.applied.map((c) => c.sequence), [1, 2, 3]);
    expect(rig.applier.applied.first.scope, scope);
  });

  test('a sync with no changes still records the time', () async {
    final rig = Rig();

    await rig.engine.syncScope(scope);

    expect(
      rig.engine.state.scopes[scope]!.lastSyncedAt,
      DateTime.utc(2026, 10, 13, 15),
    );
  });

  test(
    'the state reports the remote sequence and the standing warning',
    () async {
      final rig = Rig();
      rig.gateway.onExchange = (request) async =>
          FakeGateway.response(serverSequence: 57);

      await rig.engine.syncScope(scope);

      expect(rig.engine.state.scopes[scope]!.remoteSequence, 57);
      expect(rig.engine.state.warnUnrecoverableChanges, isTrue);
      expect(rig.engine.state.installationId, installationId);
    },
  );
}
