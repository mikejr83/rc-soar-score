import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/server/profile_access.dart';
import 'package:soar_score_contest/services/sync/sync_problem.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../support/claimed_profile_harness.dart';

/// Account A claims the installation, signs out, and B signs in: B's claim is
/// refused, and the embedded API must not serve A's data to B.
void main() {
  late Directory tempDir;
  late ClaimedProfileHarness app;
  final accountA = core.Id.create();
  var serviceAccount = accountA;

  Matcher refusedWith(String code) => throwsA(
    isA<ApiHttpError>()
        .having((e) => e.statusCode, 'status', 409)
        .having((e) => e.error?.code, 'code', code),
  );

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('soar_score_mismatch_test');
    serviceAccount = accountA;
    app = await ClaimedProfileHarness.open(
      tempDir,
      subject: 'auth0|a',
      claim: (request) async {
        if (serviceAccount != accountA) throw alreadyClaimedError();
        return claimedBy(serviceAccount, request);
      },
    );
  });

  tearDown(() async {
    await app.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('another account is not served the claimed account data', () async {
    // 1. A claims the installation and works.
    await app.createContest('A before the claim');
    await app.claimer.run();
    expect(app.acting.id, accountA);
    await app.createContest('A after the claim');
    expect(await app.client.contests(), hasLength(2));

    // 2. A signs out: A's data is still shown.
    await app.auth.signOut();
    expect(app.acting.id, accountA);
    expect(app.acting.profileAccess, ProfileAccess.verified);
    expect(await app.client.contests(), hasLength(2));

    // 3-4. B signs in; the service refuses the claim.
    serviceAccount = core.Id.create();
    await app.auth.signInAs('auth0|b');
    await app.claimer.run();

    expect(app.problems.last, SyncProblem.accountMismatch);
    expect(app.acting.profileAccess, ProfileAccess.mismatched);
    expect(app.acting.id, accountA, reason: 'nothing is attributed to B');

    // 5. Reads and writes are refused, and nothing was written.
    final before = await app.contestRows();
    await expectLater(
      app.client.contests(),
      refusedWith(profileAccountMismatchCode),
    );
    await expectLater(
      app.createContest('B writes'),
      refusedWith(profileAccountMismatchCode),
    );
    expect(await app.contestRows(), before);
    await app.client.health();

    // B signs out: A's data is shown again.
    await app.auth.signOut();
    expect(app.acting.profileAccess, ProfileAccess.verified);
    expect(await app.client.contests(), hasLength(2));
  });

  test('the owning account signing back in is served again', () async {
    await app.claimer.run();
    await app.auth.signOut();
    serviceAccount = core.Id.create();
    await app.auth.signInAs('auth0|b');
    await app.claimer.run();
    expect(app.acting.profileAccess, ProfileAccess.mismatched);

    await app.auth.signOut();
    serviceAccount = accountA;
    await app.auth.signInAs('auth0|a');
    await app.claimer.run();

    expect(app.acting.profileAccess, ProfileAccess.verified);
    await app.createContest('A again');
    final owners = (await app.client.contests()).map((c) => c.ownerAccountId);
    expect(owners.toSet(), {accountA});
  });

  test('a refusal for a sign-in that has ended changes nothing', () async {
    await app.claimer.run();
    await app.auth.signOut();
    expect(app.acting.markProfileMismatch(epoch: -5), isFalse);
    expect(app.acting.profileAccess, ProfileAccess.verified);
  });
}
