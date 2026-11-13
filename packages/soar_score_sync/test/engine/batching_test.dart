import 'dart:convert';

import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_sync/soar_score_sync.dart';
import 'package:test/test.dart';

import '../support/fake_gateway.dart';
import '../support/fixtures.dart';

/// Accepts every mutation it is sent, with rising sequences.
Future<SyncExchangeResponse> Function(SyncExchangeRequest) acceptAll() {
  var sequence = 0;
  return (request) async => FakeGateway.response(
    results: [
      for (final m in request.mutations)
        accepted(m.clientMutationId, ++sequence),
    ],
    serverSequence: sequence,
  );
}

MutationRecord creation({Map<String, Object?>? payload}) => MutationRecord(
  id: idN(1),
  contestId: contestId,
  entityType: 'Contest',
  entityId: contestId,
  clientMutationId: 'create',
  authority: Authority.director,
  clientTime: DateTime.utc(2026, 10, 13, 11),
  payload: payload ?? {'name': 'Open'},
);

void main() {
  test('the mutation limit cuts a push into exchanges', () async {
    final rig = Rig(maxMutations: 2);
    for (var n = 1; n <= 5; n++) {
      rig.store.mutations.add(mutation(n));
    }
    rig.gateway.onExchange = acceptAll();

    expect(await rig.engine.syncScope(scope), isNull);

    expect(rig.gateway.exchanges.map((r) => r.mutations.length), [0, 2, 2, 1]);
    expect(
      rig.store.mutations.every((m) => m.outcome == MutationOutcome.accepted),
      isTrue,
    );
    expect(rig.gateway.exchanges.every((r) => r.firstUpload == null), isTrue);
  });

  test('the byte limit counts the whole request, in bytes', () async {
    // Multibyte text: 4 characters are 12 bytes.
    final payload = {'note': '日本語日'};
    final probe = Rig();
    final envelope = utf8
        .encode(
          jsonEncode(
            SyncExchangeRequest(
              protocolVersion: 1,
              schemaVersion: 1,
              installationId: installationId,
              scope: SyncScopeDto.contest(contestId),
              lastAcknowledgedSequence: 0,
              firstUpload: 'open',
            ).toJson(),
          ),
        )
        .length;
    final each = utf8
        .encode(jsonEncode(mutationToDtoForTest(mutation(1, payload: payload))))
        .length;
    probe.engine.dispose();

    // Room for two mutations and their comma, not three.
    final maxBytes = envelope + exchangeEnvelopeMargin + 2 * each + 1;
    final rig = Rig(maxBytes: maxBytes);
    for (var n = 1; n <= 5; n++) {
      rig.store.mutations.add(mutation(n, payload: payload));
    }
    rig.gateway.onExchange = acceptAll();

    await rig.engine.syncScope(scope);

    final sizes = [
      for (final r in rig.gateway.exchanges.skip(1))
        utf8.encode(jsonEncode(r.toJson())).length,
    ];
    expect(rig.gateway.exchanges.map((r) => r.mutations.length), [0, 2, 2, 1]);
    expect(sizes.every((s) => s <= maxBytes), isTrue);
  });

  test('a mutation too large alone stays rejected, not retried', () async {
    final rig = Rig(maxBytes: 4000);
    rig.store.mutations
      ..add(mutation(1))
      ..add(mutation(2, payload: {'blob': 'x' * 5000}))
      ..add(mutation(3));
    rig.gateway.onExchange = acceptAll();

    await rig.engine.syncScope(scope);
    await rig.engine.syncScope(scope);

    final big = rig.store.mutations.firstWhere(
      (m) => m.clientMutationId == 'm-2',
    );
    expect(big.outcome, MutationOutcome.rejected);
    expect(big.reasonCode, 'payload_too_large');
    final sent = [for (final r in rig.gateway.exchanges) ...r.mutations]
        .map((m) => m.clientMutationId);
    expect(sent, ['m-1', 'm-3']);
  });

  test('a dependent of a failed prerequisite stays pending', () async {
    final rig = Rig(maxMutations: 1);
    final first = mutation(1);
    rig.store.mutations
      ..add(first)
      ..add(mutation(2, dependsOn: first.id))
      ..add(mutation(3));
    rig.gateway.onExchange = (request) async => FakeGateway.response(
      results: [
        for (final m in request.mutations)
          m.clientMutationId == 'm-1'
              ? SyncMutationResult(
                  clientMutationId: 'm-1',
                  outcome: MutationOutcome.rejected,
                  reasonCode: 'stale_base',
                )
              : accepted(m.clientMutationId, 5),
      ],
    );

    await rig.engine.syncScope(scope);

    final sent = [for (final r in rig.gateway.exchanges) ...r.mutations]
        .map((m) => m.clientMutationId);
    expect(sent, ['m-1', 'm-3']);
    MutationOutcome outcomeOf(String id) =>
        rig.store.mutations.firstWhere((m) => m.clientMutationId == id).outcome;
    expect(outcomeOf('m-1'), MutationOutcome.rejected);
    expect(outcomeOf('m-2'), MutationOutcome.pending);
    expect(outcomeOf('m-3'), MutationOutcome.accepted);
  });

  test('a lost response leaves the next batches for the next sync', () async {
    final rig = Rig(maxMutations: 2);
    for (var n = 1; n <= 4; n++) {
      rig.store.mutations.add(mutation(n));
    }
    final answer = acceptAll();
    var pushes = 0;
    rig.gateway.onExchange = (request) async {
      if (request.mutations.isNotEmpty && ++pushes == 2) {
        throw ApiNetworkError(
          'connection lost',
          requestUri: Uri.parse('http://localhost/x'),
        );
      }
      return answer(request);
    };

    expect(await rig.engine.syncScope(scope), SyncFailureKind.offline);
    expect(rig.store.mutations.map((m) => m.outcome), [
      MutationOutcome.accepted,
      MutationOutcome.accepted,
      MutationOutcome.pending,
      MutationOutcome.pending,
    ]);

    expect(await rig.engine.syncScope(scope), isNull);
    expect(
      rig.store.mutations.every((m) => m.outcome == MutationOutcome.accepted),
      isTrue,
    );
    final resent = rig.gateway.exchanges.last.mutations.map(
      (m) => m.clientMutationId,
    );
    expect(resent, ['m-3', 'm-4']);
  });

  test('a refusal from an earlier sync still blocks its dependent', () async {
    final rig = Rig();
    final first = mutation(1);
    final refused = MutationRecord.fromJson({
      ...first.toJson(),
      'outcome': 'Rejected',
      'reason_code': 'stale_base',
    });
    rig.store.mutations
      ..add(refused)
      ..add(mutation(2, dependsOn: first.id))
      ..add(mutation(3));
    rig.gateway.onExchange = acceptAll();

    await rig.engine.syncScope(scope);
    await rig.engine.syncScope(scope);

    final sent = [for (final r in rig.gateway.exchanges) ...r.mutations]
        .map((m) => m.clientMutationId);
    expect(sent, ['m-3']);
    expect(
      rig.store.mutations
          .firstWhere((m) => m.clientMutationId == 'm-2')
          .outcome,
      MutationOutcome.pending,
    );
  });

  test('a mutation that fits only without the margin is still sent', () async {
    final payload = {'blob': 'x' * 2000};
    final probe = Rig();
    final solo = utf8
        .encode(
          jsonEncode(
            SyncExchangeRequest(
              protocolVersion: 1,
              schemaVersion: 1,
              installationId: installationId,
              scope: SyncScopeDto.contest(contestId),
              lastAcknowledgedSequence: 0,
              mutations: [
                SyncMutationDto.fromJson(
                  mutationToDtoForTest(mutation(1, payload: payload)),
                ),
              ],
              firstUpload: 'open',
            ).toJson(),
          ),
        )
        .length;
    probe.engine.dispose();
    // Fits the limit exactly, but not with the batching margin.
    final rig = Rig(maxBytes: solo + 10);
    rig.store.mutations.add(mutation(1, payload: payload));
    rig.gateway.onExchange = acceptAll();

    await rig.engine.syncScope(scope);

    expect(rig.store.mutations.single.outcome, MutationOutcome.accepted);
    expect(
      rig.gateway.exchanges.expand((r) => r.mutations).single.clientMutationId,
      'm-1',
    );
  });

  test('an ordinary push is measured without the first-upload flag', () async {
    final payload = {'blob': 'x' * 2000};
    // The request this sync really sends: no first_upload at all.
    final exact = utf8
        .encode(
          jsonEncode(
            SyncExchangeRequest(
              protocolVersion: 1,
              schemaVersion: 1,
              installationId: installationId,
              scope: SyncScopeDto.contest(contestId),
              lastAcknowledgedSequence: 0,
              mutations: [
                SyncMutationDto.fromJson(
                  mutationToDtoForTest(mutation(1, payload: payload)),
                ),
              ],
            ).toJson(),
          ),
        )
        .length;
    final rig = Rig(maxBytes: exact);
    rig.store.mutations.add(mutation(1, payload: payload));
    rig.gateway.onExchange = acceptAll();

    await rig.engine.syncScope(scope);

    expect(rig.store.mutations.single.outcome, MutationOutcome.accepted);
    final sent = rig.gateway.exchanges.last;
    expect(utf8.encode(jsonEncode(sent.toJson())).length, exact);
  });

  group('first upload of a contest', () {
    test('every batch says so and the creation is decided last', () async {
      final rig = Rig(maxMutations: 2);
      rig.store.mutations
        ..add(creation())
        ..add(mutation(1))
        ..add(mutation(2))
        ..add(mutation(3));
      rig.gateway.onExchange = acceptAll();

      await rig.engine.syncScope(scope);

      final pushes = rig.gateway.exchanges.where((r) => r.mutations.isNotEmpty);
      expect(pushes.map((r) => r.mutations.length), [2, 2]);
      expect(pushes.every((r) => r.firstUpload == 'open'), isTrue);
      expect(
        rig.store.mutations.every((m) => m.outcome == MutationOutcome.accepted),
        isTrue,
      );
      // The creation's own outcome came after every other one, and the
      // service was told the upload is finished before that.
      final outcomes = rig.log.where((e) => e.startsWith('outcome:')).length;
      expect(outcomes, 4);
      final finish = rig.gateway.exchanges.where(
        (r) => r.firstUpload == 'finish',
      );
      expect(finish, hasLength(1));
      expect(finish.single.mutations, isEmpty);
      expect(rig.gateway.exchanges.last.firstUpload, 'finish');
    });

    test('an upload with a mutation still pending is not finished', () async {
      final rig = Rig(maxMutations: 2);
      final first = mutation(1);
      rig.store.mutations
        ..add(creation())
        ..add(first)
        ..add(mutation(2, dependsOn: first.id));
      rig.gateway.onExchange = (request) async => FakeGateway.response(
        results: [
          for (final m in request.mutations)
            m.clientMutationId == 'm-1'
                ? SyncMutationResult(
                    clientMutationId: 'm-1',
                    outcome: MutationOutcome.skipped,
                    reasonCode: 'dependency_failed',
                  )
                : accepted(m.clientMutationId, 3),
        ],
      );

      await rig.engine.syncScope(scope);

      expect(
        rig.gateway.exchanges.any((r) => r.firstUpload == 'finish'),
        isFalse,
      );
      expect(
        rig.store.mutations
            .firstWhere((m) => m.clientMutationId == 'create')
            .outcome,
        MutationOutcome.pending,
      );
    });

    test('a refused mutation does not keep the upload open', () async {
      final rig = Rig(maxMutations: 2);
      rig.store.mutations
        ..add(creation())
        ..add(mutation(1))
        ..add(mutation(2));
      rig.gateway.onExchange = (request) async => FakeGateway.response(
        results: [
          for (final m in request.mutations)
            m.clientMutationId == 'm-1'
                ? SyncMutationResult(
                    clientMutationId: 'm-1',
                    outcome: MutationOutcome.rejected,
                    reasonCode: 'invalid_payload',
                  )
                : accepted(m.clientMutationId, 3),
        ],
      );

      await rig.engine.syncScope(scope);

      expect(rig.gateway.exchanges.last.firstUpload, 'finish');
      expect(
        rig.store.mutations
            .firstWhere((m) => m.clientMutationId == 'create')
            .outcome,
        MutationOutcome.accepted,
      );
    });

    test(
      'an interrupted upload still has its creation to send again',
      () async {
        final rig = Rig(maxMutations: 2);
        rig.store.mutations
          ..add(creation())
          ..add(mutation(1))
          ..add(mutation(2))
          ..add(mutation(3));
        final answer = acceptAll();
        var pushes = 0;
        rig.gateway.onExchange = (request) async {
          if (request.mutations.isNotEmpty && ++pushes == 2) {
            throw ApiNetworkError(
              'connection lost',
              requestUri: Uri.parse('http://localhost/x'),
            );
          }
          return answer(request);
        };

        expect(await rig.engine.syncScope(scope), SyncFailureKind.offline);
        expect(
          rig.store.mutations
              .firstWhere((m) => m.clientMutationId == 'create')
              .outcome,
          MutationOutcome.pending,
        );

        expect(await rig.engine.syncScope(scope), isNull);
        final sentPushes = rig.gateway.exchanges.where(
          (r) => r.mutations.isNotEmpty,
        );
        final withCreation = sentPushes.where(
          (r) => r.mutations.any((m) => m.clientMutationId == 'create'),
        );
        expect(withCreation, hasLength(2));
        expect(sentPushes.every((r) => r.firstUpload == 'open'), isTrue);
        expect(
          rig.store.mutations.every(
            (m) => m.outcome == MutationOutcome.accepted,
          ),
          isTrue,
        );
      },
    );

    test('an ordinary push does not claim to be a first upload', () async {
      final rig = Rig();
      rig.store.mutations.add(mutation(1));
      rig.gateway.onExchange = acceptAll();

      await rig.engine.syncScope(scope);

      expect(rig.gateway.exchanges.last.firstUpload, isNull);
    });
  });
}

Map<String, Object?> mutationToDtoForTest(MutationRecord m) => SyncMutationDto(
  id: m.id,
  clientMutationId: m.clientMutationId,
  entityType: m.entityType,
  entityId: m.entityId,
  baseRevision: m.baseRevision,
  authority: m.authority,
  clientTime: m.clientTime,
  dependsOnMutationId: m.dependsOnMutationId,
  payload: m.payload,
).toJson();
