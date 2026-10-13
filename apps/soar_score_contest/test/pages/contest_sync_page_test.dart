import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app_sync_provider.dart';
import 'package:soar_score_contest/pages/contest/sync_page.dart';
import 'package:soar_score_contest/services/sync/app_sync_state.dart';
import 'package:soar_score_contest/services/sync/open_conflict.dart';
import 'package:soar_score_contest/services/sync/refused_change.dart';
import 'package:soar_score_contest/services/sync/sync_problem.dart';
import 'package:soar_score_contest/services/sync/sync_scope_summary.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/fake_app_sync.dart';

const _contestId = '019c0000-0000-7000-8000-000000000020';
final _scope = ContestScopeKey(Id.parse(_contestId));

Future<void> _pump(WidgetTester tester, FakeAppSync sync) async {
  await tester.pumpWidget(
    AppSyncInherited(
      sync: sync,
      child: const MaterialApp(home: ContestSyncPage(contestId: _contestId)),
    ),
  );
  await tester.pumpAndSettle();
}

AppSyncState _state(SyncScopeSummary summary, {bool syncing = false}) =>
    AppSyncState(syncing: syncing, scopes: {_scope: summary});

void main() {
  conflictTests();

  testWidgets('asks the engine to read the contest and shows its numbers', (
    tester,
  ) async {
    final sync = FakeAppSync(
      state: _state(
        SyncScopeSummary(
          pendingChanges: 3,
          rejectedChanges: 1,
          conflicts: 2,
          lastSyncedAt: DateTime.utc(2026, 10, 13, 18, 30),
        ),
      ),
    );

    await _pump(tester, sync);

    expect(sync.refreshed, [_scope]);
    expect(find.text('2026-10-13 18:30 UTC'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('always shows the unrecoverable-changes warning', (tester) async {
    await _pump(tester, FakeAppSync(state: _state(const SyncScopeSummary())));

    expect(
      find.byKey(const ValueKey('sync-unrecoverable-warning')),
      findsOneWidget,
    );
  });

  testWidgets('names the problem and explains it', (tester) async {
    final sync = FakeAppSync(
      state: _state(const SyncScopeSummary(problem: SyncProblem.signInExpired)),
    );

    await _pump(tester, sync);

    expect(find.text('Sign in again'), findsOneWidget);
    expect(find.textContaining('Nothing on this device was lost'), findsOne);
  });

  testWidgets('Sync now syncs the contest', (tester) async {
    final sync = FakeAppSync(state: _state(const SyncScopeSummary()));
    await _pump(tester, sync);

    await tester.tap(find.byKey(const ValueKey('sync-now')));
    await tester.pump();

    expect(sync.synced, [_scope]);
  });

  testWidgets('Sync now is off while a sync runs', (tester) async {
    final sync = FakeAppSync(
      state: _state(const SyncScopeSummary(), syncing: true),
    );
    await tester.pumpWidget(
      AppSyncInherited(
        sync: sync,
        child: const MaterialApp(home: ContestSyncPage(contestId: _contestId)),
      ),
    );
    await tester.pump();

    final button = tester.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('sync-now')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('a local-only contest says so and cannot sync', (tester) async {
    final sync = FakeAppSync(
      state: _state(const SyncScopeSummary(localOnly: true)),
    );

    await _pump(tester, sync);

    expect(find.byKey(const ValueKey('sync-local-only')), findsOneWidget);
    final button = tester.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('sync-now')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('lists the refused changes with their reasons', (tester) async {
    final sync =
        FakeAppSync(state: _state(const SyncScopeSummary(rejectedChanges: 1)))
          ..refused = [
            RefusedChange(
              entityType: 'OfficialScore',
              entityId: Id.parse('019c0000-0000-7000-8000-000000000031'),
              madeAt: DateTime.utc(2026, 10, 13, 17),
              reasonCode: 'locked',
            ),
          ];

    await _pump(tester, sync);

    expect(find.textContaining('OfficialScore'), findsOneWidget);
    expect(find.text('Locked.'), findsOneWidget);
  });

  testWidgets('a build without sync says it is not used', (tester) async {
    await _pump(tester, FakeAppSync(available: false));

    expect(find.textContaining('only used in the Windows app'), findsOne);
    expect(find.byKey(const ValueKey('sync-now')), findsNothing);
  });
}

OpenConflict _conflict() => OpenConflict(
  id: Id.parse('019c0000-0000-7000-8000-000000000030'),
  entityType: 'OfficialScore',
  entityId: Id.parse('019c0000-0000-7000-8000-000000000031'),
  createdAt: DateTime.utc(2026, 10, 13, 18),
  reasonCode: 'stale_base',
  acceptedPayload: {'time_flown': 540},
  competingPayload: {'time_flown': 545},
);

void conflictTests() {
  testWidgets('lists each open conflict and opens its comparison', (
    tester,
  ) async {
    final conflict = _conflict();
    final sync = FakeAppSync(
      state: _state(const SyncScopeSummary(conflicts: 1)),
    )..conflicts = [conflict];

    await _pump(tester, sync);

    expect(
      find.text('OfficialScore, found 2026-10-13 18:00 UTC'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(ValueKey('conflict-review-${conflict.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('conflict-comparison')), findsOneWidget);
  });

  testWidgets('a decision goes to the sync with the conflict and choice', (
    tester,
  ) async {
    final conflict = _conflict();
    final sync = FakeAppSync(
      state: _state(const SyncScopeSummary(conflicts: 1)),
    )..conflicts = [conflict];

    await _pump(tester, sync);
    await tester.tap(find.byKey(ValueKey('conflict-review-${conflict.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('conflict-take-competing')));
    await tester.pumpAndSettle();

    expect(sync.resolutions.single.conflict, conflict);
    expect(
      sync.resolutions.single.choice,
      ConflictResolutionChoice.tookCompeting,
    );
    expect(find.byKey(const ValueKey('conflict-dialog')), findsNothing);
  });

  testWidgets('says so when nothing waits for a decision', (tester) async {
    await _pump(tester, FakeAppSync(state: _state(const SyncScopeSummary())));

    expect(
      find.text('None. Nothing is waiting for your decision.'),
      findsOneWidget,
    );
  });
}
