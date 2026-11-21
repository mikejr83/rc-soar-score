import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/auth/auth_session.dart';
import 'package:soar_score_contest/auth/auth_session_inherited.dart';
import 'package:soar_score_contest/auth/identity_provider_check.dart';
import 'package:soar_score_contest/l10n/app_localization_delegates.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/pages/landing_page.dart';
import 'package:soar_score_contest/connectivity_provider.dart';

import '../support/fake_app_connectivity.dart';
import '../support/fake_auth_session.dart';
import '../support/fake_identity_provider_check.dart';

final _l10n = AppLocalizationsEn();

Widget _app(AuthSession session, IdentityProviderCheck check) {
  final connectivity = FakeAppConnectivity();
  return AppConnectivityInherited(
    monitor: connectivity,
    child: AuthSessionInherited(
      session: session,
      child: MaterialApp(
        localizationsDelegates: appLocalizationDelegates,
        home: LandingPage(isWeb: true, identityCheck: check),
      ),
    ),
  );
}

/// A stand-in check that is already resolved, so the page renders the
/// normal auth buttons without probing a real provider.
FakeIdentityProviderCheck _availableCheck() {
  final check = FakeIdentityProviderCheck(
    status: IdentityProviderStatus.available,
  )..probeCalls = 1;
  addTearDown(check.dispose);
  return check;
}

void main() {
  testWidgets('Sign in starts Auth0 sign-in', (tester) async {
    final session = FakeAuthSession();
    final check = _availableCheck();
    await tester.pumpWidget(_app(session, check));

    await tester.tap(find.text(_l10n.landingSignIn));
    await tester.pump();

    expect(session.signInCalls, [false]);
  });

  testWidgets('Create account starts sign-in on the sign-up screen', (
    tester,
  ) async {
    final session = FakeAuthSession();
    final check = _availableCheck();
    await tester.pumpWidget(_app(session, check));

    await tester.tap(find.text(_l10n.landingCreateAccount));
    await tester.pump();

    expect(session.signInCalls, [true]);
  });

  testWidgets('shows the reason when sign-in fails', (tester) async {
    final session = FakeAuthSession()
      ..signInError = const AuthException('Sign-in was cancelled.');
    final check = _availableCheck();
    await tester.pumpWidget(_app(session, check));

    await tester.tap(find.text(_l10n.landingSignIn));
    await tester.pump();

    expect(find.text('Sign-in was cancelled.'), findsOneWidget);
  });

  testWidgets('says why the session ended', (tester) async {
    final session = FakeAuthSession()
      ..reason = 'Your session was ended. Sign in again.';
    final check = _availableCheck();
    await tester.pumpWidget(_app(session, check));

    expect(find.text('Your session was ended. Sign in again.'), findsOneWidget);
  });

  testWidgets('a signed-in user can continue or sign out', (tester) async {
    final session = FakeAuthSession(signedIn: true, name: 'Pat Pilot');
    final check = _availableCheck();
    await tester.pumpWidget(_app(session, check));

    expect(find.text(_l10n.landingSignedInAs('Pat Pilot')), findsOneWidget);
    expect(find.text(_l10n.landingContinue), findsOneWidget);
    expect(find.text(_l10n.landingSignIn), findsNothing);

    await tester.tap(find.text(_l10n.landingSignOut));
    await tester.pump();

    expect(session.signOutCalls, 1);
    expect(find.text(_l10n.landingSignIn), findsOneWidget);
  });
}
