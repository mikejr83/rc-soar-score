import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/auth_epoch.dart';
import 'package:soar_score_contest/platform/local_account_claimer.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../support/fake_auth_session.dart';
import '../support/fake_local_account.dart';

void main() {
  final local = core.Id.create();
  final account = core.Id.create();
  late FakeLocalAccount localAccount;
  late core.AccountPreferences onService;
  late List<core.AccountPreferences> puts;
  late bool serviceDown;
  late LocalAccountClaimer claimer;

  setUp(() {
    final auth = FakeAuthSession(signedIn: true);
    localAccount = FakeLocalAccount(local);
    onService = core.AccountPreferences();
    puts = [];
    serviceDown = false;
    claimer = LocalAccountClaimer(
      auth: auth,
      epoch: AuthEpoch(auth),
      local: localAccount,
      claim: (request) async => LocalAccountClaimDto(
        accountId: account,
        localAccountId: request.localAccountId,
        claimedAt: DateTime.utc(2026, 10, 19),
      ),
      onClaimed: (_, _) async {},
      onSignedOut: () {},
      onProblem: (_) {},
      getPreferences: () async {
        if (serviceDown) {
          throw ApiNetworkError(
            'down',
            requestUri: Uri.parse(
              'http://hosted.invalid/api/v1/account/preferences',
            ),
          );
        }
        return onService;
      },
      putPreferences: (preferences) async {
        puts.add(preferences);
        return onService = preferences;
      },
    );
  });
  tearDown(() => claimer.stop());

  test('offline choices the account lacks move to the account', () async {
    localAccount.storedPreferences = core.AccountPreferences(
      preferredTimeZone: 'Europe/Rome',
      preferredLocale: 'en-US',
    );

    await claimer.run();

    expect(onService.preferredTimeZone, 'Europe/Rome');
    expect(onService.preferredLocale, 'en-US');
    expect(puts, hasLength(1));
  });

  test(
    'a choice the account already has stands over the offline one',
    () async {
      onService = core.AccountPreferences(preferredTimeZone: 'Asia/Tokyo');
      localAccount.storedPreferences = core.AccountPreferences(
        preferredTimeZone: 'Europe/Rome',
        preferredLocale: 'en-US',
      );

      await claimer.run();

      expect(onService.preferredTimeZone, 'Asia/Tokyo');
      expect(onService.preferredLocale, 'en-US');
      expect(localAccount.storedPreferences, onService);
    },
  );

  test('the installation shows the account\'s choices afterwards', () async {
    onService = core.AccountPreferences(preferredTimeZone: 'Asia/Tokyo');

    await claimer.run();

    expect(puts, isEmpty);
    expect(localAccount.storedPreferences, onService);
  });

  test('an unreachable service does not fail the claim', () async {
    serviceDown = true;
    localAccount.storedPreferences = core.AccountPreferences(
      preferredTimeZone: 'Europe/Rome',
    );

    await claimer.run();

    expect(localAccount.reassigned, [account]);
    expect(localAccount.storedPreferences.preferredTimeZone, 'Europe/Rome');
  });
}
