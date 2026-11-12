import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/pages/contest/activity_page.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/fake_audit_api.dart';
import '../../support/matrix_test_support.dart';

Future<void> _pump(WidgetTester tester, FakeAuditApi api) async {
  tester.view.physicalSize = const Size(900, 12000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ApiClientInherited(
      client: api.client,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ContestActivityPage(contestId: matrixContestId)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AuditEvent _lock(int n) => auditEvent(
  n,
  AuditAction.stateTransition,
  reason: 'lock: AdminLock Unlocked → Locked',
);

void main() {
  testWidgets('lists the events newest first in the contest time zone', (
    tester,
  ) async {
    final api = FakeAuditApi([
      auditEvent(1, AuditAction.configurationSaved),
      auditEvent(2, AuditAction.matrixDrawn),
    ]);
    await _pump(tester, api);

    final matrix = find.text('The matrix was drawn');
    final saved = find.text('The contest configuration was saved');
    expect(matrix, findsOneWidget);
    expect(saved, findsOneWidget);
    expect(tester.getTopLeft(matrix).dy, lessThan(tester.getTopLeft(saved).dy));
    // 2026-10-18 09:02 UTC is 03:02 in Denver.
    expect(find.textContaining('2026-10-18 03:02'), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-end')), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-load-more')), findsNothing);
  });

  testWidgets('a filter reads only that kind', (tester) async {
    final api = FakeAuditApi([
      auditEvent(1, AuditAction.configurationSaved),
      auditEvent(2, AuditAction.matrixDrawn),
    ]);
    await _pump(tester, api);

    await tester.tap(find.byKey(const ValueKey('activity-filter-matrix')));
    await tester.pumpAndSettle();

    expect(find.text('The matrix was drawn'), findsOneWidget);
    expect(find.text('The contest configuration was saved'), findsNothing);
    expect(api.requests.last['action'], 'MatrixDrawn');
  });

  testWidgets('an empty filter offers to show everything', (tester) async {
    final api = FakeAuditApi([auditEvent(1, AuditAction.configurationSaved)]);
    await _pump(tester, api);

    await tester.tap(find.byKey(const ValueKey('activity-filter-matrix')));
    await tester.pumpAndSettle();
    expect(find.text('No activity of this kind'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('activity-clear-filter')));
    await tester.pumpAndSettle();
    expect(find.text('The contest configuration was saved'), findsOneWidget);
  });

  testWidgets('a contest without events says so', (tester) async {
    await _pump(tester, FakeAuditApi([]));

    expect(find.text('Nothing has happened yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-clear-filter')), findsNothing);
  });

  testWidgets('Load more adds the next page', (tester) async {
    final api = FakeAuditApi([for (var n = 1; n <= 70; n++) _lock(n)]);
    await _pump(tester, api);

    expect(find.byKey(const ValueKey('activity-load-more')), findsOneWidget);
    final before = find.text('Administration was locked').evaluate().length;
    expect(before, lessThan(70));

    final more = find.byKey(const ValueKey('activity-load-more'));
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();

    expect(find.text('Administration was locked').evaluate().length, 70);
    expect(find.byKey(const ValueKey('activity-load-more')), findsNothing);
    expect(find.byKey(const ValueKey('activity-end')), findsOneWidget);
  });

  testWidgets('a failed first read offers Retry', (tester) async {
    final api = FakeAuditApi([auditEvent(1, AuditAction.matrixDrawn)])
      ..failAudit = true;
    await _pump(tester, api);

    expect(find.text('Activity could not be loaded'), findsOneWidget);

    api.failAudit = false;
    await tester.tap(find.byKey(const ValueKey('page-state-retry')));
    await tester.pumpAndSettle();
    expect(find.text('The matrix was drawn'), findsOneWidget);
  });

  testWidgets('a failed further page keeps the list and offers Retry', (
    tester,
  ) async {
    final api = FakeAuditApi([for (var n = 1; n <= 70; n++) _lock(n)]);
    await _pump(tester, api);
    final shown = find.text('Administration was locked').evaluate().length;

    api.failAudit = true;
    final more = find.byKey(const ValueKey('activity-load-more'));
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('activity-more-failed')), findsOneWidget);
    expect(find.text('Administration was locked').evaluate().length, shown);

    api.failAudit = false;
    final retry = find.byKey(const ValueKey('activity-more-retry'));
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('Administration was locked').evaluate().length, 70);
  });

  testWidgets('an unknown contest says so', (tester) async {
    final api = FakeAuditApi([])..missingContest = true;
    await _pump(tester, api);

    expect(find.text('This contest was not found'), findsOneWidget);
  });
}
