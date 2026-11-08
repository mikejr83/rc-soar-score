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

/// A sync's local writes belong to the exchange that brought them: once the
/// profile changed or the sign-in ended after the request was sent, the
/// response is not stored and the cursor does not move.
void main() {
  late Directory dir;
  late EmbeddedServer server;
  late FakeAuthSession auth;
  late AuthEpoch epoch;
  late ActingAccount acting;
  late SyncProfileBinding binding;
  late DriftSyncStore store;
  late ProfileBoundSyncStore bound;
  final accountA = core.Id.create();
  final scope = core.DirectorScopeKey(accountA);

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('profile_bound_sync');
    server = await startEmbeddedServer('${dir.path}/soar_score.db');
    auth = FakeAuthSession(signedIn: true);
    epoch = AuthEpoch(auth);
    acting = ActingAccount(server, epoch);
    expect(acting.actAs(accountA, epoch: epoch.value), isTrue);
    binding = SyncProfileBinding(acting);
    store = DriftSyncStore(server.database);
    bound = ProfileBoundSyncStore(store, binding);
  });

  tearDown(() async {
    await server.close();
    dir.deleteSync(recursive: true);
  });

  void sendExchange() =>
      binding.pin(generation: binding.generation, owner: accountA);

  Future<void> expectRefusedAndUnmoved() async {
    await expectLater(
      bound.writeCursor(scope, 5),
      throwsA(isA<ApiNetworkError>()),
    );
    expect(await store.readCursor(scope), 0);
  }

  test('without a transition the cursor moves', () async {
    sendExchange();
    await bound.writeCursor(scope, 5);
    expect(await store.readCursor(scope), 5);
  });

  test('signing out after the request is sent stores nothing', () async {
    sendExchange();
    acting.actAsLocal();
    await expectRefusedAndUnmoved();
  });

  test('another account signing in stores nothing', () async {
    sendExchange();
    acting.signedIn('auth0|b');
    await expectRefusedAndUnmoved();
  });

  test('a mismatch or a claim in between stores nothing', () async {
    sendExchange();
    server.markProfileMismatch();
    await expectRefusedAndUnmoved();

    server.actAsLocal();
    sendExchange();
    server.beginClaim(core.Id.create(), 'auth0|c');
    await expectRefusedAndUnmoved();
    server.endClaim();
  });

  test('signing out and in again (a new sign-in) stores nothing', () async {
    sendExchange();
    acting.actAsLocal();
    await auth.signOut();
    await auth.signIn();
    expect(acting.actAs(accountA, epoch: epoch.value), isTrue);
    await expectRefusedAndUnmoved();
  });

  test('an applied change that crosses a transition is refused', () async {
    var applied = 0;
    final applier = ProfileBoundChangeApplier(
      _CountingApplier(() => applied++, server),
      binding,
    );
    sendExchange();
    acting.signedIn('auth0|b');

    await expectLater(
      applier.apply(_change(scope)),
      throwsA(isA<ApiNetworkError>()),
    );
    expect(applied, 0);
  });

  test('the transition lands while the remote exchange is in flight', () async {
    final answer = Completer<void>();
    final gateway = ProfileBoundSyncGateway(
      _HeldGateway(answer.future),
      binding,
      (_) async => accountA,
    );

    final exchange = gateway.exchange(_request(accountA));
    await pumpEventQueue();
    acting.actAsLocal(); // signed out while the service is answering
    answer.complete();
    await expectLater(exchange, throwsA(isA<ApiNetworkError>()));

    await expectRefusedAndUnmoved();
  });

  test('the next exchange after a refusal stores normally', () async {
    sendExchange();
    acting.signedIn('auth0|b');
    await expectRefusedAndUnmoved();

    acting.signedIn(null);
    acting.actAsLocal();
    expect(acting.actAs(accountA, epoch: epoch.value), isTrue);
    sendExchange();
    await bound.writeCursor(scope, 5);
    expect(await store.readCursor(scope), 5);
  });
}

core.ReplicatedChange _change(core.SyncScopeKey scope) => core.ReplicatedChange(
  scope: scope,
  sequence: 1,
  entityType: 'contest',
  entityId: core.Id.create(),
  revision: 1,
  payload: const {},
);

SyncExchangeRequest _request(core.Id owner) => SyncExchangeRequest(
  protocolVersion: 1,
  schemaVersion: 1,
  installationId: core.Id.create(),
  scope: SyncScopeDto(ownerAccountId: owner),
  lastAcknowledgedSequence: 0,
  mutations: const [],
);

class _CountingApplier implements core.ReplicatedChangeApplier {
  _CountingApplier(this._onApply, this._server);

  final void Function() _onApply;
  final EmbeddedServer _server;

  @override
  Future<void> apply(core.ReplicatedChange change) async {
    await _server.database.customStatement('UPDATE contests SET name = name');
    _onApply();
  }
}

class _HeldGateway implements SyncGateway {
  _HeldGateway(this._gate);

  final Future<void> _gate;

  @override
  Future<SyncExchangeResponse> exchange(SyncExchangeRequest request) async {
    await _gate;
    throw ApiNetworkError(
      'lost',
      requestUri: Uri.parse('http://hosted.invalid/'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
