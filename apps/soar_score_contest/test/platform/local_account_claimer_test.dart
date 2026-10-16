import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/auth_epoch.dart';
import 'package:soar_score_contest/platform/local_account_claimer.dart';
import 'package:soar_score_contest/services/sync/sync_problem.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../support/fake_auth_session.dart';
import '../support/fake_local_account.dart';

void main() {
  final local = core.Id.create();
  final account = core.Id.create();
  late FakeAuthSession auth;
  late FakeLocalAccount localAccount;
  late List<core.Id> claimed;
  late int signedOut;
  late List<SyncProblem?> problems;
  late List<ClaimLocalAccountRequest> requests;
  late Future<LocalAccountClaimDto> Function(ClaimLocalAccountRequest) answer;
  late LocalAccountClaimer claimer;

  setUp(() {
    auth = FakeAuthSession(signedIn: true);
    localAccount = FakeLocalAccount(local);
    claimed = [];
    signedOut = 0;
    problems = [];
    requests = [];
    answer = (request) async => LocalAccountClaimDto(
      accountId: account,
      localAccountId: request.localAccountId,
      claimedAt: DateTime.utc(2026, 10, 13),
    );
    claimer = LocalAccountClaimer(
      auth: auth,
      epoch: AuthEpoch(auth),
      local: localAccount,
      claim: (request) {
        requests.add(request);
        return answer(request);
      },
      onClaimed: (id, _) async => claimed.add(id),
      onSignedOut: () => signedOut++,
      onProblem: problems.add,
    );
  });
  tearDown(() => claimer.stop());

  ApiHttpError httpError(int status) => ApiHttpError(
    'failed',
    statusCode: status,
    body: '',
    requestUri: Uri.parse('http://hosted.invalid/api/v1/account/local-claims'),
  );

  test('claims at start-up when already signed in', () async {
    claimer.start();
    await claimer.run();

    expect(requests.first.localAccountId, local);
    expect(localAccount.reassigned, [account]);
    expect(claimed, [account]);
    expect(problems.last, isNull);
  });

  test('claims when the director signs in', () async {
    auth = FakeAuthSession();
    claimer = LocalAccountClaimer(
      auth: auth,
      epoch: AuthEpoch(auth),
      local: localAccount,
      claim: (request) {
        requests.add(request);
        return answer(request);
      },
      onClaimed: (id, _) async => claimed.add(id),
      onSignedOut: () => signedOut++,
      onProblem: problems.add,
    )..start();
    await claimer.run();
    expect(requests, isEmpty, reason: 'signed out');

    await auth.signIn();
    await claimer.run();

    expect(claimed, [account]);
  });

  test('goes back to the Local account when the director signs out', () async {
    claimer.start();
    await claimer.run();
    expect(signedOut, 0);

    await auth.signOut();

    expect(signedOut, 1);
    expect(problems.last, isNull);
  });

  test(
    'a claim finishes for its account but does not outlive its session',
    () async {
      final other = core.Id.create();
      final firstAnswer = Completer<LocalAccountClaimDto>();
      var calls = 0;
      answer = (request) {
        if (calls++ == 0) return firstAnswer.future;
        return Future.value(
          LocalAccountClaimDto(
            accountId: other,
            localAccountId: request.localAccountId,
            claimedAt: DateTime.utc(2026, 10, 16),
          ),
        );
      };
      claimer.start();
      final first = claimer.run();
      await Future<void>.delayed(Duration.zero); // the claim is on its way

      // Account A signs out and account B signs in before A's claim answers.
      await auth.signOut();
      await auth.signIn();
      firstAnswer.complete(
        LocalAccountClaimDto(
          accountId: account,
          localAccountId: local,
          claimedAt: DateTime.utc(2026, 10, 16),
        ),
      );
      await first;

      expect(localAccount.reassigned, [
        account,
        other,
      ], reason: 'the service recorded A\'s claim, so A gets the data');
      expect(claimed, [other], reason: 'the app never acts as A');
      expect(requests, hasLength(2));
    },
  );

  test('a refusal for a finished session is not reported', () async {
    final firstAnswer = Completer<LocalAccountClaimDto>();
    answer = (_) => firstAnswer.future;
    claimer.start();
    final first = claimer.run();
    await Future<void>.delayed(Duration.zero); // the claim is on its way

    await auth.signOut();
    answer = (_) async => throw ApiNetworkError(
      'offline',
      requestUri: Uri.parse('http://hosted.invalid'),
    );
    firstAnswer.completeError(httpError(409));
    await first;

    expect(problems.last, isNull);
  });

  test('a claim recorded after sign-out still re-points the data', () async {
    final firstAnswer = Completer<LocalAccountClaimDto>();
    answer = (_) => firstAnswer.future;
    claimer.start();
    final first = claimer.run();
    await Future<void>.delayed(Duration.zero); // the claim is on its way

    await auth.signOut();
    firstAnswer.complete(
      LocalAccountClaimDto(
        accountId: account,
        localAccountId: local,
        claimedAt: DateTime.utc(2026, 10, 16),
      ),
    );
    await first;

    expect(localAccount.reassigned, [account]);
    expect(claimed, isEmpty, reason: 'nobody is signed in to act or sync');
  });

  test('does nothing before the Local account exists', () async {
    localAccount.id = null;

    await claimer.run();

    expect(requests, isEmpty);
  });

  test('an unreachable service leaves everything for a later run', () async {
    answer = (_) => throw ApiNetworkError(
      'offline',
      requestUri: Uri.parse('http://hosted.invalid'),
    );

    await claimer.run();

    expect(localAccount.reassigned, isEmpty);
    expect(claimed, isEmpty);
    expect(problems, isEmpty);
  });

  test('a refused claim is reported and nothing is re-pointed', () async {
    answer = (_) => throw httpError(409);

    await claimer.run();

    expect(problems.last, SyncProblem.accountClaimFailed);
    expect(localAccount.reassigned, isEmpty);
    expect(claimed, isEmpty);
  });

  test('an expired sign-in and a service error are told apart', () async {
    answer = (_) => throw httpError(401);
    await claimer.run();
    expect(problems.last, SyncProblem.signInExpired);

    answer = (_) => throw httpError(503);
    await claimer.run();
    expect(problems.last, SyncProblem.serverError);
  });

  test('a failed re-pointing is reported and sync is not started', () async {
    localAccount.reassignError = StateError('unique name');

    await claimer.run();

    expect(problems.last, SyncProblem.accountClaimBlocked);
    expect(claimed, isEmpty);
  });

  test('a later run clears the problem once it works', () async {
    answer = (_) => throw httpError(409);
    await claimer.run();
    expect(problems.last, SyncProblem.accountClaimFailed);

    answer = (request) async => LocalAccountClaimDto(
      accountId: account,
      localAccountId: request.localAccountId,
      claimedAt: DateTime.utc(2026, 10, 13),
    );
    await claimer.run();

    expect(problems.last, isNull);
    expect(claimed, [account]);
  });

  test(
    'signing out while the service answers still re-points the data',
    () async {
      answer = (request) async {
        await auth.signOut();
        return LocalAccountClaimDto(
          accountId: account,
          localAccountId: request.localAccountId,
          claimedAt: DateTime.utc(2026, 10, 13),
        );
      };

      await claimer.run();

      expect(localAccount.reassigned, [account]);
      expect(claimed, isEmpty);
    },
  );

  test('two runs at once make one claim', () async {
    await Future.wait([claimer.run(), claimer.run()]);

    expect(requests, hasLength(1));
  });

  test('signing out clears the problem', () async {
    answer = (_) => throw httpError(409);
    claimer.start();
    await claimer.run();

    await auth.signOut();

    expect(problems.last, isNull);
  });
}
