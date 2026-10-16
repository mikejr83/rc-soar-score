import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_contest/platform/auth_epoch.dart';
import 'package:soar_score_contest/platform/local_account_claimer.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_contest/services/sync/sync_problem.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

import '../support/fake_auth_session.dart';

/// One director with two installations, A and B, each used offline under its
/// own Local account, then signed in, then A signs in again.
void main() {
  late SoarScoreDatabase hostedDatabase;
  late Repository hosted;
  late shelf.Handler api;
  late Directory dir;
  late EmbeddedServer a;
  late EmbeddedServer b;
  final director = core.Id.create();
  final someoneElse = core.Id.create();

  core.Account account(core.Id id, String last) => core.Account(
    id: id,
    firstName: 'Dana',
    lastName: last,
    kind: core.AccountKind.registered,
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: DateTime.utc(2026, 10, 1),
  );

  /// The hosted API, called in process; the bearer token is the account id.
  ApiClient client(core.Id signedInAs) => ApiClient(
    baseUrl: Uri.parse('http://hosted.invalid'),
    tokenProvider: () async => signedInAs.value,
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

  Future<void> save(EmbeddedServer installation, String name) async {
    await ContestRepository(installation.database).save(
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
  }

  /// Signs [installation] in as [director] and runs its claim once.
  Future<List<SyncProblem?>> signIn(EmbeddedServer installation) async {
    final problems = <SyncProblem?>[];
    final remote = client(director);
    final auth = FakeAuthSession(signedIn: true);
    final claimer = LocalAccountClaimer(
      auth: auth,
      epoch: AuthEpoch(auth),
      local: LocalAccountRepository(installation.database),
      claim: remote.claimLocalAccount,
      onClaimed: (_, _) async {},
      onSignedOut: () {},
      onProblem: problems.add,
    );
    await claimer.run();
    remote.close();
    return problems;
  }

  Future<Set<core.Id?>> contestOwners(EmbeddedServer installation) async => {
    for (final contest in await ContestRepository(
      installation.database,
    ).getAll())
      contest.ownerAccountId,
  };

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    hostedDatabase = SoarScoreDatabase(
      NativeDatabase.memory(),
      profile: DatabaseProfile.server,
    );
    hosted = Repository(hostedDatabase);
    await hosted.accountRepository.save(account(director, 'Director'));
    await hosted.accountRepository.save(account(someoneElse, 'Other'));
    api = buildApiHandler(
      name: 'hosted',
      displayName: 'Hosted',
      version: '0.0.0',
      repository: hosted,
      authMiddleware: (inner) => (request) {
        final token = request.headers['authorization']!.substring(7);
        return inner(
          request.change(
            context: {
              principalContextKey: Principal(accountId: core.Id.parse(token)),
            },
          ),
        );
      },
    );
    dir = Directory.systemTemp.createTempSync('two_installations');
    a = await startEmbeddedServer('${dir.path}/a/soar_score.db');
    b = await startEmbeddedServer('${dir.path}/b/soar_score.db');
    await save(a, 'Spring A');
    await save(b, 'Spring B');
  });

  tearDown(() async {
    await a.close();
    await b.close();
    await hostedDatabase.close();
    dir.deleteSync(recursive: true);
  });

  test('two installations end up owned by one account', () async {
    final localA = a.localAccountId;
    final localB = b.localAccountId;
    expect(localA, isNot(localB));

    expect(await signIn(a), [null]);
    expect(await contestOwners(a), {director});
    expect(await contestOwners(b), {localB}, reason: 'B has not signed in');

    expect(await signIn(b), [null]);
    expect(await contestOwners(b), {director});

    // Back on A, signing in again is harmless.
    expect(await signIn(a), [null]);
    expect(await contestOwners(a), {director});
    expect(await ContestRepository(a.database).getAll(), hasLength(1));
    final roles = await RoleRepository(b.database)
        .listVisibleTo(ownerAccountId: director);
    expect(
      roles.map((role) => role.displayName),
      contains('Timekeeper Spring B'),
    );

    // The service knows both Local accounts as the director.
    expect(
      (await hosted.accountAliasRepository.findById(localA))?.accountId,
      director,
    );
    expect(
      (await hosted.accountAliasRepository.findById(localB))?.accountId,
      director,
    );
    expect(await hosted.accountAliasRepository.resolve(localA), director);
    expect(await hosted.accountAliasRepository.resolve(localB), director);
  });

  test('nothing keeps naming a Local account after the claim', () async {
    final localA = a.localAccountId;
    await signIn(a);

    final left = await a.database
        .customSelect(
          'SELECT COUNT(*) AS n FROM mutation_records '
          "WHERE owner_account_id = '${localA.value}' "
          "OR actor_id = '${localA.value}' "
          "OR payload LIKE '%\"owner_account_id\":\"${localA.value}\"%'",
        )
        .getSingle();
    expect(left.read<int>('n'), 0);
  });

  test('another account cannot take a claimed Local account', () async {
    await signIn(a);

    final other = client(someoneElse);
    await expectLater(
      other.claimLocalAccount(
        ClaimLocalAccountRequest(localAccountId: a.localAccountId),
      ),
      throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 409)),
    );
    other.close();
    expect(
      (await hosted.accountAliasRepository.findById(a.localAccountId))
          ?.accountId,
      director,
    );
  });
}
