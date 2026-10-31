import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/router.dart';

import '../support/fake_auth_session.dart';

void main() {
  group('navigation guard with a sign-in session', () {
    testWidgets('sends a signed-out user back to the landing page', (
      tester,
    ) async {
      final router = buildAppRouter(
        initialLocation: homePath,
        auth: FakeAuthSession(),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(router.state.uri.path, landingPath);
    });

    testWidgets('lets a signed-in user reach the main page', (tester) async {
      final router = buildAppRouter(
        initialLocation: homePath,
        auth: FakeAuthSession(signedIn: true),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(router.state.uri.path, homePath);
    });

    testWidgets('returns to the landing page when the user signs out', (
      tester,
    ) async {
      final session = FakeAuthSession(signedIn: true);
      final router = buildAppRouter(initialLocation: homePath, auth: session);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      expect(router.state.uri.path, homePath);

      await session.signOut();
      await tester.pumpAndSettle();

      expect(router.state.uri.path, landingPath);
    });
  });
}
