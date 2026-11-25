import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soar_score_self_score/auth/auth_scope.dart';
import 'package:soar_score_self_score/auth/auth_session.dart';
import 'package:soar_score_self_score/auth/e2e_auth_session.dart';
import 'package:soar_score_self_score/l10n/app_localization_delegates.dart';
import 'package:soar_score_self_score/pages/home_page.dart';
import 'package:soar_score_self_score/router.dart';

/// A session that records what the landing page asks of it.
class _FakeAuth extends E2eAuthSession {
  final calls = <String>[];
  bool failNext = false;
  bool failSignOut = false;
  Completer<void>? signOutGate;

  @override
  Future<void> signOut() async {
    calls.add('sign-out');
    await signOutGate?.future;
    if (failSignOut) throw StateError('logout failed');
    await super.signOut();
  }

  @override
  Future<void> signIn({bool createAccount = false}) async {
    calls.add(createAccount ? 'sign-up' : 'sign-in');
    if (failNext) throw const AuthException('no');
    await super.signIn(createAccount: createAccount);
  }
}

Future<void> _pump(WidgetTester tester, AuthSession auth) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AuthScope(
      session: auth,
      child: MaterialApp.router(
        localizationsDelegates: appLocalizationDelegates,
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
            GoRoute(
              path: contestsPath,
              builder: (context, state) =>
                  const Scaffold(body: Text('Contests page')),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('signed out, Sign in and Sign up start the right flow', (
    tester,
  ) async {
    final auth = _FakeAuth();
    await _pump(tester, auth);

    expect(find.textContaining('coming in a future release'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(auth.calls, ['sign-in']);
  });

  testWidgets('Sign up opens the sign-up page', (tester) async {
    final auth = _FakeAuth();
    await _pump(tester, auth);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign up'));
    await tester.pump();
    expect(auth.calls, ['sign-up']);
  });

  testWidgets('a sign-in that cannot start says so and stays signed out', (
    tester,
  ) async {
    final auth = _FakeAuth()..failNext = true;
    await _pump(tester, auth);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Sign-in could not be started. Try again.'), findsOne);
    expect(auth.isSignedIn, isFalse);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('signed in, the page shows the pilot and the way on', (
    tester,
  ) async {
    final auth = _FakeAuth();
    await auth.signIn();
    await _pump(tester, auth);

    expect(find.text('Signed in as Penny Pilot'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'My contests'));
    await tester.pumpAndSettle();
    expect(find.text('Contests page'), findsOneWidget);
  });

  testWidgets('Sign out returns to the signed-out page', (tester) async {
    final auth = _FakeAuth();
    await auth.signIn();
    await _pump(tester, auth);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(auth.isSignedIn, isFalse);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('a sign-out that fails says so and stays signed in', (
    tester,
  ) async {
    final auth = _FakeAuth();
    await auth.signIn();
    auth.failSignOut = true;
    await _pump(tester, auth);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign-out could not be completed. Try again.'), findsOne);
    expect(auth.isSignedIn, isTrue);
  });

  test('the E2E session gives the E2E server its pilot token', () async {
    final auth = E2eAuthSession();
    expect(await auth.accessToken(), isNull);
    await auth.signIn();
    expect(await auth.accessToken(), e2ePilotToken);
    await auth.signOut();
    expect(await auth.accessToken(), isNull);
  });

  testWidgets('Sign out is off while pending, and retry stays on offer', (
    tester,
  ) async {
    final auth = _FakeAuth();
    await auth.signIn();
    auth.signOutGate = Completer<void>();
    await _pump(tester, auth);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pump();
    // The request is out: the page stays signed in and the button is off, so
    // a second tap cannot send a second request.
    expect(find.text('Signed in as Penny Pilot'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Sign out'),
          )
          .onPressed,
      isNull,
    );

    auth.failSignOut = true;
    auth.signOutGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Sign-out could not be completed. Try again.'), findsOne);
    expect(find.text('Signed in as Penny Pilot'), findsOneWidget);
    final retry = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Sign out'),
    );
    expect(retry.onPressed, isNotNull);

    auth
      ..failSignOut = false
      ..signOutGate = null;
    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(auth.isSignedIn, isFalse);
    expect(auth.calls.where((c) => c == 'sign-out'), hasLength(2));
  });
}
