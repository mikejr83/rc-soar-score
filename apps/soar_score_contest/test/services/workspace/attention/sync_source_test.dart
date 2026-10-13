import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/sync/sync_scope_summary.dart';
import 'package:soar_score_contest/services/workspace/attention/attention_item.dart';
import 'package:soar_score_contest/services/workspace/attention/needs_attention.dart';
import 'package:soar_score_contest/services/workspace/attention/sync_source.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';

import '../../../support/workspace_facts_support.dart';

AttentionItem? _row(SyncScopeSummary? summary) {
  final attention = NeedsAttention.of(
    WorkspaceFacts.derive(data: workspaceData()),
    sources: [SyncSource(summary)],
  );
  return attention.items.isEmpty ? null : attention.items.single;
}

void main() {
  test('no summary adds no row', () {
    expect(_row(null), isNull);
  });

  test('a quiet contest adds no row', () {
    expect(_row(const SyncScopeSummary(pendingChanges: 4)), isNull);
  });

  test('refused changes become one row that opens the sync details', () {
    final row = _row(const SyncScopeSummary(rejectedChanges: 2))!;

    expect(row.kind, AttentionKind.rejectedSync);
    expect(row.count, 2);
    expect(row.title, '2 changes were refused by the service');
    expect(row.detail, '2 refused by the service');
    expect(row.opensSync, isTrue);
  });

  test('one refused change reads in the singular', () {
    expect(
      _row(const SyncScopeSummary(rejectedChanges: 1))!.title,
      '1 change was refused by the service',
    );
  });

  test('conflicts alone are named as conflicts', () {
    final row = _row(const SyncScopeSummary(conflicts: 3))!;

    expect(row.title, '3 conflicts need a decision');
    expect(row.detail, '3 conflicts need a decision');
  });

  test('refused changes and conflicts share one row', () {
    final row = _row(const SyncScopeSummary(rejectedChanges: 1, conflicts: 1))!;

    expect(row.count, 2);
    expect(row.title, '2 synced changes need a look');
    expect(row.detail, '1 refused by the service, 1 conflict needs a decision');
  });
}
