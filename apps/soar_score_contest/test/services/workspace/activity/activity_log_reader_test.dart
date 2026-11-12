import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/activity/activity_entry.dart';
import 'package:soar_score_contest/services/workspace/activity/activity_log_reader.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/fake_audit_api.dart';
import '../../../support/matrix_test_support.dart';

/// A configuration save, which the list shows.
AuditEvent _saved(int n, {int? minute}) =>
    auditEvent(n, AuditAction.configurationSaved, minute: minute);

/// A routine score entry (no correction reason), which the list skips.
AuditEvent _routine(int n) => auditEvent(n, AuditAction.scoreAttempt);

/// A successful publication, recorded on the publishing server.
AuditEvent _published(int n, {int? minute}) => auditEvent(
  n,
  AuditAction.publicationAttempt,
  authority: Authority.system,
  minute: minute,
);

ActivityLogReader _reader(
  FakeAuditApi api, {
  ActivityFilter filter = ActivityFilter.all,
  FakeAuditApi? hosted,
}) => ActivityLogReader(
  api.client,
  contestId,
  filter: filter,
  publicationClient: hosted?.client,
);

void main() {
  test('reads the newest first and says when there is nothing older', () async {
    final api = FakeAuditApi([_saved(1), _saved(2), _saved(3)]);

    final page = await _reader(api).next();

    expect(page.entries.map((e) => e.id), [
      for (final n in [3, 2, 1])
        auditEvent(n, AuditAction.matrixDrawn).id.value,
    ]);
    expect(page.entries.first.kind, ActivityKind.configurationSaved);
    expect(page.hasMore, isFalse);
  });

  test('asks the server for the filter', () async {
    final api = FakeAuditApi([
      _saved(1),
      auditEvent(2, AuditAction.matrixDrawn),
    ]);

    final page = await _reader(api, filter: ActivityFilter.matrix).next();

    expect(page.entries.single.kind, ActivityKind.matrixDrawn);
    expect(api.requests.single, {
      'action': 'MatrixDrawn',
      'limit': '${ActivityLogReader.readSize}',
      'offset': '0',
    });
  });

  test('keeps reading past events the list does not show', () async {
    // 120 routine entries (skipped) are newer than 3 saves.
    final api = FakeAuditApi([
      for (var n = 1; n <= 3; n++) _saved(n),
      for (var n = 10; n < 130; n++) _routine(n),
    ]);

    final page = await _reader(api).next();

    expect(page.entries, hasLength(3));
    expect(page.hasMore, isFalse);
    expect(api.requests.map((r) => r['offset']), ['0', '50', '100']);
  });

  test('pages without skipping or repeating a line', () async {
    final api = FakeAuditApi([for (var n = 1; n <= 60; n++) _saved(n)]);
    final reader = _reader(api);

    final first = await reader.next();
    expect(first.entries, hasLength(ActivityLogReader.pageSize));
    expect(first.hasMore, isTrue);
    final second = await reader.next();
    expect(second.entries, hasLength(ActivityLogReader.pageSize));
    final third = await reader.next();
    expect(third.entries, hasLength(10));
    expect(third.hasMore, isFalse);

    final ids = [...first.entries, ...second.entries, ...third.entries];
    expect(ids.map((e) => e.id).toSet(), hasLength(60));
    expect(
      ids.map((e) => e.at).toList(),
      [...ids.map((e) => e.at)]..sort((a, b) => b.compareTo(a)),
    );
  });

  test('a read that fails fails the page and a retry loses nothing', () async {
    // The newest 50 events hold 10 lines; the page needs more and the second
    // read fails after those 10 were taken.
    final api = FakeAuditApi([
      for (var n = 1; n <= 40; n++) _saved(n),
      for (var n = 100; n < 140; n++) _routine(n),
      for (var n = 200; n < 210; n++) _saved(n),
    ])..failAfterReads = 1;
    final reader = _reader(api);

    await expectLater(reader.next(), throwsA(anything));
    api.failAfterReads = null;
    final page = await reader.next();

    expect(page.entries, hasLength(25));
    expect(page.entries.map((e) => e.id).toSet(), hasLength(25));
    final newest = auditEvent(209, AuditAction.configurationSaved);
    expect(page.entries.first.id, newest.id.value);
  });

  group('with a publishing server of its own', () {
    test('Everything merges its publications into the local events', () async {
      // Local events at minutes 1-60; publications interleaved at 10, 20, ...
      final local = FakeAuditApi([for (var n = 1; n <= 60; n++) _saved(n)]);
      final hosted = FakeAuditApi([
        for (var n = 1; n <= 6; n++) _published(500 + n, minute: n * 10 + 1),
      ]);
      final reader = _reader(local, hosted: hosted);

      final first = await reader.next();
      final second = await reader.next();
      final third = await reader.next();
      final lines = [...first.entries, ...second.entries, ...third.entries];

      expect(lines, hasLength(66));
      expect(lines.map((e) => e.id).toSet(), hasLength(66));
      expect(
        lines.where((e) => e.kind == ActivityKind.publication),
        hasLength(6),
      );
      for (var i = 1; i < lines.length; i++) {
        expect(lines[i - 1].at.isBefore(lines[i].at), isFalse);
      }
      // The publication at minute 61 comes before the save at minute 60, and
      // a page boundary falls among interleaved lines.
      expect(lines.first.kind, ActivityKind.publication);
      expect(first.entries.last.kind, isNotNull);
      expect(third.hasMore, isFalse);
    });

    test('Everything leaves publications out of the local source', () async {
      final local = FakeAuditApi([_saved(1), _published(2)]);
      final hosted = FakeAuditApi([_published(3, minute: 5)]);

      final page = await _reader(local, hosted: hosted).next();

      expect(
        page.entries.where((e) => e.kind == ActivityKind.publication),
        hasLength(1),
      );
    });

    test('Publication reads only the publishing server', () async {
      final local = FakeAuditApi([_saved(1)]);
      final hosted = FakeAuditApi([_published(3)]);

      final page = await _reader(
        local,
        filter: ActivityFilter.publication,
        hosted: hosted,
      ).next();

      expect(page.entries.single.kind, ActivityKind.publication);
      expect(page.entries.single.system, isTrue);
      expect(local.requests, isEmpty);
    });

    test('other filters read only the local server', () async {
      final local = FakeAuditApi([_saved(1)]);
      final hosted = FakeAuditApi([_published(3)]);

      await _reader(
        local,
        filter: ActivityFilter.configuration,
        hosted: hosted,
      ).next();

      expect(hosted.requests, isEmpty);
    });

    test(
      'signed out of or unknown on the publishing server is no events',
      () async {
        for (final status in [401, 404]) {
          final local = FakeAuditApi([_saved(1)]);
          final hosted = FakeAuditApi([])..auditStatus = status;

          final page = await _reader(local, hosted: hosted).next();

          expect(page.entries, hasLength(1), reason: '$status');
        }
      },
    );

    test('a failing publishing server leaves local history, marked '
        'incomplete', () async {
      for (final fail in <void Function(FakeAuditApi)>[
        (api) => api.auditStatus = 503,
        (api) => api.networkDown = true,
      ]) {
        final local = FakeAuditApi([for (var n = 1; n <= 60; n++) _saved(n)]);
        final hosted = FakeAuditApi([_published(900, minute: 30)]);
        fail(hosted);
        final reader = _reader(local, hosted: hosted);

        final first = await reader.next();
        final second = await reader.next();
        final third = await reader.next();

        expect(first.incomplete, isTrue);
        expect(first.entries, hasLength(25));
        expect(second.entries, hasLength(25));
        expect(third.entries, hasLength(10));
        expect(third.hasMore, isFalse);
      }
    });

    test('a new reader after recovery has both sources in order', () async {
      final local = FakeAuditApi([for (var n = 1; n <= 3; n++) _saved(n)]);
      final hosted = FakeAuditApi([_published(900, minute: 2)])
        ..auditStatus = 503;
      expect((await _reader(local, hosted: hosted).next()).incomplete, isTrue);

      hosted.auditStatus = null;
      final page = await _reader(local, hosted: hosted).next();

      expect(page.incomplete, isFalse);
      expect(page.entries.map((e) => e.kind), [
        ActivityKind.configurationSaved,
        ActivityKind.publication,
        ActivityKind.configurationSaved,
        ActivityKind.configurationSaved,
      ]);
    });

    test('Publication alone fails when the publishing server does', () async {
      final local = FakeAuditApi([_saved(1)]);
      final hosted = FakeAuditApi([])..auditStatus = 503;

      expect(
        _reader(
          local,
          filter: ActivityFilter.publication,
          hosted: hosted,
        ).next(),
        throwsA(anything),
      );
    });

    test('a failing local source fails the page', () async {
      final local = FakeAuditApi([_saved(1)])..auditStatus = 503;
      final hosted = FakeAuditApi([_published(900)]);

      expect(_reader(local, hosted: hosted).next(), throwsA(anything));
    });
  });
}
