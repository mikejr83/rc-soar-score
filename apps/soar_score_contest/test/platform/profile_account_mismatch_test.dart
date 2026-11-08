import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/acting_account.dart';
import 'package:soar_score_contest/platform/auth_epoch.dart';
import 'package:soar_score_contest/platform/local_account_claimer.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_contest/server/profile_mismatch_guard.dart';
import 'package:soar_score_contest/services/sync/sync_problem.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

import '../support/fake_auth_session.dart';

/// Account A claims the installation, signs out, and B signs in: B's claim is
/// refused, and the embedded API must not serve A's data to B.
void main() {
  late Directory tempDir;
  late EmbeddedServer server;
  late ApiClient client;
  late FakeAuthSession auth;
  late ActingAccount acting;
  late LocalAccountClaimer claimer;
  late List<SyncProblem?> problems;
  final accountA = core.Id.create();

  /// The account the service believes is signed in.
  late core.Id signedInAs;

  ApiHttpError alreadyClaimed() => ApiHttpError(
    'claimed',
    statusCode: 409,
    body: jsonEncode({
      'error': {'code': 'already_claimed', 'message': 'claimed'},
    }),
    requestUri: Uri.parse('http://hosted.invalid/api/v1/account/local-claims'),
  );

  Future<core.Contest> createContest(String name) => client.createContest(
    CreateContestRequest(
      id: core.Id.create(),
      name: name,
      startDateTime: DateTime.utc(2026, 10, 17, 14),
      endDateTime: DateTime.utc(2026, 10, 18, 22),
      timezone: 'America/Denver',
    ),
  );

  Future<int> contestRows() async =>
      (await server.database
              .customSelect('SELECT COUNT(*) AS n FROM contests')
              .getSingle())
          .read<int>('n');

  Matcher refusedAsMismatch() => throwsA(
    isA<ApiHttpError>()
        .having((e) => e.statusCode, 'status', 409)
        .having((e) => e.error?.code, 'code', profileAccountMismatchCode),
  );

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('soar_score_mismatch_test');
    server = await startEmbeddedServer(
      '${tempDir.path}${Platform.pathSeparator}soar_score.db',
    );
    client = ApiClient(
      baseUrl: server.baseUrl,
      tokenProvider: () async => server.secret,
    );
    auth = FakeAuthSession(signedIn: true);
    final epoch = AuthEpoch(auth);
    acting = ActingAccount(server, epoch);
    problems = [];
    signedInAs = accountA;
    claimer = LocalAccountClaimer(
      auth: auth,
      epoch: epoch,
      local: LocalAccountRepository(server.database),
      claim: (request) async {
        if (signedInAs != accountA) throw alreadyClaimed();
        return LocalAccountClaimDto(
          accountId: signedInAs,
          localAccountId: request.localAccountId,
          claimedAt: DateTime.utc(2026, 11, 8),
        );
      },
      onClaimed: (id, session) async {
        acting.actAs(id, epoch: session);
      },
      onSignedOut: acting.actAsLocal,
      onProblem: problems.add,
      onAccountMismatch: (session) =>
          acting.markProfileMismatch(epoch: session),
    );
  });

  tearDown(() async {
    claimer.stop();
    client.close();
    await server.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('another account is not served the claimed account\'s data', () async {
    // 1. A claims the installation and works.
    await createContest('A before the claim');
    claimer.start();
    await claimer.run();
    expect(acting.id, accountA);
    await createContest('A after the claim');
    expect(await client.contests(), hasLength(2));

    // 2. A signs out: A's data is still shown.
    await auth.signOut();
    expect(acting.id, accountA);
    expect(acting.profileMismatch, isFalse);
    expect(await client.contests(), hasLength(2));

    // 3-4. B signs in and the service refuses the claim.
    signedInAs = core.Id.create();
    await auth.signIn();
    await claimer.run();

    expect(problems.last, SyncProblem.accountMismatch);
    expect(acting.profileMismatch, isTrue);
    expect(acting.id, accountA, reason: 'nothing is attributed to B');

    // 5. Reads and writes are refused, and nothing was written.
    final before = await contestRows();
    await expectLater(client.contests(), refusedAsMismatch());
    await expectLater(createContest('B writes'), refusedAsMismatch());
    expect(await contestRows(), before);
    // The health probe stays open.
    await client.health();

    // B signs out: A's data is shown again.
    await auth.signOut();
    expect(acting.profileMismatch, isFalse);
    expect(await client.contests(), hasLength(2));
  });

  test('the owning account signing back in is served again', () async {
    claimer.start();
    await claimer.run();
    await auth.signOut();
    signedInAs = core.Id.create();
    await auth.signIn();
    await claimer.run();
    expect(acting.profileMismatch, isTrue);

    await auth.signOut();
    signedInAs = accountA;
    await auth.signIn();
    await claimer.run();

    expect(acting.profileMismatch, isFalse);
    await createContest('A again');
    expect((await client.contests()).map((c) => c.ownerAccountId).toSet(), {
      accountA,
    });
  });

  test('a refusal for a sign-in that has ended changes nothing', () async {
    claimer.start();
    await claimer.run();
    await auth.signOut();
    expect(acting.markProfileMismatch(epoch: -5), isFalse);
    expect(acting.profileMismatch, isFalse);
  });
}
