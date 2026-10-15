import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_contest/platform/local_account_claimer.dart';
import 'package:soar_score_contest/platform/native_sync.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

import '../support/fake_auth_session.dart';

/// Device A signs in and syncs; device B, used offline under its own Local
/// account, signs in and syncs; A syncs again and receives what B made.
void main() {
  late SoarScoreDatabase hostedDatabase;
  late Repository hosted;
  late shelf.Handler api;
  late Directory dir;
  late EmbeddedServer a;
  late EmbeddedServer b;
  late NativeSync syncA;
  late NativeSync syncB;
  late ApiClient remoteA;
  late ApiClient remoteB;
  late core.Id contestA;
  late core.Id contestB;
  final director = core.Id.create();

  ApiClient client() => ApiClient(
    baseUrl: Uri.parse('http://hosted.invalid'),
    tokenProvider: () async => director.value,
    httpClient: MockClient((request) async {
      final response = await api(
        shelf.Request(
          request.method,
          request.url,
          headers: request.headers,
          body: request.bodyBytes,
        ),
      );
      return http.Response.bytes(
        await response.read().expand((chunk) => chunk).toList(),
        response.statusCode,
        headers: response.headers,
      );
    }),
  );

  Future<core.Id> save(EmbeddedServer installation, String name) async {
    final contest = await ContestRepository(installation.database).save(
      core.Contest(
        id: core.Id.create(),
        name: name,
        startDateTime: DateTime.utc(2026, 4, 15, 10),
        endDateTime: DateTime.utc(2026, 4, 16, 20),
        timezone: 'America/Denver',
        ownerAccountId: installation.localAccountId,
        createdAt: DateTime.utc(2026, 4),
        updatedAt: DateTime.utc(2026, 4),
      ),
      metadata: core.MutationMetadata(
        clientMutationId: 'm-$name',
        authority: core.Authority.director,
        clientTime: DateTime.utc(2026, 4),
        actorId: installation.localAccountId,
      ),
    );
    await RoleRepository(installation.database).save(
      core.Role(
        id: core.Id.create(),
        ownerAccountId: installation.localAccountId,
        displayName: 'Timekeeper $name',
        type: core.RoleType.nonFlier,
      ),
      metadata: core.MutationMetadata(
        clientMutationId: 'r-$name',
        authority: core.Authority.director,
        clientTime: DateTime.utc(2026, 4),
        actorId: installation.localAccountId,
      ),
    );
    return contest.id;
  }

  /// Signs in on [installation] and syncs what the claim made syncable.
  Future<void> signInAndSync(
    EmbeddedServer installation,
    NativeSync sync,
    ApiClient remote,
    core.Id contest,
  ) async {
    final claimer = LocalAccountClaimer(
      auth: FakeAuthSession(signedIn: true),
      local: LocalAccountRepository(installation.database),
      claim: remote.claimLocalAccount,
      onClaimed: sync.accountClaimed,
      onProblem: (_) {},
    );
    await claimer.run();
    expect(
      await sync.engine.syncScope(core.DirectorScopeKey(director)),
      isNull,
    );
    expect(await sync.engine.syncScope(core.ContestScopeKey(contest)), isNull);
  }

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    hostedDatabase = SoarScoreDatabase(
      NativeDatabase.memory(),
      profile: DatabaseProfile.server,
    );
    hosted = Repository(hostedDatabase);
    await hosted.accountRepository.save(
      core.Account(
        id: director,
        firstName: 'Dana',
        lastName: 'Director',
        kind: core.AccountKind.registered,
        createdAt: DateTime.utc(2026, 10, 1),
        updatedAt: DateTime.utc(2026, 10, 1),
      ),
    );
    api = buildApiHandler(
      name: 'hosted',
      displayName: 'Hosted',
      version: '0.0.0',
      repository: hosted,
      authMiddleware: fixedPrincipal(Principal(accountId: director)),
    );
    dir = Directory.systemTemp.createTempSync('two_installations_sync');
    a = await startEmbeddedServer('${dir.path}/a/soar_score.db');
    b = await startEmbeddedServer('${dir.path}/b/soar_score.db');
    remoteA = client();
    remoteB = client();
    syncA = await NativeSync.start(
      database: a.database,
      localAccountId: a.localAccountId,
      remote: remoteA,
      databasePath: '${dir.path}/a/soar_score.db',
    );
    syncB = await NativeSync.start(
      database: b.database,
      localAccountId: b.localAccountId,
      remote: remoteB,
      databasePath: '${dir.path}/b/soar_score.db',
    );
    contestA = await save(a, 'Spring A');
    contestB = await save(b, 'Spring B');
  });

  tearDown(() async {
    await syncA.close();
    await syncB.close();
    await a.close();
    await b.close();
    remoteA.close();
    remoteB.close();
    await hostedDatabase.close();
    dir.deleteSync(recursive: true);
  });

  test('A receives what B made offline after B signs in', () async {
    await signInAndSync(a, syncA, remoteA, contestA);
    expect(
      (await hosted.contestRepository.findById(contestA))?.ownerAccountId,
      director,
    );

    await signInAndSync(b, syncB, remoteB, contestB);
    final onServer = await hosted.contestRepository.getAll();
    expect(
      onServer.map((c) => c.name),
      unorderedEquals(['Spring A', 'Spring B']),
    );
    expect(onServer.map((c) => c.ownerAccountId), everyElement(director));

    // A syncs again. The director's own data comes down by itself.
    expect(
      await syncA.engine.syncScope(core.DirectorScopeKey(director)),
      isNull,
    );
    final roles = await RoleRepository(a.database)
        .listVisibleTo(ownerAccountId: director);
    expect(
      roles.map((role) => role.displayName),
      containsAll(['Timekeeper Spring A', 'Timekeeper Spring B']),
    );

    // A finds B's contest by listing the account's contests; nobody names
    // its id. Before that, the contest is not held and not syncable.
    expect(await ContestRepository(a.database).findById(contestB), isNull);
    await syncA.discoverAccountContests();
    expect(
      await syncA.engine.syncScope(core.ContestScopeKey(contestB)),
      isNull,
    );

    final onA = await ContestRepository(a.database).getAll();
    expect(onA.map((c) => c.name), unorderedEquals(['Spring A', 'Spring B']));
    expect(onA.map((c) => c.ownerAccountId), everyElement(director));
  });

  test(
    'a contest the service does not list for the account stays unknown',
    () async {
      await signInAndSync(a, syncA, remoteA, contestA);
      await syncA.discoverAccountContests();
      expect(
        await syncA.engine.syncScope(core.ContestScopeKey(core.Id.create())),
        isNull,
      );
      expect(
        (await ContestRepository(a.database).getAll()).map((c) => c.name),
        ['Spring A'],
      );
    },
  );
}
