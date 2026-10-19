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
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

import '../support/fake_auth_session.dart';

/// One director with two installations: preferences chosen on A reach the
/// account when A signs in and reach B when B signs in, through the real API
/// client, handlers and repositories.
void main() {
  late SoarScoreDatabase hostedDatabase;
  late Repository hosted;
  late shelf.Handler api;
  late Directory dir;
  late EmbeddedServer a;
  late EmbeddedServer b;
  final director = core.Id.create();

  /// The hosted API, called in process; the bearer token is the account id.
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

  Future<void> signIn(EmbeddedServer installation) async {
    final remote = client();
    final auth = FakeAuthSession(signedIn: true);
    final claimer = LocalAccountClaimer(
      auth: auth,
      epoch: AuthEpoch(auth),
      local: LocalAccountRepository(installation.database),
      claim: remote.claimLocalAccount,
      onClaimed: (_, _) async {},
      onSignedOut: () {},
      onProblem: (_) {},
      getPreferences: remote.getAccountPreferences,
      putPreferences: remote.updateAccountPreferences,
    );
    await claimer.run();
    claimer.stop();
    remote.close();
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
      authMiddleware: (inner) =>
          (request) => inner(
            request.change(
              context: {principalContextKey: Principal(accountId: director)},
            ),
          ),
    );
    dir = Directory.systemTemp.createTempSync('two_installations_prefs');
    a = await startEmbeddedServer('${dir.path}/a/soar_score.db');
    b = await startEmbeddedServer('${dir.path}/b/soar_score.db');
  });

  tearDown(() async {
    await a.close();
    await b.close();
    await hostedDatabase.close();
    dir.deleteSync(recursive: true);
  });

  test('preferences chosen on one device load on another', () async {
    final chosen = core.AccountPreferences(
      preferredTimeZone: 'Europe/Rome',
      preferredLocale: 'en-US',
    );
    await LocalAccountRepository(a.database).savePreferences(chosen);

    await signIn(a);
    expect(
      await hosted.accountRepository.findById(director),
      isA<core.Account>(),
    );
    expect(
      (await hosted.accountRepository.findById(director))!.preferences,
      chosen,
    );

    await signIn(b);
    expect(await LocalAccountRepository(b.database).preferences(), chosen);
  });

  test('a choice on the account stands over one made offline', () async {
    final onAccount = core.AccountPreferences(preferredTimeZone: 'Asia/Tokyo');
    await core.AccountPreferencesService(hosted).update(
      accountId: director,
      preferences: onAccount,
      now: DateTime.utc(2026, 10, 2),
    );
    await LocalAccountRepository(b.database).savePreferences(
      core.AccountPreferences(
        preferredTimeZone: 'Europe/Rome',
        preferredLocale: 'en-US',
      ),
    );

    await signIn(b);

    expect(
      await LocalAccountRepository(b.database).preferences(),
      core.AccountPreferences(
        preferredTimeZone: 'Asia/Tokyo',
        preferredLocale: 'en-US',
      ),
    );
  });

  test('the embedded server has no accounts and answers 409', () async {
    final embedded = ApiClient(
      baseUrl: a.baseUrl,
      tokenProvider: () async => a.secret,
    );
    try {
      await expectLater(
        embedded.getAccountPreferences(),
        throwsA(
          isA<ApiHttpError>()
              .having((e) => e.statusCode, 'status', 409)
              .having((e) => e.error?.code, 'code', 'backend_only'),
        ),
      );
      await expectLater(
        embedded.updateAccountPreferences(core.AccountPreferences()),
        throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 409)),
      );
    } finally {
      embedded.close();
    }
  });
}
