import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_banners.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/fake_app_connectivity.dart';
import '../support/matrix_test_support.dart';
import '../support/next_step_widget_support.dart';

const _offlineKey = ValueKey('workspace-banner-offline');
const _staleKey = ValueKey('workspace-banner-stale');
const _offlineText =
    "Offline. Scoring and the other controls keep working on this device and "
    "sync when you're back. Publishing, visibility and delisting need a "
    'connection.';

FakeAppConnectivity _offline() =>
    FakeAppConnectivity()..internetStatus = ConnectivityStatus.unavailable;

WorkspaceServer _completed() => WorkspaceServer(
  state: LifecycleState.completed,
  configuration: matrixConfiguration(),
  matrix: drawnMatrix(),
);

void main() {
  group('offline', () {
    testWidgets('shows the banner and keeps the page rendered', (tester) async {
      await pumpShellWorkspace(tester, _completed(), monitor: _offline());

      expect(find.text(_offlineText), findsOneWidget);
      expect(
        find.byKey(const ValueKey('workspace-section-next-step')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('next-step-card')), findsOneWidget);
    });

    testWidgets('has no banner while online', (tester) async {
      await pumpShellWorkspace(
        tester,
        _completed(),
        monitor: FakeAppConnectivity(),
      );
      expect(find.byKey(_offlineKey), findsNothing);
    });

    testWidgets('a server-only action is disabled with its reason', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpShellWorkspace(tester, _completed(), monitor: _offline());

      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('next-step-primary')),
      );
      expect(button.onPressed, isNull);
      expect(find.text('Needs a connection.'), findsOneWidget);
      final node = tester.getSemantics(
        find.byKey(const ValueKey('next-step-primary')),
      );
      expect(node.hint, contains('Needs a connection.'));
      handle.dispose();
    });

    testWidgets('going offline and back updates the page without a reload', (
      tester,
    ) async {
      final monitor = FakeAppConnectivity();
      final server = _completed();
      await pumpShellWorkspace(tester, server, monitor: monitor);
      final reads = server.contestReads;
      expect(find.byKey(_offlineKey), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('next-step-primary')),
            )
            .onPressed,
        isNotNull,
      );

      monitor.internetStatus = ConnectivityStatus.unavailable;
      monitor.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byKey(_offlineKey), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('next-step-primary')),
            )
            .onPressed,
        isNull,
      );

      monitor.internetStatus = ConnectivityStatus.available;
      monitor.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byKey(_offlineKey), findsNothing);
      expect(server.contestReads, reads);
    });

    testWidgets('is announced as a live region (the status role is web-only)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpShellWorkspace(tester, _completed(), monitor: _offline());
      final data = tester
          .getSemantics(find.byKey(_offlineKey))
          .getSemanticsData();
      // Native builds announce banners through the live region; the web role
      // mapping is covered in page_state_view_test.
      expect(data.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });

  group('stale page', () {
    testWidgets('shows with the offline banner at the same time', (
      tester,
    ) async {
      final server = WorkspaceServer(
        state: LifecycleState.configuring,
        lock: AdminLock.locked,
        configuration: matrixConfiguration(),
      )..rejectNext = 409;
      await pumpShellWorkspace(
        tester,
        server,
        monitor: _offline(),
        size: const Size(1000, 900),
      );

      await tester.tap(find.byKey(const ValueKey('next-step-primary')));
      await tester.pumpAndSettle();

      expect(find.byKey(_staleKey), findsOneWidget);
      expect(find.byKey(_offlineKey), findsOneWidget);
    });

    testWidgets('is announced as an alert and leaves the sections alone', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final server = WorkspaceServer(
        state: LifecycleState.configuring,
        lock: AdminLock.locked,
        configuration: matrixConfiguration(),
      )..rejectNext = 409;
      await pumpShellWorkspace(tester, server);
      final before = cardTitle(tester);

      await tester.tap(find.byKey(const ValueKey('next-step-primary')));
      await tester.pumpAndSettle();

      final data = tester
          .getSemantics(find.byKey(_staleKey))
          .getSemanticsData();
      expect(data.flagsCollection.isLiveRegion, isTrue);
      expect(cardTitle(tester), before);
      handle.dispose();
    });

    for (final status in [500, 503]) {
      testWidgets('a failed Refresh ($status) keeps the page and the banner', (
        tester,
      ) async {
        final server = WorkspaceServer(
          state: LifecycleState.configuring,
          lock: AdminLock.locked,
          configuration: matrixConfiguration(),
        )..rejectNext = 409;
        await pumpShellWorkspace(tester, server);
        final before = cardTitle(tester);
        await tester.tap(find.byKey(const ValueKey('next-step-primary')));
        await tester.pumpAndSettle();
        expect(find.byKey(_staleKey), findsOneWidget);

        server.contestStatus = status;
        await tester.tap(find.text('Refresh'));
        await tester.pumpAndSettle();

        expect(find.byKey(_staleKey), findsOneWidget);
        expect(find.byKey(const ValueKey('next-step-primary')), findsOneWidget);
        expect(cardTitle(tester), before);
      });
    }

    testWidgets('a failed Refresh over the network keeps the page', (
      tester,
    ) async {
      final server = WorkspaceServer(
        state: LifecycleState.configuring,
        lock: AdminLock.locked,
        configuration: matrixConfiguration(),
      )..rejectNext = 409;
      await pumpShellWorkspace(tester, server);
      await tester.tap(find.byKey(const ValueKey('next-step-primary')));
      await tester.pumpAndSettle();

      server.networkDown = true;
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();

      // The facts behind the cards fail too, so the card shows its own
      // retry; the workspace itself stays up, not the load-failed view.
      expect(find.byKey(_staleKey), findsOneWidget);
      expect(find.byKey(const ValueKey('workspace-banners')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('workspace-state-action')),
        findsNothing,
      );
    });

    testWidgets('a Refresh that works clears the banner', (tester) async {
      final server = WorkspaceServer(
        state: LifecycleState.configuring,
        lock: AdminLock.locked,
        configuration: matrixConfiguration(),
      )..rejectNext = 409;
      await pumpShellWorkspace(tester, server);
      await tester.tap(find.byKey(const ValueKey('next-step-primary')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();

      expect(find.byKey(_staleKey), findsNothing);
    });
  });

  group('the banners widget', () {
    Widget app({ThemeMode mode = ThemeMode.light, double scale = 1}) =>
        MaterialApp(
          themeMode: mode,
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: WorkspaceBanners(
                offline: true,
                localCopyTime: 'Sun Oct 18, 16:40',
                staleChange: 'administration',
                onRetry: () {},
                onRefresh: () {},
              ),
            ),
          ),
        );

    testWidgets('the unavailable banner has the design copy and Try again', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      expect(
        find.text(
          "Can't reach the Soar Score server. Showing this device's copy from "
          'Sun Oct 18, 16:40. Scoring still works here and will sync; '
          'publishing, visibility and delisting are off until the server is '
          'back.',
        ),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets(
      'the offline banner on the web does not promise local scoring',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: WorkspaceBanners(offline: true, keepsLocalData: false),
            ),
          ),
        );
        expect(find.textContaining('Offline.'), findsOneWidget);
        expect(find.textContaining('keep working'), findsNothing);
        expect(find.textContaining('sync'), findsNothing);
      },
    );

    for (final mode in ThemeMode.values.where((m) => m != ThemeMode.system)) {
      testWidgets('fits at 200% text scale in a narrow window, $mode', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(app(mode: mode, scale: 2));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('with nothing to say, shows nothing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: WorkspaceBanners())),
      );
      expect(find.byKey(_offlineKey), findsNothing);
      expect(find.byKey(_staleKey), findsNothing);
    });
  });
}
