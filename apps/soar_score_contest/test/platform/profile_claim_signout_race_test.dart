import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/server/profile_access.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../support/claimed_profile_harness.dart';

/// A sign-out that lands between the re-pointing of the Local data and what
/// follows it must not leave the process thinking the data is still the
/// Local account's.
void main() {
  late Directory tempDir;
  late ClaimedProfileHarness app;
  final accountA = core.Id.create();

  /// Closed to B: unverified until B's claim is answered, mismatched after.
  Matcher refusedWith(String code) => throwsA(
    isA<ApiHttpError>()
        .having((e) => e.statusCode, 'status', 409)
        .having(
          (e) => e.error?.code,
          'code',
          anyOf(code, profileAccountMismatchCode),
        ),
  );

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('soar_score_race_test');
    app = await ClaimedProfileHarness.open(
      tempDir,
      subject: 'auth0|a',
      claim: (request) async {
        if (app.auth.subject != 'auth0|a') throw alreadyClaimedError();
        return claimedBy(accountA, request);
      },
    );
  });

  tearDown(() async {
    await app.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('sign-out after the data moved keeps the claimed owner', () async {
    app.afterReassign = () async {
      app.afterReassign = null;
      await app.auth.signOut();
    };

    await app.claimer.run();

    // The ownership refresh is kept; the stale sign-in is not activated.
    expect(app.server.actingAccountId, accountA);
    expect(app.acting.lease(), isNull);
    expect(app.acting.leaseFor(accountA), isNull);
    expect(app.acting.profileAccess, ProfileAccess.verified);

    // Signed-out work belongs to the claimed account and is usable.
    final contest = await app.createContest('Written while signed out');
    expect(contest.ownerAccountId, accountA);
    expect(await app.client.contests(), hasLength(1));

    // A different user is checked against the persisted owner.
    await app.auth.signInAs('auth0|b');
    expect(app.acting.profileAccess, ProfileAccess.unverified);
    final rows = await app.contestRows();
    await expectLater(
      app.client.contests(),
      refusedWith(profileUnverifiedCode),
    );
    await expectLater(
      app.createContest('B writes'),
      refusedWith(profileUnverifiedCode),
    );
    expect(await app.contestRows(), rows);

    // The owner signing in is verified.
    await app.auth.signOut();
    await app.auth.signInAs('auth0|a');
    expect(app.acting.profileAccess, ProfileAccess.verified);
    expect(await app.client.contests(), hasLength(1));
  });

  test('another user signing in during the claim is closed out', () async {
    app.afterReassign = () async {
      app.afterReassign = null;
      await app.auth.signOut();
      await app.auth.signInAs('auth0|b');
    };

    await app.claimer.run();

    expect(app.server.actingAccountId, accountA);
    // B's own claim was refused after the owner's committed.
    expect(app.acting.profileAccess, ProfileAccess.mismatched);
    await expectLater(
      app.client.contests(),
      refusedWith(profileUnverifiedCode),
    );
  });
}
