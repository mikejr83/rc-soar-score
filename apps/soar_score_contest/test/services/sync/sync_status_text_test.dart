import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/services/preferences/director_time.dart';
import 'package:soar_score_contest/services/sync/sync_problem.dart';
import 'package:soar_score_contest/services/sync/sync_scope_summary.dart';
import 'package:soar_score_contest/services/sync/sync_status_text.dart';

SyncStatusText _text(
  SyncScopeSummary? summary, {
  bool syncing = false,
  bool canSyncNow = false,
}) => SyncStatusText.of(
  AppLocalizationsEn(),
  summary,
  syncing: syncing,
  canSyncNow: canSyncNow,
  time: (utc) => DirectorTime.format(utc, zoneId: 'America/Denver'),
);

void main() {
  final synced = DateTime.utc(2026, 10, 13, 18, 30);

  test('says it is checking before the engine has looked', () {
    expect(_text(null).label, 'Checking…');
  });

  test('local only wins over everything else', () {
    final text = _text(
      const SyncScopeSummary(localOnly: true, pendingChanges: 3),
    );
    expect(text.label, 'Local only');
    expect(text.tooltip, contains('not backed up'));
  });

  test('local only names why the account is not linked in the tooltip', () {
    final text = _text(
      const SyncScopeSummary(
        localOnly: true,
        problem: SyncProblem.accountClaimBlocked,
      ),
    );
    expect(text.label, 'Local only');
    expect(text.tooltip, contains('Account not linked'));
  });

  test('a running sync says so', () {
    final text = _text(
      SyncScopeSummary(lastSyncedAt: synced),
      syncing: true,
      canSyncNow: true,
    );
    expect(text.label, 'Syncing…');
    expect(text.tooltip, isNot(contains('Click to sync now')));
  });

  test('a sync that worked says so and the time is in the tooltip', () {
    final text = _text(SyncScopeSummary(lastSyncedAt: synced));
    expect(text.label, 'Sync successful');
    expect(text.label, isNot(contains('MDT')));
    expect(text.tooltip, contains('Last synced 10/13/2026 12:30 MDT'));
  });

  test('the tooltip says a click syncs now', () {
    expect(
      _text(SyncScopeSummary(lastSyncedAt: synced), canSyncNow: true).tooltip,
      endsWith('Click to sync now'),
    );
  });

  test('says when it never synced', () {
    final text = _text(const SyncScopeSummary());
    expect(text.label, 'Not synced yet');
    expect(text.tooltip, 'Not synced yet');
  });

  test('a failure is short in the bar and explained in the tooltip', () {
    final text = _text(
      SyncScopeSummary(
        problem: SyncProblem.offline,
        pendingChanges: 2,
        lastSyncedAt: synced,
      ),
    );
    expect(text.label, 'Sync failed');
    expect(text.tooltip, contains(SyncProblem.offline.explanation));
    expect(text.tooltip, contains('Last synced 10/13/2026 12:30 MDT'));
    expect(text.tooltip, contains('2 changes waiting to be sent'));
  });

  test('a failure before the first sync says so', () {
    final text = _text(const SyncScopeSummary(problem: SyncProblem.offline));
    expect(text.label, 'Sync failed');
    expect(text.tooltip, contains('Not synced yet'));
  });

  test('conflicts and refused changes have their own words', () {
    final conflicts = _text(
      SyncScopeSummary(rejectedChanges: 1, conflicts: 1, lastSyncedAt: synced),
    );
    expect(conflicts.label, 'Sync conflicts');
    expect(conflicts.tooltip, contains('2 changes need your attention'));

    final refused = _text(
      SyncScopeSummary(rejectedChanges: 1, lastSyncedAt: synced),
    );
    expect(refused.label, 'Changes refused');
    expect(refused.tooltip, contains('1 change needs your attention'));
  });

  test('changes waiting to be sent show as pending', () {
    final text = _text(
      SyncScopeSummary(pendingChanges: 1, lastSyncedAt: synced),
    );
    expect(text.label, 'Changes pending');
    expect(text.tooltip, contains('1 change waiting to be sent'));
  });
}
