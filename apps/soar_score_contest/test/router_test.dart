import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app_mode_provider.dart';
import 'package:soar_score_contest/pages/contest_workspace_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/widgets/contest_shell.dart';

void main() {
  group('AppModeNotifier', () {
    test('defaults to offline mode false', () {
      final notifier = AppModeNotifier();
      expect(notifier.isOfflineMode, isFalse);
    });

    test('can be initialized with offline mode true', () {
      final notifier = AppModeNotifier(isOfflineMode: true);
      expect(notifier.isOfflineMode, isTrue);
    });

    test('enterOfflineMode sets isOfflineMode to true and notifies', () {
      final notifier = AppModeNotifier();
      var notificationCount = 0;
      notifier.addListener(() => notificationCount++);

      notifier.enterOfflineMode();
      expect(notifier.isOfflineMode, isTrue);
      expect(notificationCount, 1);

      // Calling again when already in offline mode does not notify
      notifier.enterOfflineMode();
      expect(notificationCount, 1);
    });

    test('exitOfflineMode sets isOfflineMode to false and notifies', () {
      final notifier = AppModeNotifier(isOfflineMode: true);
      var notificationCount = 0;
      notifier.addListener(() => notificationCount++);

      notifier.exitOfflineMode();
      expect(notifier.isOfflineMode, isFalse);
      expect(notificationCount, 1);

      // Calling again when already false does not notify
      notifier.exitOfflineMode();
      expect(notificationCount, 1);
    });
  });

  group('navigationGuard routing via routerConfig', () {
    testWidgets('redirects unknown path to landing path', (tester) async {
      final router = buildAppRouter(initialLocation: '/unknown-route');
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, landingPath);
    });

    testWidgets('allows landing path anonymously', (tester) async {
      final router = buildAppRouter(initialLocation: landingPath);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, landingPath);
    });

    testWidgets(
      'redirects route beyond landing to landing when offline mode is false',
      (tester) async {
        final appMode = AppModeNotifier(isOfflineMode: false);
        final router = buildAppRouter(
          initialLocation: '$landingPath/home',
          appMode: appMode,
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        expect(router.state.uri.path, landingPath);
      },
    );

    testWidgets('allows route beyond landing when offline mode is true', (
      tester,
    ) async {
      final appMode = AppModeNotifier(isOfflineMode: true);
      final router = buildAppRouter(
        initialLocation: '$landingPath/home',
        appMode: appMode,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '$landingPath/home');
    });

    testWidgets('wraps the main page in the shell and not the landing page', (
      tester,
    ) async {
      final appMode = AppModeNotifier(isOfflineMode: true);
      final router = buildAppRouter(
        initialLocation: homePath,
        appMode: appMode,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.byType(ContestShell), findsOneWidget);

      router.go(landingPath);
      await tester.pumpAndSettle();
      expect(find.byType(ContestShell), findsNothing);
    });

    testWidgets('wraps the contest workspace in the shell', (tester) async {
      final appMode = AppModeNotifier(isOfflineMode: true);
      final workspace = contestWorkspacePath(
        '01890a5d-ac96-774b-bcce-b302099a8057',
      );
      final router = buildAppRouter(
        initialLocation: workspace,
        appMode: appMode,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, workspace);
      expect(find.byType(ContestShell), findsOneWidget);
      expect(find.byType(ContestWorkspacePage), findsOneWidget);
    });

    testWidgets('reacts to appMode changes via refreshListenable', (
      tester,
    ) async {
      final appMode = AppModeNotifier(isOfflineMode: true);
      final router = buildAppRouter(
        initialLocation: '$landingPath/home',
        appMode: appMode,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '$landingPath/home');

      // Exiting offline mode triggers refreshListenable and redirects to landing
      appMode.exitOfflineMode();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, landingPath);
    });
  });
}
