import 'dart:async';

import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_sync/soar_score_sync.dart';
import 'package:test/test.dart';

import '../support/fake_gateway.dart';
import '../support/fixtures.dart';

SyncRefusedError refused(SyncReasonCode reason, int status) => SyncRefusedError(
  'refused',
  reason: reason,
  statusCode: status,
  body: '',
  requestUri: Uri.parse('http://localhost/x'),
);

void main() {
  Rig rigWithPending() {
    final rig = Rig();
    rig.store.mutations.add(mutation(1));
    return rig;
  }

  Future<void> expectFailure(
    Object error,
    SyncFailureKind kind, {
    bool fromInfo = false,
  }) async {
    final rig = rigWithPending();
    rig.gateway.onExchange = (_) async => throw error;

    expect(await rig.engine.syncScope(scope), kind);

    final state = rig.engine.state.scopes[scope]!;
    expect(state.failure, kind);
    // Local data is untouched: the mutation is still waiting.
    expect(state.pendingMutations, 1);
    expect(rig.store.mutations.single.outcome, MutationOutcome.pending);
  }

  test('no response is offline', () async {
    await expectFailure(
      ApiNetworkError('down', requestUri: _uri),
      SyncFailureKind.offline,
    );
  });

  test('a 401 is an expired token', () async {
    await expectFailure(httpError(401), SyncFailureKind.tokenExpired);
  });

  test('a 5xx is a server error', () async {
    await expectFailure(httpError(500), SyncFailureKind.serverError);
  });

  test('an unreadable answer is a server error', () async {
    await expectFailure(
      ApiException('bad body', requestUri: _uri),
      SyncFailureKind.serverError,
    );
  });

  test('schema_too_old needs an update', () async {
    await expectFailure(
      refused(SyncReasonCode.schemaTooOld, 426),
      SyncFailureKind.updateRequired,
    );
  });

  test('inactive_installation is reported as such', () async {
    await expectFailure(
      refused(SyncReasonCode.inactiveInstallation, 403),
      SyncFailureKind.inactiveInstallation,
    );
  });

  test(
    'a version outside the service range stops before any exchange',
    () async {
      final rig = rigWithPending();
      rig.gateway.info = SyncInfoDto(
        protocolVersion: 1,
        minProtocolVersion: 1,
        minSchemaVersion: 2,
        maxSchemaVersion: 3,
        serverTime: DateTime.utc(2026, 10, 13),
      );

      expect(await rig.engine.syncScope(scope), SyncFailureKind.updateRequired);

      expect(rig.gateway.exchanges, isEmpty);
      expect(rig.gateway.registrations, isEmpty);
    },
  );

  test('a failed registration is a failure, not a crash', () async {
    final rig = rigWithPending();
    rig.gateway.registerError = ApiNetworkError('down', requestUri: _uri);

    expect(await rig.engine.syncScope(scope), SyncFailureKind.offline);
    expect(rig.gateway.exchanges, isEmpty);
  });

  test('the next sync after a failure clears it', () async {
    final rig = rigWithPending();
    var fail = true;
    rig.gateway.onExchange = (request) async {
      if (fail) throw httpError(500);
      return FakeGateway.response(
        results: request.mutations.isEmpty ? [] : [accepted('m-1', 2)],
      );
    };

    await rig.engine.syncScope(scope);
    expect(
      rig.engine.state.scopes[scope]!.failure,
      SyncFailureKind.serverError,
    );

    fail = false;
    expect(await rig.engine.syncScope(scope), isNull);
    expect(rig.engine.state.scopes[scope]!.failure, isNull);
    expect(rig.engine.state.scopes[scope]!.pendingMutations, 0);
  });

  test('an accountless contest is not synced and says why', () async {
    final rig = Rig(syncable: (_) => false);
    rig.store.mutations.add(mutation(1));

    expect(await rig.engine.syncScope(scope), isNull);

    expect(rig.gateway.exchanges, isEmpty);
    expect(rig.gateway.infoCalls, 0);
    final state = rig.engine.state.scopes[scope]!;
    expect(state.skipReason, SyncSkipReason.accountless);
    expect(state.pendingMutations, 1);
  });

  test('the state stream reports syncing and the result', () async {
    final rig = rigWithPending();
    final seen = <SyncState>[];
    final subscription = rig.engine.states.listen(seen.add);
    addTearDown(subscription.cancel);

    await rig.engine.syncScope(scope);
    await Future<void>.delayed(Duration.zero);

    expect(seen.first.syncing, isTrue);
    expect(seen.last.syncing, isFalse);
    expect(seen.last.scopes[scope], isNotNull);
  });

  test('syncs of one engine run one after another', () async {
    final rig = Rig();
    final release = Completer<void>();
    var running = 0;
    var peak = 0;
    rig.gateway.onExchange = (_) async {
      running++;
      if (running > peak) peak = running;
      await release.future;
      running--;
      return FakeGateway.response();
    };

    final first = rig.engine.syncScope(scope);
    final second = rig.engine.syncScope(scope);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    release.complete();
    await Future.wait([first, second]);

    expect(peak, 1);
  });
}

final _uri = Uri.parse('http://localhost/x');
