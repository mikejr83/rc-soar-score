import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../support/fake_gateway.dart';
import '../support/fixtures.dart';

/// The `promote_score` intent travels like any outbox row, but only to a
/// service that lists the capability, and an accepted one is settled by the
/// receipt that comes back inside the adoption's aggregate.
void main() {
  Rig capable() {
    final rig = Rig();
    rig.gateway.info = infoWithPromotion();
    return rig;
  }

  test('a service without the capability never receives the intent', () async {
    final rig = Rig();
    rig.store.mutations
      ..add(intent(1))
      ..add(mutation(2));
    rig.gateway.onExchange = (request) async => request.mutations.isEmpty
        ? FakeGateway.response()
        : FakeGateway.response(results: [accepted('m-2', 3)]);

    expect(await rig.engine.syncScope(scope), isNull);

    final sent = rig.gateway.exchanges.expand((r) => r.mutations);
    expect(sent.map((m) => m.clientMutationId), ['m-2']);
    final held = rig.store.mutations.firstWhere(
      (m) => m.entityType == promotionReceiptEntityType,
    );
    expect(held.outcome, MutationOutcome.pending);
    final state = rig.engine.state.scopes[scope]!;
    expect(state.waitingForNewerService, 1);
    expect(state.pendingMutations, 1);
  });

  test('with only an intent waiting, nothing is pushed at all', () async {
    final rig = Rig();
    rig.store.mutations.add(intent(1));

    expect(await rig.engine.syncScope(scope), isNull);

    expect(rig.gateway.exchanges.every((r) => r.mutations.isEmpty), isTrue);
    expect(rig.engine.state.scopes[scope]!.waitingForNewerService, 1);
  });

  test('the intent is sent once the service lists the capability', () async {
    final rig = capable();
    rig.store.mutations.add(intent(1));
    rig.gateway.onExchange = (request) async => request.mutations.isEmpty
        ? FakeGateway.response()
        : FakeGateway.response(
            results: [accepted('p-1', 12)],
            changes: adoption(1, from: 10),
          );

    expect(await rig.engine.syncScope(scope), isNull);

    final sent = rig.gateway.exchanges.expand((r) => r.mutations).single;
    expect(sent.entityType, promotionReceiptEntityType);
    expect(sent.entityId, idN(5001));
    expect(rig.engine.state.scopes[scope]!.waitingForNewerService, 0);
  });

  test(
    'the receipt settles the intent with the rest of the aggregate',
    () async {
      final rig = capable();
      rig.store.mutations.add(intent(1));
      rig.gateway.onExchange = (request) async => request.mutations.isEmpty
          ? FakeGateway.response()
          : FakeGateway.response(
              results: [accepted('p-1', 12)],
              changes: adoption(1, from: 10),
            );

      await rig.engine.syncScope(scope);

      // One aggregate, applied together, in sequence order.
      expect(rig.applier.aggregates, hasLength(1));
      expect(rig.applier.aggregates.single.map((c) => c.sequence), [
        10,
        11,
        12,
      ]);
      expect(
        rig.applier.aggregates.single.last.entityType,
        promotionReceiptEntityType,
      );
      final settled = rig.store.mutations.single;
      expect(settled.outcome, MutationOutcome.accepted);
      expect(settled.sequence, 12);
      // The intent was not settled before its adoption was applied: the
      // engine's own result handling leaves an accepted intent pending.
      final apply = rig.log.indexOf('receipt:12');
      final settle = rig.log.indexOf('settle:12');
      expect(settle, greaterThan(apply));
      expect(rig.log.where((e) => e == 'outcome:accepted'), isEmpty);
      expect(rig.store.cursors[scope], 12);
    },
  );

  test('an aggregate that fails to apply keeps the intent pending', () async {
    final rig = capable();
    rig.store.mutations.add(intent(1));
    rig.applier.failAggregateOnSequence = 11;
    rig.gateway.onExchange = (request) async => request.mutations.isEmpty
        ? FakeGateway.response()
        : FakeGateway.response(
            results: [accepted('p-1', 12)],
            changes: adoption(1, from: 10),
          );

    await expectLater(rig.engine.syncScope(scope), throwsStateError);

    expect(rig.store.mutations.single.outcome, MutationOutcome.pending);
    expect(rig.store.cursors[scope] ?? 0, 0);
  });

  test('a repeated sync after a crash is healed by the pull', () async {
    // The service committed the adoption, but the client died before it heard
    // the answer: the intent is still pending and the next pull returns the
    // receipt, so the intent is settled without a new decision.
    final rig = capable();
    rig.store.mutations.add(intent(1));
    rig.gateway.onExchange = (request) async => request.mutations.isEmpty
        ? FakeGateway.response(
            changes: adoption(1, from: 10),
            serverSequence: 12,
          )
        : FakeGateway.response(results: [accepted('p-1', 12)]);

    await rig.engine.syncScope(scope);

    expect(rig.store.mutations.single.outcome, MutationOutcome.accepted);
    expect(rig.store.mutations.single.sequence, 12);
    expect(rig.applier.aggregates, hasLength(1));
  });

  test('plain changes keep applying one by one', () async {
    final rig = capable();
    rig.gateway.onExchange = (request) async =>
        FakeGateway.response(changes: [change(1), change(2)]);

    await rig.engine.syncScope(scope);

    expect(rig.applier.aggregates, isEmpty);
    expect(rig.applier.applied.map((c) => c.sequence), [1, 2]);
  });

  test(
    'an accepted intent whose receipt never came is settled from the answer',
    () async {
      final rig = capable();
      rig.store.mutations.add(intent(1));
      rig.gateway.onExchange = (request) async => request.mutations.isEmpty
          ? FakeGateway.response()
          // The answer says accepted at 5, and the pull has passed 5, yet no
          // receipt came in the changes.
          : FakeGateway.response(
              results: [accepted('p-1', 5)],
              changes: [change(5)],
            );

      await rig.engine.syncScope(scope);

      expect(rig.store.mutations.single.outcome, MutationOutcome.accepted);
      expect(rig.store.mutations.single.sequence, 5);
    },
  );

  test('a refusal is final and keeps its reason', () async {
    final rig = capable();
    rig.store.mutations.add(intent(1));
    rig.gateway.onExchange = (request) async => request.mutations.isEmpty
        ? FakeGateway.response()
        : FakeGateway.response(
            results: [
              SyncMutationResult(
                clientMutationId: 'p-1',
                outcome: MutationOutcome.rejected,
                reasonCode: SyncReasonCode.staleSource.code,
              ),
            ],
          );

    await rig.engine.syncScope(scope);

    final refused = rig.store.mutations.single;
    expect(refused.outcome, MutationOutcome.rejected);
    expect(refused.reasonCode, 'stale_source');
    expect(rig.engine.state.scopes[scope]!.pendingMutations, 0);
    expect(rig.engine.state.scopes[scope]!.rejectedMutations, 1);
  });

  test('a refusal as unknown from a service that dropped the capability holds the intent back', () async {
    final rig = capable();
    rig.store.mutations.add(intent(1));
    rig.gateway.onExchange = (request) async {
      if (request.mutations.isEmpty) return FakeGateway.response();
      // The service was replaced by an older one: it lists nothing now and
      // refuses the unknown entity type.
      rig.gateway.info = SyncInfoDto(
        protocolVersion: 1,
        minProtocolVersion: 1,
        minSchemaVersion: 1,
        maxSchemaVersion: 1,
        serverTime: DateTime.utc(2026, 10, 13),
      );
      return FakeGateway.response(
        results: [
          SyncMutationResult(
            clientMutationId: 'p-1',
            outcome: MutationOutcome.rejected,
            reasonCode: SyncReasonCode.invalidPayload.code,
          ),
        ],
      );
    };

    await rig.engine.syncScope(scope);

    expect(rig.store.mutations.single.outcome, MutationOutcome.pending);
    // The next sync does not send it again.
    final before = rig.gateway.exchanges.expand((r) => r.mutations).length;
    await rig.engine.syncScope(scope);
    expect(rig.gateway.exchanges.expand((r) => r.mutations).length, before);
  });

  test(
    'invalid_payload from a service that lists the capability is final',
    () async {
      final rig = capable();
      rig.store.mutations.add(intent(1));
      rig.gateway.onExchange = (request) async => request.mutations.isEmpty
          ? FakeGateway.response()
          : FakeGateway.response(
              results: [
                SyncMutationResult(
                  clientMutationId: 'p-1',
                  outcome: MutationOutcome.rejected,
                  reasonCode: SyncReasonCode.invalidPayload.code,
                ),
              ],
            );

      await rig.engine.syncScope(scope);

      expect(rig.store.mutations.single.outcome, MutationOutcome.rejected);
      expect(rig.store.mutations.single.reasonCode, 'invalid_payload');
    },
  );

  test(
    'an intent restarts: the stored id is sent again, never a new one',
    () async {
      final rig = capable();
      rig.store.mutations.add(intent(1));
      rig.gateway.onExchange = (request) async {
        if (request.mutations.isEmpty) return FakeGateway.response();
        throw httpError(503);
      };

      await rig.engine.syncScope(scope);
      await rig.engine.syncScope(scope);

      final sent = [
        for (final r in rig.gateway.exchanges)
          for (final m in r.mutations) (m.clientMutationId, m.entityId),
      ];
      expect(sent, hasLength(2));
      expect(sent.toSet(), hasLength(1));
      expect(rig.store.mutations.single.outcome, MutationOutcome.pending);
    },
  );
}
