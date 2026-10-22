import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/acting_account.dart';
import 'package:soar_score_contest/platform/auth_epoch.dart';
import 'package:soar_score_contest/platform/inspection_owner_guard.dart';
import 'package:soar_score_contest/platform/native_sync.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_sync/soar_score_sync.dart';

import '../support/fake_auth_session.dart';
import '../support/inspection_import.dart';

/// A contest imported for inspection, and the director data that came with
/// it, never reaches the service: with no acting account, signed in, after a
/// restart, after a claim, after a local edit, and when the markers cannot
/// be read.
void main() {
  late Directory dir;
  late String databasePath;
  late EmbeddedServer server;
  late List<String> requests;
  late core.Contest inspected;
  late core.Id owner;
  var contestsListing = '{"contests": []}';

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('inspection_sync_test');
    databasePath = '${dir.path}/soar_score.db';
    server = await startEmbeddedServer(databasePath);
    requests = [];
    contestsListing = '{"contests": []}';
    final imported = await importDemoForInspection(
      server.database,
      localAccountId: server.localAccountId,
    );
    inspected = imported.contest;
    owner = imported.owner;
  });

  tearDown(() async {
    await server.close();
    dir.deleteSync(recursive: true);
  });

  ApiClient remote() => ApiClient(
    baseUrl: Uri.parse('http://hosted.invalid'),
    httpClient: MockClient((request) async {
      // The path and the body, so a request that names the contest or its
      // owner anywhere is seen.
      requests.add('${request.method} ${request.url} ${request.body}');
      if (request.url.path == '/api/v1/contests') {
        return http.Response(
          contestsListing,
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode({
          'error': {'code': 'unavailable', 'message': 'offline'},
        }),
        503,
        headers: {'content-type': 'application/json'},
      );
    }),
  );

  Future<NativeSync> start({
    ActingAccount? acting,
    InspectionOwnerGuard? guard,
  }) async {
    final sync = await NativeSync.start(
      database: server.database,
      localAccountId: server.localAccountId,
      acting: acting,
      remote: remote(),
      databasePath: databasePath,
      discoveryDelay: const Duration(milliseconds: 200),
      inspectionOwners: guard,
    );
    addTearDown(sync.close);
    return sync;
  }

  ActingAccount signedInAs(core.Id account) {
    final epoch = AuthEpoch(FakeAuthSession(signedIn: true));
    final acting = ActingAccount(server, epoch);
    expect(acting.actAs(account, epoch: epoch.value), isTrue);
    return acting;
  }

  Future<void> settle() => Future<void>.delayed(const Duration(seconds: 1));

  List<String> aboutInspection() => [
    for (final request in requests)
      if (request.contains(inspected.id.value) || request.contains(owner.value))
        request,
  ];

  /// Asks to sync every scope of the inspection copy, in every way a person
  /// or the app can, and returns how many requests that made.
  Future<int> trySyncEverything(NativeSync sync) async {
    await settle();
    final before = requests.length;
    final contest = core.ContestScopeKey(inspected.id);
    final director = core.DirectorScopeKey(owner);
    await sync.engine.syncScope(contest);
    await sync.engine.syncScope(director);
    await sync.appSync.syncNow(contest);
    await sync.appSync.syncNow(director);
    await settle();
    return requests.length - before;
  }

  Future<void> editInspectedContest() async {
    final contest = await ContestRepository(server.database)
        .findById(inspected.id);
    await ContestRepository(server.database).save(
      core.Contest.fromJson({
        ...contest!.toJson(),
        'name': '${contest.name} (edited)',
      }),
      metadata: core.MutationMetadata(
        clientMutationId: 'edit-${DateTime.now().microsecondsSinceEpoch}',
        authority: core.Authority.director,
        clientTime: DateTime.now().toUtc(),
        actorId: owner,
      ),
    );
  }

  test('the import left rows with an inspection owner', () {
    expect(owner, isNot(server.localAccountId));
    expect(inspected.ownerAccountId, owner);
  });

  test('with no acting account, nothing about it is sent', () async {
    final sync = await start();

    await editInspectedContest();
    expect(await trySyncEverything(sync), 0);

    expect(aboutInspection(), isEmpty);
  });

  test(
    'signed in, nothing about it is sent, and the account still syncs',
    () async {
      final account = core.Id.create();
      final sync = await start(acting: signedInAs(account));

      await editInspectedContest();
      expect(await trySyncEverything(sync), 0);
      expect(requests, isEmpty);

      await sync.engine.syncScope(core.DirectorScopeKey(account));
      await settle();
      expect(requests, isNotEmpty, reason: 'the account\'s own data does sync');
      expect(aboutInspection(), isEmpty);
    },
  );

  test('signing out and in again changes nothing', () async {
    final account = core.Id.create();
    final acting = signedInAs(account);
    final sync = await start(acting: acting);

    acting.actAsLocal();
    expect(await trySyncEverything(sync), 0);
    final epoch = AuthEpoch(FakeAuthSession(signedIn: true));
    final again = ActingAccount(server, epoch)
      ..actAs(core.Id.create(), epoch: epoch.value);
    expect(await trySyncEverything(sync), 0);
    expect(again.isAccount, isTrue);

    expect(aboutInspection(), isEmpty);
  });

  test(
    'a restart (a new engine over the same database) changes nothing',
    () async {
      final first = await start();
      await first.close();

      final second = await start(acting: signedInAs(core.Id.create()));
      await editInspectedContest();
      expect(await trySyncEverything(second), 0);

      expect(aboutInspection(), isEmpty);
    },
  );

  test(
    'a claim leaves the inspection rows alone and does not send them',
    () async {
      final sync = await start();
      final account = core.Id.create();

      await LocalAccountRepository(server.database).reassignTo(account);
      await sync.accountClaimed(account);
      // The claim's own sync of the account is not the subject here.
      await trySyncEverything(sync);
      for (final scope in [
        core.ContestScopeKey(inspected.id),
        core.DirectorScopeKey(owner),
      ]) {
        final state = sync.engine.state.scopes[scope];
        expect(state?.skipReason, SyncSkipReason.accountless);
        expect(state?.lastSyncedAt, isNull);
        expect(state?.failure, isNull);
      }

      final contest = await ContestRepository(server.database)
          .findById(inspected.id);
      expect(contest!.ownerAccountId, owner);
      expect(aboutInspection(), isEmpty);
    },
  );

  test('an account contest listed on the service that is held as an inspection copy is not synced', () async {
    final account = core.Id.create();
    contestsListing = jsonEncode({
      'contests': [
        {...inspected.toJson(), 'owner_account_id': account.value},
      ],
    });
    final sync = await start(acting: signedInAs(account));

    await sync.accountClaimed(account);
    await settle();

    expect(requests.any((r) => r.contains('/api/v1/contests')), isTrue);
    expect(
      requests.where(
        (r) => r.contains('exchange') && r.contains(inspected.id.value),
      ),
      isEmpty,
    );
  });

  test(
    'when the markers cannot be read, only an acting account\'s data syncs',
    () async {
      final account = core.Id.create();
      final stranger = core.Id.create();
      final broken = _BrokenGuard(server.database);

      // No acting account: an unknown owner must not sync.
      final plain = await start(guard: broken);
      await ContestRepository(server.database)
          .save(_contestOf(stranger), metadata: _metadata(stranger));
      await plain.engine.syncScope(core.ContestScopeKey(inspected.id));
      await plain.engine.syncScope(core.DirectorScopeKey(stranger));
      await settle();
      expect(requests.where((r) => r.contains('exchange')), isEmpty);
      await plain.close();

      // An acting account: only data it is acting for.
      final acting = await start(acting: signedInAs(account), guard: broken);
      await acting.engine.syncScope(core.ContestScopeKey(inspected.id));
      await acting.engine.syncScope(core.DirectorScopeKey(owner));
      await settle();
      expect(requests, isEmpty);
      await acting.engine.syncScope(core.DirectorScopeKey(account));
      await settle();
      expect(requests, isNotEmpty);
      expect(aboutInspection(), isEmpty);
    },
  );
}

core.Contest _contestOf(core.Id owner) => core.Contest(
  id: core.Id.create(),
  name: 'Stranger\'s Meet',
  startDateTime: DateTime.utc(2026, 4, 15, 10),
  endDateTime: DateTime.utc(2026, 4, 16, 20),
  timezone: 'America/Denver',
  createdAt: DateTime.utc(2026, 4),
  updatedAt: DateTime.utc(2026, 4),
  ownerAccountId: owner,
);

core.MutationMetadata _metadata(core.Id actor) => core.MutationMetadata(
  clientMutationId: 'm-${DateTime.now().microsecondsSinceEpoch}',
  authority: core.Authority.director,
  clientTime: DateTime.utc(2026, 4),
  actorId: actor,
);

/// A guard whose markers cannot be read.
class _BrokenGuard extends InspectionOwnerGuard {
  _BrokenGuard(super.database);

  @override
  Future<bool> isInspection(core.Id? owner) async =>
      owner == null ? false : throw StateError('markers unreadable');
}
