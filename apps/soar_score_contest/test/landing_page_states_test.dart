import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/auth/auth_session.dart';
import 'package:soar_score_contest/auth/auth_session_inherited.dart';
import 'package:soar_score_contest/auth/identity_provider_check.dart';
import 'package:soar_score_contest/connectivity_provider.dart';
import 'package:soar_score_contest/pages/landing_page.dart';

import 'support/fake_app_connectivity.dart';
import 'support/fake_auth_session.dart';
import 'support/fake_identity_provider_check.dart';

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
      child: MaterialApp(
        home: LandingPage(isWeb: isWeb, identityCheck: check),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the loading row instead of the auth buttons while the '
      'check is in flight', (tester) async {
    final session = FakeAuthSession();
    final check = FakeIdentityProviderCheck();
    addTearDown(check.dispose);

    await tester.pumpWidget(_app(session: session, check: check));

    expect(check.probeCalls, 1);
    expect(find.text('Checking sign-in…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    expect(find.text('Create account'), findsNothing);
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

    expect(find.text('Checking sign-in…'), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('shows the unavailable state with reason and a retry action', (
    tester,
  ) async {
    final session = FakeAuthSession();
    final check = FakeIdentityProviderCheck()..status = IdentityProviderStatus.unavailable;
    check.lastError = 'Timed out';
    addTearDown(check.dispose);

    await tester.pumpWidget(_app(session: session, check: check, isWeb: false));

    expect(find.text('Sign-in unavailable'), findsOneWidget);
    expect(
      find.text('The identity provider is currently unreachable: Timed out.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);

    // Retry issues a new probe.
    final probesBefore = check.probeCalls;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(check.probeCalls, probesBefore + 1);

    // Continue offline stays usable in the error state on desktop.
    final continueOffline = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Continue offline'),
        matching: find.byType(TextButton),
      ),
    );
    expect(continueOffline.onPressed, isNotNull);

    // Recovering hides the error and restores the buttons.
    check.status = IdentityProviderStatus.available;
    check.notifyListeners();
    await tester.pump();
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Sign-in unavailable'), findsNothing);
  });

  testWidgets('renders the normal buttons without a check when no session '
      'is inherited', (tester) async {
    final monitor = FakeAppConnectivity();
    final check = FakeIdentityProviderCheck();
    addTearDown(check.dispose);

    await tester.pumpWidget(
      AppConnectivityInherited(
        monitor: monitor,
        child: MaterialApp(home: LandingPage(isWeb: true)),
      ),
    );

    expect(check.probeCalls, 0);
    expect(find.text('Checking sign-in…'), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('renders the signed-in area regardless of the probe status', (
    tester,
  ) async {
    final session = FakeAuthSession(signedIn: true, name: 'Pat Pilot');
    final check = FakeIdentityProviderCheck();
    addTearDown(check.dispose);

    await tester.pumpWidget(_app(session: session, check: check));

    expect(find.text('Signed in as Pat Pilot'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Checking sign-in…'), findsNothing);
    expect(find.text('Sign in'), findsNothing);

    check.status = IdentityProviderStatus.unavailable;
    check.lastError = 'HTTP 500';
    check.notifyListeners();
    await tester.pump();

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Sign-in unavailable'), findsNothing);
  });

  testWidgets('re-probes exactly once when the internet transitions to '
      'available', (tester) async {
    final session = FakeAuthSession();
    final monitor = FakeAppConnectivity()
      ..internetStatus = ConnectivityStatus.unavailable;
    final check = FakeIdentityProviderCheck();
    addTearDown(check.dispose);
    addTearDown(monitor.dispose);

    await tester.pumpWidget(_app(session: session, check: check, monitor: monitor));
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
      AppConnectivityInherited(
        monitor: monitor,
        child: const MaterialApp(home: LandingPage(isWeb: true)),
      ),
    );
    expect(injected.probeCalls, 0);
    expect(find.text('Checking sign-in…'), findsNothing);

    // A session appears: the page adopts the injected check and starts one
    // probe.
    await tester.pumpWidget(
      AppConnectivityInherited(
        monitor: monitor,
        child: AuthSessionInherited(
          session: session,
          child: MaterialApp(
            home: LandingPage(isWeb: true, identityCheck: injected),
          ),
        ),
      ),
    );
    expect(injected.probeCalls, 1);
    expect(find.text('Checking sign-in…'), findsOneWidget);

    // The session instance swaps: the existing check is reused, not
    // re-created or re-probed.
    await tester.pumpWidget(
      AppConnectivityInherited(
        monitor: monitor,
        child: AuthSessionInherited(
          session: FakeAuthSession(),
          child: MaterialApp(
            home: LandingPage(isWeb: true, identityCheck: injected),
          ),
        ),
      ),
    );
    expect(injected.probeCalls, 1);
    expect(find.text('Checking sign-in…'), findsOneWidget);

    // The session disappears: the injected check is released, not disposed
    // (the owner still owns it), and it remains usable.
    await tester.pumpWidget(
      AppConnectivityInherited(
        monitor: monitor,
        child: const MaterialApp(home: LandingPage(isWeb: true)),
      ),
    );
    expect(injected.probeCalls, 1);
    expect(find.text('Checking sign-in…'), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
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
          child: MaterialApp(
            home: LandingPage(isWeb: true, identityCheck: injected),
          ),
        ),
      ),
    );
    expect(injected.probeCalls, 1);

    // The page is removed, but the check is owned by the test, so the page
    // must release it without disposing it.
    await tester.pumpWidget(
      AppConnectivityInherited(
        monitor: monitor,
        child: const MaterialApp(home: SizedBox()),
      ),
    );

    // Still functional afterwards: a disposed notifier would throw.
    injected.status = IdentityProviderStatus.available;
    injected.notifyListeners();
    expect(injected.probeCalls, 1);
  });
}
