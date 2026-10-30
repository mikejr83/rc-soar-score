import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app_sync_provider.dart';
import 'package:soar_score_contest/connectivity_provider.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/services/storage/storage_monitor.dart';
import 'package:soar_score_contest/services/sync/app_sync_state.dart';
import 'package:soar_score_contest/services/sync/sync_scope_summary.dart';
import 'package:soar_score_contest/storage_provider.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/widgets/connectivity_indicator.dart';
import 'package:soar_score_contest/widgets/contest_status_bar.dart';

import '../support/fake_app_connectivity.dart';
import '../support/fake_app_sync.dart';

/// Hosts the status bar at the bottom of a page, the way the shell does,
/// optionally below a connectivity provider.
Widget _host({FakeAppConnectivity? monitor}) {
  Widget app = const MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          Expanded(child: SizedBox.shrink()),
          ContestStatusBar(),
        ],
      ),
    ),
  );
  if (monitor != null) {
    app = AppConnectivityInherited(monitor: monitor, child: app);
  }
  return app;
}

List<ConnectivityIndicatorKind> _indicatorKinds(WidgetTester tester) => tester
    .widgetList<ConnectivityIndicator>(find.byType(ConnectivityIndicator))
    .map((indicator) => indicator.kind)
    .toList();

void main() {
  testWidgets('spans the full width even inside a centering column', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    final screen = tester.getSize(find.byType(Scaffold));
    expect(tester.getSize(find.byType(ContestStatusBar)).width, screen.width);
    expect(find.text(ContestStatusBar.status), findsOneWidget);
  });

  testWidgets('shows no indicators without a connectivity monitor', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    expect(find.byType(ConnectivityIndicator), findsNothing);
  });

  testWidgets('shows the internet then the API indicator on the trailing '
      'side', (tester) async {
    final monitor = FakeAppConnectivity();
    addTearDown(monitor.dispose);
    await tester.pumpWidget(_host(monitor: monitor));

    expect(_indicatorKinds(tester), [
      ConnectivityIndicatorKind.internet,
      ConnectivityIndicatorKind.api,
    ]);

    final status = tester.getRect(find.text(ContestStatusBar.status));
    final api = tester.getRect(find.byType(ConnectivityIndicator).last);
    final bar = tester.getRect(find.byType(ContestStatusBar));
    expect(api.left, greaterThan(status.right));
    expect(bar.right - api.right, lessThan(32));
  });

  testWidgets('hides the internet indicator when the host cannot report '
      'connectivity', (tester) async {
    final monitor = FakeAppConnectivity()..supportsConnectivity = false;
    addTearDown(monitor.dispose);
    await tester.pumpWidget(_host(monitor: monitor));

    expect(_indicatorKinds(tester), [ConnectivityIndicatorKind.api]);
  });

  _syncAndStorage();
  _constrained();
}

Contest _contest() => Contest(
  id: Id.parse('019c0000-0000-7000-8000-000000000020'),
  name: 'Spring Meet',
  startDateTime: DateTime.utc(2026, 4, 15, 10),
  endDateTime: DateTime.utc(2026, 4, 16, 20),
  timezone: 'America/Denver',
  createdAt: DateTime.utc(2026, 4),
  updatedAt: DateTime.utc(2026, 4),
);

Widget _frame(Contest? contest, {FakeAppSync? sync, StorageMonitor? storage}) {
  Widget app = MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Column(
        children: [
          const Expanded(child: SizedBox.shrink()),
          ContestStatusBar(contest: contest),
        ],
      ),
    ),
  );
  if (storage != null) {
    app = StorageMonitorInherited(monitor: storage, child: app);
  }
  return AppSyncInherited(sync: sync ?? FakeAppSync(), child: app);
}

// ---- sync and storage ----
void _syncAndStorage() {
  testWidgets('shows the storage indicator before the connectivity chips', (
    tester,
  ) async {
    final storage = StorageMonitor(probe: () async {}, pollInterval: null);
    addTearDown(storage.dispose);
    await tester.pumpWidget(_frame(null, storage: storage));
    await tester.pump();

    expect(find.text('Local storage · Available'), findsOneWidget);
  });

  testWidgets('shows the contest\'s pending changes and last sync in the bar', (
    tester,
  ) async {
    final contest = _contest();
    final sync = FakeAppSync(
      state: AppSyncState(
        scopes: {
          ContestScopeKey(contest.id): SyncScopeSummary(
            pendingChanges: 3,
            lastSyncedAt: DateTime.utc(2026, 4, 15, 18, 2),
          ),
        },
      ),
    );
    await tester.pumpWidget(_frame(contest, sync: sync));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('contest-status-bar')),
        matching: find.textContaining('3 pending'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Synced '), findsOneWidget);
  });

  testWidgets('says Local only for a contest with no account', (tester) async {
    final contest = _contest();
    final sync = FakeAppSync(
      state: AppSyncState(
        scopes: {
          ContestScopeKey(contest.id): const SyncScopeSummary(localOnly: true),
        },
      ),
    );
    await tester.pumpWidget(_frame(contest, sync: sync));
    await tester.pump();

    expect(find.text('Local only'), findsOneWidget);
  });

  testWidgets('shows no sync entry outside a contest', (tester) async {
    await tester.pumpWidget(_frame(null));
    await tester.pump();

    expect(find.byKey(const ValueKey('shell-sync-status')), findsNothing);
  });

  testWidgets('keeps the same height with and without a selected contest', (
    tester,
  ) async {
    // The sync entry only exists in a contest; it must not inflate the bar.
    final contest = _contest();
    final sync = FakeAppSync(
      state: AppSyncState(
        scopes: {ContestScopeKey(contest.id): const SyncScopeSummary(localOnly: true)},
      ),
    );
    for (final width in [800.0, 360.0]) {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_frame(null));
      await tester.pump();
      final without = tester.getSize(find.byType(ContestStatusBar)).height;

      await tester.pumpWidget(_frame(contest, sync: sync));
      await tester.pump();
      final withContest = tester.getSize(find.byType(ContestStatusBar)).height;

      expect(withContest, without, reason: 'at ${width.round()}dp');
    }
  });
}

void _constrained() {
  for (final (width, scale) in [(360.0, 1.0), (360.0, 2.0), (800.0, 2.0)]) {
    testWidgets('fits every indicator at ${width}dp, text x$scale', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final contest = _contest();
      final storage = StorageMonitor(probe: () async {}, pollInterval: null);
      addTearDown(storage.dispose);
      final sync = FakeAppSync(
        state: AppSyncState(
          scopes: {
            ContestScopeKey(contest.id): SyncScopeSummary(
              pendingChanges: 12,
              rejectedChanges: 2,
              lastSyncedAt: DateTime.utc(2026, 4, 15, 18, 2),
            ),
          },
        ),
      );
      final monitor = FakeAppConnectivity();
      addTearDown(monitor.dispose);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: Size(width, 700),
            textScaler: TextScaler.linear(scale),
          ),
          child: AppConnectivityInherited(
            monitor: monitor,
            child: _frame(contest, sync: sync, storage: storage),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Local storage · Available'), findsOneWidget);
      expect(find.textContaining('12 pending'), findsOneWidget);
    });
  }
}
