import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/activity/activity_entry.dart';
import 'package:soar_score_contest/services/workspace/activity/activity_log_loader.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/fake_audit_api.dart';
import '../../../support/matrix_test_support.dart';

/// A configuration save, which the list shows.
AuditEvent _saved(int n) => auditEvent(n, AuditAction.configurationSaved);

/// A routine score entry (no correction reason), which the list skips.
AuditEvent _routine(int n) => auditEvent(n, AuditAction.scoreAttempt);

void main() {
  test('reads the newest first and says when there is nothing older', () async {
    final api = FakeAuditApi([_saved(1), _saved(2), _saved(3)]);

    final page = await ActivityLogLoader(api.client).load(contestId);

    expect(page.entries.map((e) => e.id), [
      for (final n in [3, 2, 1])
        auditEvent(n, AuditAction.matrixDrawn).id.value,
    ]);
    expect(page.entries.first.kind, ActivityKind.configurationSaved);
    expect(page.hasMore, isFalse);
    expect(page.nextOffset, 3);
  });

  test('asks the server for the filter and the offset', () async {
    final api = FakeAuditApi([
      _saved(1),
      auditEvent(2, AuditAction.matrixDrawn),
    ]);

    final page = await ActivityLogLoader(api.client)
        .load(contestId, filter: ActivityFilter.matrix, offset: 0);

    expect(page.entries.single.kind, ActivityKind.matrixDrawn);
    expect(api.requests.single, {
      'action': 'MatrixDrawn',
      'limit': '${ActivityLogLoader.readSize}',
      'offset': '0',
    });
  });

  test('keeps reading past events the list does not show', () async {
    // 120 routine entries (skipped) are newer than 3 saves.
    final api = FakeAuditApi([
      for (var n = 1; n <= 3; n++) _saved(n),
      for (var n = 10; n < 130; n++) _routine(n),
    ]);

    final page = await ActivityLogLoader(api.client).load(contestId);

    expect(page.entries, hasLength(3));
    expect(page.hasMore, isFalse);
    expect(page.nextOffset, 123);
    expect(api.requests.map((r) => r['offset']), ['0', '50', '100']);
  });

  test(
    'stops at a page of lines and continues from where it stopped',
    () async {
      final api = FakeAuditApi([for (var n = 1; n <= 60; n++) _saved(n)]);
      final loader = ActivityLogLoader(api.client);

      final first = await loader.load(contestId);
      expect(
        first.entries.length,
        greaterThanOrEqualTo(ActivityLogLoader.pageSize),
      );
      expect(first.hasMore, isTrue);

      final second = await loader.load(contestId, offset: first.nextOffset);
      expect(second.hasMore, isFalse);
      final ids = [...first.entries, ...second.entries].map((e) => e.id);
      expect(ids.toSet(), hasLength(60));
    },
  );

  test('a read that fails fails the load', () async {
    final api = FakeAuditApi([_saved(1)])..failAudit = true;

    expect(ActivityLogLoader(api.client).load(contestId), throwsA(anything));
  });
}
