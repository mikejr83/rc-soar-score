import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_contest/app_sync_provider.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/sync/app_sync_state.dart';
import 'package:soar_score_contest/services/sync/sync_scope_summary.dart';
import 'package:soar_score_contest/widgets/sync/shell_sync_status.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/fake_app_sync.dart';

Contest _contest() => Contest(
  id: Id.parse('019c0000-0000-7000-8000-000000000020'),
  name: 'Spring Meet',
  startDateTime: DateTime.utc(2026, 4, 15, 10),
  endDateTime: DateTime.utc(2026, 4, 16, 20),
  timezone: 'America/Denver',
  createdAt: DateTime.utc(2026, 4),
  updatedAt: DateTime.utc(2026, 4),
);

Future<GoRouter> _pump(
  WidgetTester tester,
  FakeAppSync sync, {
  bool inContest = true,
}) async {
  final contest = _contest();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: ShellSyncStatus(contest: inContest ? contest : null),
        ),
      ),
      GoRoute(
        path: contestSyncPath(contest.id.value),
        builder: (context, state) => const Text('sync page'),
      ),
    ],
  );
  await tester.pumpWidget(
    AppSyncInherited(
      sync: sync,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('shows nothing in a build that does not sync', (tester) async {
    await _pump(tester, FakeAppSync(available: false));

    expect(find.byKey(const ValueKey('shell-sync-status')), findsNothing);
  });

  testWidgets('shows the status and a tap syncs now', (tester) async {
    final contest = _contest();
    final sync = FakeAppSync(
      state: AppSyncState(
        scopes: {
          ContestScopeKey(contest.id): const SyncScopeSummary(
            pendingChanges: 2,
          ),
        },
      ),
    );
    await _pump(tester, sync);

    expect(find.text('Not synced yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('shell-sync-status')));
    await tester.pumpAndSettle();

    expect(sync.synced, [ContestScopeKey(contest.id)]);
    expect(find.text('sync page'), findsNothing);
  });

  testWidgets('the time and the details are in the tooltip', (tester) async {
    final contest = _contest();
    final sync = FakeAppSync(
      state: AppSyncState(
        scopes: {
          ContestScopeKey(contest.id): SyncScopeSummary(
            lastSyncedAt: DateTime.utc(2026, 4),
          ),
        },
      ),
    );
    await _pump(tester, sync);

    expect(find.text('Sync successful'), findsOneWidget);
    expect(find.textContaining('Last synced'), findsNothing);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('shell-sync-status'))),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.textContaining('Last synced'), findsOneWidget);
    expect(find.textContaining('Click to sync now'), findsOneWidget);
  });

  testWidgets('a tap does not start a second sync while one runs', (
    tester,
  ) async {
    final contest = _contest();
    final sync = FakeAppSync(
      state: AppSyncState(
        scopes: {ContestScopeKey(contest.id): const SyncScopeSummary()},
        syncing: true,
      ),
    );
    await _pump(tester, sync);

    expect(find.text('Syncing…'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('shell-sync-status')));
    await tester.pump();

    expect(sync.synced, isEmpty);
  });

  testWidgets('follows the engine as its state changes', (tester) async {
    final contest = _contest();
    final sync = FakeAppSync();
    await _pump(tester, sync);
    expect(find.text('Checking…'), findsOneWidget);

    sync.state = AppSyncState(
      scopes: {ContestScopeKey(contest.id): const SyncScopeSummary()},
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Not synced yet'), findsOneWidget);
  });

  testWidgets('outside a contest shows the account status and a tap syncs it', (
    tester,
  ) async {
    final account = DirectorScopeKey(
      Id.parse('019c0000-0000-7000-8000-000000000021'),
    );
    final sync = FakeAppSync(
      state: AppSyncState(
        scopes: {
          account: SyncScopeSummary(lastSyncedAt: DateTime.utc(2026, 4)),
        },
      ),
    )..accountScope = account;
    await _pump(tester, sync, inContest: false);

    expect(find.text('Sync successful'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('shell-sync-status')));
    await tester.pumpAndSettle();

    expect(sync.synced, [account]);
    expect(find.text('sync page'), findsNothing);
  });

  testWidgets('outside a contest shows nothing while nobody is signed in', (
    tester,
  ) async {
    await _pump(tester, FakeAppSync(), inContest: false);

    expect(find.byKey(const ValueKey('shell-sync-status')), findsNothing);
  });
}
