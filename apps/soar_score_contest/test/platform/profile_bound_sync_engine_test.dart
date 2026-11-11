import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/acting_account.dart';
import 'package:soar_score_contest/platform/auth_epoch.dart';
import 'package:soar_score_contest/platform/profile_bound_sync.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_sync/soar_score_sync.dart';

import '../support/fake_auth_session.dart';

/// A real [SyncEngine] over the pinned store, applier and gateway: a sync in
/// flight and a conflict decision run at the same time, the profile changes
/// before the sync's response is released, and the sync's own pin decides
/// what it may store.
void main() {
  late Directory dir;
  late EmbeddedServer server;
  late ActingAccount acting;
  late DriftSyncStore store;
  late _Service service;
  late _CountingApplier applier;
  late SyncEngine engine;
  final accountA = core.Id.create();
  final scope = core.DirectorScopeKey(accountA);

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('profile_bound_engine');
    server = await startEmbeddedServer('${dir.path}/soar_score.db');
    final auth = FakeAuthSession(signedIn: true);
    final epoch = AuthEpoch(auth);
    acting = ActingAccount(server, epoch);
    expect(acting.actAs(accountA, epoch: epoch.value), isTrue);
    final binding = SyncProfileBinding(acting);
    store = DriftSyncStore(server.database);
    service = _Service();
    applier = _CountingApplier(server);
    engine = SyncEngine(
      store: ProfileBoundSyncStore(store, binding),
      applier: ProfileBoundChangeApplier(applier, binding),
      gateway: ProfileBoundSyncGateway(service, binding, (_) async => accountA),
      config: SyncEngineConfig(
        installationId: core.Id.create(),
        label: 'test',
        platform: core.Platform.other,
        schemaVersion: 1,
      ),
    );
  });

  tearDown(() async {
    await engine.dispose();
    await server.close();
    dir.deleteSync(recursive: true);
  });

  test('a conflict decision during a sync leaves the sync pinned to its own '
      'exchange', () async {
    // 1-2. The sync reaches its exchange, which the service holds.
    service.holdNextExchange();
    final sync = engine.syncScope(scope);
    await service.exchangeReached;

    // 3. The profile changes (a mismatch that ends again: it looks as it did,
    // only its generation tells the two apart).
    server.markProfileMismatch();
    server.actAsLocal();

    // 4. A conflict decision starts after that, while the sync is still in
    // flight, and is held as well. Pinning here would replace the sync's pin
    // with one of the new generation.
    service.holdConflict();
    final decision = engine.resolveConflict(
      scope,
      core.Id.create(),
      clientMutationId: 'decision',
      choice: core.ConflictResolutionChoice.keptAccepted,
    );
    await pumpEventQueue();
    expect(service.conflictRequests, 1);

    // 5. Both answers arrive.
    service.releaseConflict();
    service.releaseExchange();
    final failure = await sync;
    await decision;

    // 6. The sync stored nothing, and it will be tried again.
    expect(failure, SyncFailureKind.offline);
    expect(applier.applied, 0);
    expect(await store.readCursor(scope), 0);

    // 7. The next sync pins afresh and completes.
    expect(await engine.syncScope(scope), isNull);
    expect(applier.applied, 1);
    expect(await store.readCursor(scope), 1);
  });
}

SyncExchangeResponse _response() => SyncExchangeResponse(
  protocolVersion: core.SyncProtocol.protocolVersion,
  results: const [],
  changes: [
    SyncChangeDto(
      sequence: 1,
      entityType: 'contest',
      entityId: core.Id.create(),
      revision: 1,
      payload: const {},
    ),
  ],
  conflicts: const [],
  serverSequence: 1,
);

class _CountingApplier implements core.ReplicatedChangeApplier {
  _CountingApplier(this._server);

  final EmbeddedServer _server;
  int applied = 0;

  @override
  Future<bool> apply(core.ReplicatedChange change) async {
    // A real write, so the database is what refuses a stale one.
    await _server.database.customStatement('UPDATE contests SET name = name');
    applied++;
    return true;
  }
}

/// A service that answers at once unless a test holds the exchange or the
/// conflict decision.
class _Service implements SyncGateway {
  Completer<void>? _exchangeGate;
  Completer<void>? _heldExchange;
  Completer<void>? _conflictGate;
  final _reached = Completer<void>();
  int conflictRequests = 0;

  Future<void> get exchangeReached => _reached.future;

  void holdNextExchange() => _exchangeGate = Completer<void>();

  void releaseExchange() => _heldExchange?.complete();

  void holdConflict() => _conflictGate = Completer<void>();

  void releaseConflict() => _conflictGate?.complete();

  @override
  Future<SyncInfoDto> syncInfo() async => SyncInfoDto(
    protocolVersion: core.SyncProtocol.protocolVersion,
    minProtocolVersion: 1,
    minSchemaVersion: 1,
    maxSchemaVersion: 1,
    serverTime: DateTime.utc(2026, 11, 8),
  );

  @override
  Future<core.Installation> registerInstallation(
    RegisterInstallationRequest request,
  ) async => core.Installation(
    id: request.id,
    ownerAccountId: core.Id.create(),
    label: request.label,
    platform: request.platform,
    createdAt: DateTime.utc(2026, 11, 8),
  );

  @override
  Future<SyncExchangeResponse> exchange(SyncExchangeRequest request) async {
    final gate = _exchangeGate;
    if (gate != null) {
      _exchangeGate = null;
      _heldExchange = gate;
      if (!_reached.isCompleted) _reached.complete();
      await gate.future;
    }
    return _response();
  }

  @override
  Future<SyncMutationResult> resolveConflict(
    core.Id conflictId,
    ResolveConflictRequest request, {
    required core.SyncScopeKey scope,
  }) async {
    conflictRequests++;
    await _conflictGate?.future;
    // Rejected, so the engine does not start a sync of its own to store it.
    return SyncMutationResult(
      clientMutationId: request.clientMutationId,
      outcome: core.MutationOutcome.rejected,
    );
  }

  @override
  Future<SystemDataResponse> systemData({
    required int afterSequence,
    String? pageToken,
  }) => throw UnimplementedError();
}
