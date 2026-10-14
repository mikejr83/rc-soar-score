import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/auth/auth_session_inherited.dart';
import 'package:soar_score_contest/connectivity_provider.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/widgets/contest_shell.dart';

import '../support/fake_app_connectivity.dart';
import '../support/fake_auth_session.dart';

void main() {
  Widget app(FakeAuthSession session, String initialLocation) {
    final router = buildAppRouter(
      initialLocation: initialLocation,
      auth: session,
    );
    addTearDown(router.dispose);
    return AppConnectivityInherited(
      monitor: FakeAppConnectivity(),
      child: AuthSessionInherited(
        session: session,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  testWidgets('signing in on the landing page opens the main page', (
    tester,
  ) async {
    final session = FakeAuthSession();
    await tester.pumpWidget(app(session, landingPath));
    await tester.pumpAndSettle();
    expect(find.byType(ContestShell), findsNothing);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.byType(ContestShell), findsOneWidget);
    expect(find.text('Contests'), findsWidgets);
  });

  testWidgets('a restored session skips the landing page', (tester) async {
    final session = FakeAuthSession(signedIn: true, name: 'Pat Pilot');
    await tester.pumpWidget(app(session, landingPath));
    await tester.pumpAndSettle();

    expect(find.byType(ContestShell), findsOneWidget);
  });

  testWidgets('a signed-out user stays on the landing page', (tester) async {
    final session = FakeAuthSession();
    await tester.pumpWidget(app(session, landingPath));
    await tester.pumpAndSettle();

    expect(find.byType(ContestShell), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('signing out returns to the landing page', (tester) async {
    final session = FakeAuthSession(signedIn: true);
    await tester.pumpWidget(app(session, homePath));
    await tester.pumpAndSettle();
    expect(find.byType(ContestShell), findsOneWidget);

    await session.signOut();
    await tester.pumpAndSettle();

    expect(find.byType(ContestShell), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
