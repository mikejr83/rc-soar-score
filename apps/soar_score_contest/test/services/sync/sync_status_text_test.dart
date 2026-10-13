import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/sync/sync_problem.dart';
import 'package:soar_score_contest/services/sync/sync_scope_summary.dart';
import 'package:soar_score_contest/services/sync/sync_status_text.dart';

String _text(SyncScopeSummary? summary, {bool syncing = false}) =>
    SyncStatusText.of(summary, syncing: syncing, zoneId: 'America/Denver');

void main() {
  test('says it is checking before the engine has looked', () {
    expect(_text(null), 'Checking…');
  });

  test('local only wins over everything else', () {
    expect(
      _text(const SyncScopeSummary(localOnly: true, pendingChanges: 3)),
      'Local only',
    );
  });

  test('a running sync says so', () {
    expect(_text(const SyncScopeSummary(), syncing: true), 'Syncing…');
  });

  test('names the last sync in the contest zone', () {
    expect(
      _text(SyncScopeSummary(lastSyncedAt: DateTime.utc(2026, 10, 13, 18, 30))),
      'Synced 2026-10-13 12:30 MDT',
    );
  });

  test('says when it never synced', () {
    expect(_text(const SyncScopeSummary()), 'Not synced yet');
  });

  test('a problem replaces the sync time and pending changes follow', () {
    expect(
      _text(
        SyncScopeSummary(
          problem: SyncProblem.offline,
          pendingChanges: 2,
          lastSyncedAt: DateTime.utc(2026, 10, 13),
        ),
      ),
      'Offline · 2 pending',
    );
  });

  test('refused changes and conflicts are counted together', () {
    expect(
      _text(
        SyncScopeSummary(
          rejectedChanges: 1,
          conflicts: 1,
          lastSyncedAt: DateTime.utc(2026, 10, 13, 18, 30),
        ),
      ),
      'Synced 2026-10-13 12:30 MDT · 2 need attention',
    );
    expect(
      _text(const SyncScopeSummary(rejectedChanges: 1)),
      'Not synced yet · 1 needs attention',
    );
  });
}
