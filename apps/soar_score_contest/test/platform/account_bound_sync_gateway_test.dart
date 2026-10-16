import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/account_bound_sync_gateway.dart';
import 'package:soar_score_contest/platform/acting_account.dart';
import 'package:soar_score_contest/platform/auth_epoch.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_sync/soar_score_sync.dart';

import '../support/gated_auth_session.dart';

/// Every request type of the sync engine, with sign-outs and sign-ins as
/// someone else at each point where an await separates the decision to send
/// from the request: the owner lookup and the access-token lookup.
void main() {
  late Directory dir;
  late EmbeddedServer server;
  late GatedAuthSession auth;
  late AuthEpoch epoch;
  late ActingAccount acting;
  late AccountBoundSyncGateway gateway;
  late List<http.Request> sent;
  Completer<void>? ownerGate;
  final accountA = core.Id.create();
  final accountB = core.Id.create();
  final scopeA = core.DirectorScopeKey(accountA);

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('account_bound_gateway');
    server = await startEmbeddedServer('${dir.path}/soar_score.db');
    auth = GatedAuthSession(signedIn: true);
    epoch = AuthEpoch(auth);
    acting = ActingAccount(server, epoch);
    expect(acting.actAs(accountA, epoch: epoch.value), isTrue);
    sent = [];
    ownerGate = null;
    final client = ApiClient(
      baseUrl: Uri.parse('http://hosted.invalid'),
      tokenProvider: epoch.boundToken(auth.accessToken),
      httpClient: MockClient((request) async {
        sent.add(request);
        return http.Response('{}', 503);
      }),
    );
    gateway = AccountBoundSyncGateway(
      ApiClientSyncGateway(client),
      acting: acting,
      ownerOf: (scope) async {
        await ownerGate?.future;
        return scope is core.DirectorScopeKey ? scope.ownerAccountId : null;
      },
    );
  });

  tearDown(() async {
    epoch.close();
    await server.close();
    dir.deleteSync(recursive: true);
  });

  /// What the engine sends, by name.
  final operations = <String, Future<Object?> Function()>{
    'sync info': () => gateway.syncInfo(),
    'registration': () => gateway.registerInstallation(
      RegisterInstallationRequest(
        id: core.Id.create(),
        label: 'Laptop',
        platform: core.Platform.windows,
      ),
    ),
    'exchange': () => gateway.exchange(
      SyncExchangeRequest(
        protocolVersion: 1,
        schemaVersion: 1,
        installationId: core.Id.create(),
        scope: SyncScopeDto.owner(accountA),
        lastAcknowledgedSequence: 0,
      ),
    ),
    'system data': () => gateway.systemData(afterSequence: 0),
    'conflict decision': () => gateway.resolveConflict(
      core.Id.create(),
      ResolveConflictRequest(
        clientMutationId: 'm-1',
        choice: core.ConflictResolutionChoice.keptAccepted,
      ),
      scope: scopeA,
    ),
  };

  /// The director signs out; the app goes back to the Local account.
  Future<void> signOut() async {
    await auth.signOut();
    acting.actAsLocal();
  }

  /// Signs out and in as B, and B's claim finishes.
  Future<void> switchToB() async {
    await auth.switchTo('B');
    expect(acting.actAs(accountB, epoch: epoch.value), isTrue);
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  for (final MapEntry(key: name, value: send) in operations.entries) {
    group(name, () {
      test('is sent under the token of the account it is for', () async {
        await expectLater(send(), throwsA(isA<ApiHttpError>()));

        expect(sent.single.headers['authorization'], 'Bearer token-A');
      });

      test('is not sent after sign-out', () async {
        await signOut();

        await expectLater(send(), throwsA(isA<SessionChangedError>()));
        expect(sent, isEmpty);
      });

      test('is not sent if sign-out comes during the token lookup', () async {
        auth.gate = Completer<void>();
        final result = send();
        await settle();

        await signOut();
        auth.gate!.complete();

        await expectLater(result, throwsA(isA<SessionChangedError>()));
        expect(sent, isEmpty);
      });

      test('never carries B\'s token when B signs in during the token '
          'lookup', () async {
        auth.gate = Completer<void>();
        final result = send();
        await settle();

        acting.actAsLocal();
        await auth.switchTo('B');
        auth.gate!.complete();

        await expectLater(result, throwsA(isA<SessionChangedError>()));
        expect(sent, isEmpty, reason: 'A\'s request must not carry B\'s token');
      });

      test(
        'is not sent if the bootstrap closes during the token lookup',
        () async {
          auth.gate = Completer<void>();
          final result = send();
          await settle();

          epoch.close();
          auth.gate!.complete();

          await expectLater(result, throwsA(isA<SessionChangedError>()));
          expect(sent, isEmpty);
        },
      );
    });
  }

  for (final name in ['exchange', 'conflict decision']) {
    group('$name, while the scope\'s owner is looked up', () {
      test('is not sent after sign-out', () async {
        ownerGate = Completer<void>();
        final result = operations[name]!();
        await settle();

        await signOut();
        ownerGate!.complete();

        await expectLater(result, throwsA(isA<SessionChangedError>()));
        expect(sent, isEmpty);
      });

      test('is not sent after sign-in as another account', () async {
        ownerGate = Completer<void>();
        final result = operations[name]!();
        await settle();

        acting.actAsLocal();
        await switchToB();
        ownerGate!.complete();

        await expectLater(result, throwsA(isA<SessionChangedError>()));
        expect(sent, isEmpty, reason: 'A\'s scope is not B\'s to send');
      });
    });
  }

  test('requests for another account\'s scope are refused', () async {
    final result = gateway.exchange(
      SyncExchangeRequest(
        protocolVersion: 1,
        schemaVersion: 1,
        installationId: core.Id.create(),
        scope: SyncScopeDto.owner(accountB),
        lastAcknowledgedSequence: 0,
      ),
    );

    await expectLater(result, throwsA(isA<SessionChangedError>()));
    expect(sent, isEmpty);
  });
}
