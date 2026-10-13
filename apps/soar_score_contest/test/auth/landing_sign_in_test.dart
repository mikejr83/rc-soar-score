import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/auth/auth_session.dart';
import 'package:soar_score_contest/auth/auth_session_inherited.dart';
import 'package:soar_score_contest/pages/landing_page.dart';
import 'package:soar_score_contest/connectivity_provider.dart';

import '../support/fake_app_connectivity.dart';
import '../support/fake_auth_session.dart';

Widget _app(AuthSession session) {
  final connectivity = FakeAppConnectivity();
  return AppConnectivityInherited(
    monitor: connectivity,
    child: AuthSessionInherited(
      session: session,
      child: const MaterialApp(home: LandingPage(isWeb: true)),
    ),
  );
}

void main() {
  testWidgets('Sign in starts Auth0 sign-in', (tester) async {
    final session = FakeAuthSession();
    await tester.pumpWidget(_app(session));

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(session.signInCalls, [false]);
  });

  testWidgets('Create account starts sign-in on the sign-up screen', (
    tester,
  ) async {
    final session = FakeAuthSession();
    await tester.pumpWidget(_app(session));

    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(session.signInCalls, [true]);
  });

  testWidgets('shows the reason when sign-in fails', (tester) async {
    final session = FakeAuthSession()
      ..signInError = const AuthException('Sign-in was cancelled.');
    await tester.pumpWidget(_app(session));

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Sign-in was cancelled.'), findsOneWidget);
  });

  testWidgets('says why the session ended', (tester) async {
    final session = FakeAuthSession()
      ..reason = 'Your session was ended. Sign in again.';
    await tester.pumpWidget(_app(session));

    expect(find.text('Your session was ended. Sign in again.'), findsOneWidget);
  });

  testWidgets('a signed-in user can continue or sign out', (tester) async {
    final session = FakeAuthSession(signedIn: true, name: 'Pat Pilot');
    await tester.pumpWidget(_app(session));

    expect(find.text('Signed in as Pat Pilot'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);

    await tester.tap(find.text('Sign out'));
    await tester.pump();

    expect(session.signOutCalls, 1);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
