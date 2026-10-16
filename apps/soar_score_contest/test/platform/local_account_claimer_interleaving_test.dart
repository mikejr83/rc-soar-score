import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/auth_epoch.dart';
import 'package:soar_score_contest/platform/local_account_claimer.dart';
import 'package:soar_score_contest/services/sync/sync_problem.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../support/fake_local_account.dart';
import '../support/gated_auth_session.dart';

/// Every await of a claim, paused while the sign-in changes, then resumed.
/// The service is a small stand-in that records the first claimant of a Local
/// account and refuses any other, like the real one.
void main() {
  final local = core.Id.create();
  final accounts = {'A': core.Id.create(), 'B': core.Id.create()};
  late GatedAuthSession auth;
  late AuthEpoch epoch;
  late FakeLocalAccount localAccount;
  late ApiClient remote;
  late List<String> requests; // the token each claim request carried
  late Map<core.Id, core.Id> claimedBy; // the service's records
  late List<(core.Id, int)> claimed;
  late List<SyncProblem?> problems;
  late int signedOut;
  late LocalAccountClaimer claimer;

  LocalAccountClaimer newClaimer() => LocalAccountClaimer(
    auth: auth,
    epoch: epoch,
    local: localAccount,
    claim: remote.claimLocalAccount,
    onClaimed: (id, session) async => claimed.add((id, session)),
    onSignedOut: () => signedOut++,
    onProblem: problems.add,
  );

  setUp(() {
    auth = GatedAuthSession(signedIn: true);
    epoch = AuthEpoch(auth);
    localAccount = FakeLocalAccount(local);
    requests = [];
    claimedBy = {};
    claimed = [];
    problems = [];
    signedOut = 0;
    remote = ApiClient(
      baseUrl: Uri.parse('http://hosted.invalid'),
      tokenProvider: epoch.boundToken(auth.accessToken),
      httpClient: MockClient((request) async {
        final token = request.headers['authorization']!.substring(7);
        requests.add(token);
        final account = accounts[token.substring('token-'.length)]!;
        final localId = core.Id.parse(
          (jsonDecode(request.body) as Map)['local_account_id'] as String,
        );
        final owner = claimedBy.putIfAbsent(localId, () => account);
        if (owner != account) {
          return http.Response(
            jsonEncode({
              'error': {'code': 'already_claimed', 'message': 'claimed'},
            }),
            409,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode(
            LocalAccountClaimDto(
              accountId: account,
              localAccountId: localId,
              claimedAt: DateTime.utc(2026, 10, 16),
            ).toJson(),
          ),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    claimer = newClaimer();
  });

  tearDown(() {
    claimer.stop();
    epoch.close();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('while the Local account is looked up', () {
    test('a claim is not sent for a sign-in that ended', () async {
      localAccount.findGate = Completer<void>();
      claimer.start();
      await settle();

      await auth.signOut();
      localAccount.findGate!.complete();
      await claimer.run();

      expect(requests, isEmpty);
      expect(claimed, isEmpty);
    });
  });

  group('while the access token is looked up', () {
    test('A\'s claim is never sent with B\'s token', () async {
      auth.gate = Completer<void>();
      claimer.start();
      await settle();

      await auth.switchTo('B');
      auth.gate!.complete();
      await claimer.run();

      expect(requests, ['token-B'], reason: 'only B\'s own claim goes out');
      expect(localAccount.reassigned, [accounts['B']]);
      expect(claimed.map((c) => c.$1), [accounts['B']]);
    });

    test('a sign-out drops the claim', () async {
      auth.gate = Completer<void>();
      claimer.start();
      await settle();

      await auth.signOut();
      auth.gate!.complete();
      await claimer.run();

      expect(requests, isEmpty);
      expect(localAccount.reassigned, isEmpty);
      expect(claimed, isEmpty);
    });
  });

  group('while the Local data is re-pointed', () {
    test('A keeps the data and B\'s claim is refused', () async {
      localAccount.reassignGate = Completer<void>();
      claimer.start();
      await settle();
      await settle();
      expect(claimedBy[local], accounts['A'], reason: 'the service recorded A');

      await auth.switchTo('B');
      localAccount.reassignGate!.complete();
      await claimer.run();

      expect(localAccount.reassigned.first, accounts['A']);
      expect(
        claimed.where((c) => c.$1 == accounts['A']),
        isEmpty,
        reason: 'the app never acts as A for B\'s sign-in',
      );
      expect(requests, ['token-A', 'token-B']);
      expect(problems.last, SyncProblem.accountClaimFailed);
      expect(claimed, isEmpty, reason: 'B owns nothing on this installation');
    });

    test(
      'a sign-out leaves the data with the account that claimed it',
      () async {
        localAccount.reassignGate = Completer<void>();
        claimer.start();
        await settle();
        await settle();

        await auth.signOut();
        localAccount.reassignGate!.complete();
        await claimer.run();

        expect(localAccount.reassigned, [accounts['A']]);
        expect(claimed, isEmpty);
        expect(signedOut, 1);
      },
    );
  });

  group('a restart', () {
    test(
      'after the service recorded the claim finishes the re-pointing',
      () async {
        localAccount.reassignError = StateError('the app was killed');
        claimer.start();
        await claimer.run();
        expect(claimedBy[local], accounts['A']);
        expect(localAccount.reassigned, isEmpty);
        expect(problems.last, SyncProblem.accountClaimBlocked);
        claimer.stop();
        epoch.close();

        // A new start: new epoch, new claimer, the same installation.
        localAccount.reassignError = null;
        epoch = AuthEpoch(auth);
        claimer = newClaimer()..start();
        await claimer.run();

        expect(requests, ['token-A', 'token-A']);
        expect(localAccount.reassigned, [accounts['A']]);
        expect(claimed.map((c) => c.$1), [accounts['A']]);
        expect(problems.last, isNull);
      },
    );

    test('another account on a half-claimed installation is refused, then '
        'the first account completes it', () async {
      localAccount.reassignError = StateError('the app was killed');
      claimer.start();
      await claimer.run();
      claimer.stop();
      epoch.close();
      localAccount.reassignError = null;

      await auth.switchTo('B');
      epoch = AuthEpoch(auth);
      claimer = newClaimer()..start();
      await claimer.run();
      expect(problems.last, SyncProblem.accountClaimFailed);
      expect(localAccount.reassigned, isEmpty, reason: 'not B\'s to take');
      expect(claimed, isEmpty);

      await auth.switchTo('A');
      await claimer.run();
      expect(localAccount.reassigned, [accounts['A']]);
      expect(claimed.map((c) => c.$1), [accounts['A']]);
    });
  });

  group('closing the app', () {
    test('while the token is looked up sends nothing', () async {
      auth.gate = Completer<void>();
      claimer.start();
      await settle();

      claimer.stop();
      epoch.close();
      auth.gate!.complete();
      await claimer.run();

      expect(requests, isEmpty);
      expect(localAccount.reassigned, isEmpty);
    });

    test('while the data is re-pointed starts nothing afterwards', () async {
      localAccount.reassignGate = Completer<void>();
      claimer.start();
      await settle();
      await settle();

      claimer.stop();
      epoch.close();
      localAccount.reassignGate!.complete();
      await settle();

      expect(claimed, isEmpty);
      expect(problems.where((p) => p != null), isEmpty);
    });
  });
}
