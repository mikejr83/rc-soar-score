import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_contest/app_sync_provider.dart';
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
      child: MaterialApp.router(routerConfig: router),
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

  testWidgets('shows the status and opens the sync details', (tester) async {
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

    expect(find.text('Not synced yet · 2 pending'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('shell-sync-status')));
    await tester.pumpAndSettle();

    expect(find.text('sync page'), findsOneWidget);
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

    expect(find.textContaining('Synced '), findsOneWidget);

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
