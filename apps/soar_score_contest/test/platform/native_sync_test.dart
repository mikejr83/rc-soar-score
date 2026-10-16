import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/acting_account.dart';
import 'package:soar_score_contest/platform/auth_epoch.dart';
import 'package:soar_score_contest/platform/native_sync.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_contest/services/sync/sync_problem.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

import '../support/fake_auth_session.dart';

void main() {
  late Directory dir;
  late String databasePath;
  late EmbeddedServer server;
  late NativeSync sync;
  late List<String> paths;
  var status = 503;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('native_sync_test');
    databasePath = '${dir.path}/soar_score.db';
    server = await startEmbeddedServer(databasePath);
    paths = [];
    status = 503;
    // A hosted server that answers nothing useful: the test only watches which
    // requests the engine makes.
    final remote = ApiClient(
      baseUrl: Uri.parse('http://hosted.invalid'),
      httpClient: MockClient((request) async {
        paths.add(request.url.path);
        return http.Response(
          jsonEncode({
            'error': {'code': 'unavailable', 'message': 'offline'},
          }),
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    sync = await NativeSync.start(
      database: server.database,
      localAccountId: server.localAccountId,
      remote: remote,
      databasePath: databasePath,
      discoveryDelay: const Duration(milliseconds: 300),
    );
  });

  tearDown(() async {
    await sync.close();
    await server.close();
    dir.deleteSync(recursive: true);
  });

  Future<core.Contest> saveContest(core.Id? owner) =>
      ContestRepository(server.database).save(
        core.Contest(
          id: core.Id.create(),
          name: 'Spring Meet',
          startDateTime: DateTime.utc(2026, 4, 15, 10),
          endDateTime: DateTime.utc(2026, 4, 16, 20),
          timezone: 'America/Denver',
          createdAt: DateTime.utc(2026, 4),
          updatedAt: DateTime.utc(2026, 4),
          ownerAccountId: owner,
        ),
        metadata: core.MutationMetadata(
          clientMutationId: 'm-${DateTime.now().microsecondsSinceEpoch}',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 4),
        ),
      );

  Future<void> settle() => Future<void>.delayed(const Duration(seconds: 2));

  test('a contest owned by the Local account is never synced', () async {
    await saveContest(server.localAccountId);
    await settle();

    expect(paths, isEmpty);
  });

  test('a local write to an account-owned contest starts a sync', () async {
    await saveContest(core.Id.create());
    await settle();

    expect(paths, isNotEmpty);
    expect(paths.first, '/api/v1/sync/info');
  });

  test('claiming the Local account makes its contest sync', () async {
    final contest = await saveContest(server.localAccountId);
    await settle();
    expect(paths, isEmpty);
    final account = core.Id.create();

    await LocalAccountRepository(server.database).reassignTo(account);
    await sync.accountClaimed(account);
    await settle();

    expect(paths, isNotEmpty);
    final scope = core.ContestScopeKey(contest.id);
    final summary = sync.appSync.state.of(scope)!;
    expect(summary.localOnly, isFalse);
    expect(summary.pendingChanges, 1);
  });

  test('a burst of syncs lists the account contests once', () async {
    // A refused token is not retried, so only the syncs below end here.
    status = 401;
    final account = core.Id.create();
    await sync.accountClaimed(account);
    await settle();
    final afterClaim = paths.where((p) => p == '/api/v1/contests').length;

    for (var i = 0; i < 5; i++) {
      await sync.engine.syncScope(core.DirectorScopeKey(account));
    }
    await settle();

    expect(paths.where((p) => p == '/api/v1/contests').length, afterClaim + 1);
  });

  test('data of another account is not synced as the acting account', () async {
    final acting = core.Id.create();
    final auth = FakeAuthSession(signedIn: true);
    final epoch = AuthEpoch(auth);
    final account = ActingAccount(server, epoch);
    expect(account.actAs(acting, epoch: epoch.value), isTrue);
    final actingPaths = <String>[];
    final actingSync = await NativeSync.start(
      database: server.database,
      localAccountId: server.localAccountId,
      acting: account,
      remote: ApiClient(
        baseUrl: Uri.parse('http://hosted.invalid'),
        httpClient: MockClient((request) async {
          actingPaths.add(request.url.path);
          return http.Response('{}', 503);
        }),
      ),
      databasePath: databasePath,
    );
    addTearDown(actingSync.close);

    await saveContest(core.Id.create());
    await settle();
    expect(actingPaths, isEmpty, reason: 'another account owns it');

    await saveContest(acting);
    await settle();
    expect(actingPaths, isNotEmpty, reason: 'the acting account owns it');
  });

  test('contests are listed only for the account the app acts as', () async {
    final acting = core.Id.create();
    final auth = FakeAuthSession(signedIn: true);
    final epoch = AuthEpoch(auth);
    final account = ActingAccount(server, epoch);
    expect(account.actAs(acting, epoch: epoch.value), isTrue);
    final listed = <String>[];
    final actingSync = await NativeSync.start(
      database: server.database,
      localAccountId: server.localAccountId,
      acting: account,
      remote: ApiClient(
        baseUrl: Uri.parse('http://hosted.invalid'),
        httpClient: MockClient((request) async {
          listed.add(request.url.path);
          return http.Response('[]', 200);
        }),
      ),
      databasePath: databasePath,
    );
    addTearDown(actingSync.close);

    await actingSync.accountClaimed(core.Id.create());
    expect(listed.where((p) => p == '/api/v1/contests'), isEmpty);

    await actingSync.accountClaimed(acting);
    expect(listed.where((p) => p == '/api/v1/contests'), isNotEmpty);
  });

  test('a claim problem shows on a local-only contest', () async {
    final contest = await saveContest(server.localAccountId);
    final scope = core.ContestScopeKey(contest.id);
    await sync.appSync.refresh(scope);

    sync.appSync.claimProblemChanged(SyncProblem.accountClaimBlocked);

    expect(
      sync.appSync.state.of(scope)!.problem,
      SyncProblem.accountClaimBlocked,
    );
    sync.appSync.claimProblemChanged(null);
    expect(sync.appSync.state.of(scope)!.problem, isNull);
  });

  group('what the screens see', () {
    test('a local-only contest is reported as local only', () async {
      final contest = await saveContest(server.localAccountId);
      final scope = core.ContestScopeKey(contest.id);

      await sync.appSync.refresh(scope);

      expect(sync.appSync.state.of(scope)!.localOnly, isTrue);
    });

    test('an account-owned contest shows its pending change', () async {
      final contest = await saveContest(core.Id.create());
      final scope = core.ContestScopeKey(contest.id);

      await sync.appSync.refresh(scope);

      final summary = sync.appSync.state.of(scope)!;
      expect(summary.localOnly, isFalse);
      expect(summary.pendingChanges, 1);
      expect(summary.rejectedChanges, 0);
    });

    test('a failed sync names its problem and keeps the change', () async {
      final contest = await saveContest(core.Id.create());
      final scope = core.ContestScopeKey(contest.id);

      await sync.appSync.syncNow(scope);

      final summary = sync.appSync.state.of(scope)!;
      expect(summary.problem, SyncProblem.serverError);
      expect(summary.pendingChanges, 1);
    });

    test('a refused change is counted and listed with its reason', () async {
      final contest = await saveContest(core.Id.create());
      final scope = core.ContestScopeKey(contest.id);
      final store = DriftSyncStore(server.database);
      final pending = (await store.pendingMutations(scope)).single;
      await store.recordOutcome(
        mutationId: pending.id,
        outcome: core.MutationOutcome.rejected,
        serverRejectionTime: DateTime.utc(2026, 4, 2),
        reasonCode: 'locked',
      );

      await sync.appSync.refresh(scope);

      expect(sync.appSync.state.of(scope)!.rejectedChanges, 1);
      final refused = await sync.appSync.refusedChanges(scope);
      expect(refused.single.entityType, 'Contest');
      expect(refused.single.reason, 'Locked.');
    });
  });
}
