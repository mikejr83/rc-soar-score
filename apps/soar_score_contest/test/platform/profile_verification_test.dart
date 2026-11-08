import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/server/profile_access.dart';
import 'package:soar_score_contest/services/sync/sync_problem.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../support/claimed_profile_harness.dart';

/// The claimed account data is closed to a signed-in user until their
/// identity is checked: while the claim is in flight, and offline.
void main() {
  late Directory tempDir;
  late ClaimedProfileHarness app;
  final accountA = core.Id.create();
  var online = true;
  Completer<void>? hold;

  Matcher refusedWith(String code) => throwsA(
    isA<ApiHttpError>()
        .having((e) => e.statusCode, 'status', 409)
        .having((e) => e.error?.code, 'code', code),
  );

  /// A answers the claim; anyone else is refused; offline nothing arrives.
  Future<LocalAccountClaimDto> service(ClaimLocalAccountRequest request) async {
    await hold?.future;
    if (!online) throw unreachableError();
    if (app.auth.subject != 'auth0|a') throw alreadyClaimedError();
    return claimedBy(accountA, request);
  }

  setUp(() async {
    online = true;
    hold = null;
    tempDir = Directory.systemTemp.createTempSync('soar_score_verify_test');
    // A claims the installation and works in it, then the app is closed.
    app = await ClaimedProfileHarness.open(
      tempDir,
      subject: 'auth0|a',
      claim: service,
    );
    await app.claimer.run();
    await app.createContest('A contest');
    expect(app.acting.profileAccess, ProfileAccess.verified);
  });

  tearDown(() async {
    if (hold != null && !hold!.isCompleted) hold!.complete();
    await app.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('B signing in is refused until the claim answer arrives', () async {
    await app.auth.signOut();
    hold = Completer<void>();

    await app.auth.signInAs('auth0|b');

    // The claim is still on its way: B is not served A's data.
    expect(app.acting.profileAccess, ProfileAccess.unverified);
    final before = await app.contestRows();
    await expectLater(
      app.client.contests(),
      refusedWith(profileUnverifiedCode),
    );
    await expectLater(
      app.createContest('B writes'),
      refusedWith(profileUnverifiedCode),
    );
    expect(await app.contestRows(), before);

    hold!.complete();
    await app.claimer.run();
    expect(app.acting.profileAccess, ProfileAccess.mismatched);
    expect(app.problems.last, SyncProblem.accountMismatch);
  });

  test('a restored B session is refused before the claim completes', () async {
    hold = Completer<void>();
    await app.restart(subject: 'auth0|b');

    expect(app.acting.profileAccess, ProfileAccess.unverified);
    await expectLater(
      app.client.contests(),
      refusedWith(profileUnverifiedCode),
    );
    await app.client.health();
  });

  test('offline, a restored B session stays blocked', () async {
    online = false;
    await app.restart(subject: 'auth0|b');
    await app.claimer.run();

    expect(app.acting.profileAccess, ProfileAccess.unverified);
    expect(app.problems.last, SyncProblem.accountUnverified);
    final before = await app.contestRows();
    await expectLater(
      app.client.contests(),
      refusedWith(profileUnverifiedCode),
    );
    await expectLater(
      app.createContest('B writes'),
      refusedWith(profileUnverifiedCode),
    );
    expect(await app.contestRows(), before);

    // Signing out ends the block: the stored data is A's to see offline.
    await app.auth.signOut();
    expect(app.acting.profileAccess, ProfileAccess.verified);
    expect(await app.client.contests(), hasLength(1));
  });

  test('offline, the owning A session restores and works', () async {
    online = false;
    await app.restart(subject: 'auth0|a');
    await app.claimer.run();

    expect(app.acting.profileAccess, ProfileAccess.verified);
    expect(app.acting.id, accountA);
    expect(await app.client.contests(), hasLength(1));
    await app.createContest('A offline');
    expect(await app.client.contests(), hasLength(2));
  });

  test('a signed-out start shows the last account data', () async {
    online = false;
    await app.restart(subject: null);

    expect(app.acting.profileAccess, ProfileAccess.verified);
    expect(await app.client.contests(), hasLength(1));
  });

  test('a session with no known identity is not trusted', () async {
    online = false;
    await app.restart(subject: 'auth0|a');
    await app.auth.signOut();
    // Signed in, but the identity provider did not say who.
    await app.auth.signInAs(null);
    await app.claimer.run();

    expect(app.acting.profileAccess, ProfileAccess.unverified);
  });
}
