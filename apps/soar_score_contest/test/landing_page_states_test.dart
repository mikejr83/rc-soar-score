import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localization_delegates.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/auth/auth_session.dart';
import 'package:soar_score_contest/auth/auth_session_inherited.dart';
import 'package:soar_score_contest/auth/identity_provider_check.dart';
import 'package:soar_score_contest/connectivity_provider.dart';
import 'package:soar_score_contest/pages/landing_page.dart';

import 'support/fake_app_connectivity.dart';
import 'support/fake_auth_session.dart';
import 'support/fake_identity_provider_check.dart';

const _delegates = appLocalizationDelegates;
const _locales = [Locale('en')];

Widget _l10nApp(Widget home) => MaterialApp(
  localizationsDelegates: _delegates,
  supportedLocales: _locales,
  home: home,
);

Widget _app({
  required AuthSession session,
  required FakeIdentityProviderCheck check,
  FakeAppConnectivity? monitor,
  bool isWeb = true,
}) {
  return AppConnectivityInherited(
    monitor: monitor ?? FakeAppConnectivity(),
    child: AuthSessionInherited(
      session: session,
      child: _l10nApp(LandingPage(isWeb: isWeb, identityCheck: check)),
    ),
  );
}

Widget _bareApp({required Widget home, FakeAppConnectivity? monitor}) {
  return AppConnectivityInherited(
    monitor: monitor ?? FakeAppConnectivity(),
    child: _l10nApp(home),
  );
}

