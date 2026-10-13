import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app_mode_provider.dart';
import 'package:soar_score_contest/auth/auth_session_inherited.dart';
import 'package:soar_score_contest/widgets/shell_account_button.dart';

import '../support/fake_auth_session.dart';
import '../support/shell_test_router.dart';

const _menu = ValueKey('account-menu');

Future<void> _pump(
  WidgetTester tester, {
  FakeAuthSession? session,
  AppModeNotifier? mode,
}) async {
  final router = buildShellTestRouter();
  addTearDown(router.dispose);
  await pumpShellRouter(
    tester,
    router,
    wrap: (app) {
      var wrapped = app;
      if (session != null) {
        wrapped = AuthSessionInherited(session: session, child: wrapped);
      }
      if (mode != null) {
        wrapped = AppModeInherited(notifier: mode, child: wrapped);
      }
      return wrapped;
    },
  );
}

void main() {
  testWidgets('signed in: the menu names the user and signs out', (
    tester,
  ) async {
    final session = FakeAuthSession(signedIn: true, name: 'Pat Pilot');
    await _pump(tester, session: session);

    expect(find.byKey(const ValueKey('settings-button')), findsNothing);
    await tester.tap(find.byKey(_menu));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('account-name')), findsOneWidget);
    expect(find.text('Pat Pilot'), findsWidgets);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(session.signOutCalls, 1);
    expect(find.text('Landing stub'), findsOneWidget);
  });

  testWidgets('signed in: Settings shows the not-available dialog', (
    tester,
  ) async {
    await _pump(tester, session: FakeAuthSession(signedIn: true, name: 'Pat'));

    await tester.tap(find.byKey(_menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings is not available yet'), findsOneWidget);
  });

  testWidgets('signed in: the menu opens from the keyboard', (tester) async {
    await _pump(tester, session: FakeAuthSession(signedIn: true, name: 'Pat'));

    Focus.of(
      tester.element(
        find.descendant(
          of: find.byKey(_menu),
          matching: find.byType(CircleAvatar),
        ),
      ),
    ).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('signed out: a gear opens the not-available dialog', (
    tester,
  ) async {
    await _pump(tester, session: FakeAuthSession());

    expect(find.byKey(_menu), findsNothing);
    await tester.tap(find.byKey(const ValueKey('settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('Settings is not available yet'), findsOneWidget);
  });

  testWidgets('offline: no sign-out; Sign in leads to the landing page', (
    tester,
  ) async {
    final mode = AppModeNotifier(isOfflineMode: true);
    final session = FakeAuthSession();
    await _pump(tester, session: session, mode: mode);

    await tester.tap(find.byKey(_menu));
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(mode.isOfflineMode, isFalse);
    expect(find.text('Landing stub'), findsOneWidget);
  });

  testWidgets('shows on a narrow window without overflow', (tester) async {
    tester.view.physicalSize = const Size(500, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pump(tester, session: FakeAuthSession(signedIn: true, name: 'Pat'));

    expect(find.byType(ShellAccountButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