void main() {
  final l10n = AppLocalizationsEn();

  testWidgets('shows the loading row instead of the auth buttons while the '
      'check is in flight', (tester) async {
    final session = FakeAuthSession();
    final check = FakeIdentityProviderCheck();
    addTearDown(check.dispose);

    await tester.pumpWidget(_app(session: session, check: check));

    expect(check.probeCalls, 1);
    expect(find.text(l10n.landingCheckingSignIn), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(l10n.landingSignIn), findsNothing);
    expect(find.text(l10n.landingCreateAccount), findsNothing);
  });

  testWidgets('shows the auth buttons when the check resolves available', (
    tester,
  ) async {
    final session = FakeAuthSession();
    final check = FakeIdentityProviderCheck();
    addTearDown(check.dispose);

    await tester.pumpWidget(_app(session: session, check: check));
    check.status = IdentityProviderStatus.available;
    check.notifyListeners();
    await tester.pump();

    expect(find.text(l10n.landingCheckingSignIn), findsNothing);
    expect(find.text(l10n.landingSignIn), findsOneWidget);
    expect(find.text(l10n.landingCreateAccount), findsOneWidget);
  });

  testWidgets('shows the unavailable state with reason and a retry action', (
    tester,
  ) async {
    final session = FakeAuthSession();
    final check = FakeIdentityProviderCheck()
      ..status = IdentityProviderStatus.unavailable;
    check.lastError = 'Timed out';
    addTearDown(check.dispose);

    await tester.pumpWidget(_app(session: session, check: check, isWeb: false));

    expect(find.text(l10n.landingSignInUnavailable), findsOneWidget);
    expect(
      find.text(l10n.landingSignInUnavailableDetail('Timed out')),
      findsOneWidget,
    );
    expect(find.text(l10n.landingRetry), findsOneWidget);
    expect(find.text(l10n.landingSignIn), findsNothing);

    // Retry issues a new probe.
    final probesBefore = check.probeCalls;
    await tester.tap(find.text(l10n.landingRetry));
    await tester.pump();
    expect(check.probeCalls, probesBefore + 1);

    // Continue offline stays usable in the error state on desktop.
    final continueOffline = tester.widget<TextButton>(
      find.ancestor(
        of: find.text(l10n.landingContinueOffline),
        matching: find.byType(TextButton),
      ),
    );
    expect(continueOffline.onPressed, isNotNull);

    // Recovering hides the error and restores the buttons.
    check.status = IdentityProviderStatus.available;
    check.notifyListeners();
    await tester.pump();
    expect(find.text(l10n.landingSignIn), findsOneWidget);
    expect(find.text(l10n.landingSignInUnavailable), findsNothing);
  });

  testWidgets('renders the normal buttons without a check when no session '
      'is inherited', (tester) async {
    final monitor = FakeAppConnectivity();
    final check = FakeIdentityProviderCheck();
    addTearDown(check.dispose);

    await tester.pumpWidget(
      _bareApp(monitor: monitor, home: LandingPage(isWeb: true)),
    );

    expect(check.probeCalls, 0);
    expect(find.text(l10n.landingCheckingSignIn), findsNothing);
    expect(find.text(l10n.landingSignIn), findsOneWidget);
    expect(find.text(l10n.landingCreateAccount), findsOneWidget);
  });

  testWidgets('renders the signed-in area regardless of the probe status', (
    tester,
  ) async {
    final session = FakeAuthSession(signedIn: true, name: 'Pat Pilot');
    final check = FakeIdentityProviderCheck();
    addTearDown(check.dispose);

    await tester.pumpWidget(_app(session: session, check: check));

    expect(find.text(l10n.landingSignedInAs('Pat Pilot')), findsOneWidget);
    expect(find.text(l10n.landingContinue), findsOneWidget);
    expect(find.text(l10n.landingSignOut), findsOneWidget);
    expect(find.text(l10n.landingCheckingSignIn), findsNothing);
    expect(find.text(l10n.landingSignIn), findsNothing);

    check.status = IdentityProviderStatus.unavailable;
    check.lastError = 'HTTP 500';
    check.notifyListeners();
    await tester.pump();

    expect(find.text(l10n.landingContinue), findsOneWidget);
    expect(find.text(l10n.landingSignInUnavailable), findsNothing);
  });

  testWidgets('re-probes exactly once when the internet transitions to '
      'available', (tester) async {
    final session = FakeAuthSession();
    final monitor = FakeAppConnectivity()
      ..internetStatus = ConnectivityStatus.unavailable;
    final check = FakeIdentityProviderCheck();
    addTearDown(check.dispose);
    addTearDown(monitor.dispose);

    await tester.pumpWidget(
      _app(session: session, check: check, monitor: monitor),
    );
    expect(check.probeCalls, 1);

    // Recovery triggers exactly one re-probe.
    monitor.internetStatus = ConnectivityStatus.available;
    monitor.notifyListeners();
    await tester.pump();
    expect(check.probeCalls, 2);

    // A further available report (no transition) does not re-probe.
    monitor.internetStatus = ConnectivityStatus.available;
    monitor.notifyListeners();
    await tester.pump();
    expect(check.probeCalls, 2);

    // A transition away and back re-probes again.
    monitor.internetStatus = ConnectivityStatus.unavailable;
    monitor.notifyListeners();
    await tester.pump();
    expect(check.probeCalls, 2);

    monitor.internetStatus = ConnectivityStatus.available;
    monitor.notifyListeners();
    await tester.pump();
    expect(check.probeCalls, 3);
  });

  testWidgets('adopts the injected check when a session appears, and '
      'reuses it when the session dependency updates', (tester) async {
    final monitor = FakeAppConnectivity();
    final session = FakeAuthSession();
    final injected = FakeIdentityProviderCheck();
    addTearDown(injected.dispose);
    addTearDown(monitor.dispose);

    // No inherited session: no check is created and the one is untouched.
    await tester.pumpWidget(
      _bareApp(monitor: monitor, home: LandingPage(isWeb: true)),
    );
    expect(injected.probeCalls, 0);
    expect(find.text(l10n.landingCheckingSignIn), findsNothing);

    // A session appears: the page adopts the injected check and starts one
    // probe.
    await tester.pumpWidget(
      AppConnectivityInherited(
        monitor: monitor,
        child: AuthSessionInherited(
          session: session,
          child: _l10nApp(LandingPage(isWeb: true, identityCheck: injected)),
        ),
      ),
    );
    expect(injected.probeCalls, 1);
    expect(find.text(l10n.landingCheckingSignIn), findsOneWidget);

    // The session instance swaps: the existing check is reused, not
    // re-created or re-probed.
    await tester.pumpWidget(
      AppConnectivityInherited(
        monitor: monitor,
        child: AuthSessionInherited(
          session: FakeAuthSession(),
          child: _l10nApp(LandingPage(isWeb: true, identityCheck: injected)),
        ),
      ),
    );
    expect(injected.probeCalls, 1);
    expect(find.text(l10n.landingCheckingSignIn), findsOneWidget);

    // The session disappears: the injected check is released, not disposed
    // (the owner still owns it), and it remains usable.
    await tester.pumpWidget(
      _bareApp(monitor: monitor, home: LandingPage(isWeb: true)),
    );
    expect(injected.probeCalls, 1);
    expect(find.text(l10n.landingCheckingSignIn), findsNothing);
    expect(find.text(l10n.landingSignIn), findsOneWidget);
    injected.status = IdentityProviderStatus.available;
    injected.notifyListeners();
  });

  testWidgets('does not dispose an injected check when the page is removed '
      '(the owner keeps it)', (tester) async {
    final monitor = FakeAppConnectivity();
    final session = FakeAuthSession();
    final injected = FakeIdentityProviderCheck();
    addTearDown(injected.dispose);
    addTearDown(monitor.dispose);

    await tester.pumpWidget(
      AppConnectivityInherited(
        monitor: monitor,
        child: AuthSessionInherited(
          session: session,
          child: _l10nApp(LandingPage(isWeb: true, identityCheck: injected)),
        ),
      ),
    );
    expect(injected.probeCalls, 1);

    // The page is removed, but the check is owned by the test, so the page
    // must release it without disposing it.
    await tester.pumpWidget(_bareApp(monitor: monitor, home: const SizedBox()));

    // Still functional afterwards: a disposed notifier would throw.
    injected.status = IdentityProviderStatus.available;
    injected.notifyListeners();
    expect(injected.probeCalls, 1);
  });
}
