import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/connectivity_provider.dart';
import 'package:soar_score_contest/services/ui_account/ui_account.dart';
import 'package:soar_score_contest/ui_account_provider.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/pages/contest/activity_page.dart';

import '../../support/fake_app_connectivity.dart';
import '../../support/fake_audit_api.dart';
import '../../support/matrix_test_support.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeAuditApi api, {
  FakeAuditApi? hosted,
  UiAccount? account,
  FakeAppConnectivity? connectivity,
}) async {
  tester.view.physicalSize = const Size(900, 12000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ApiClientInherited(
      client: api.client,
      child: PublicationClientInherited(
        client: (hosted ?? api).client,
        child: _wrap(
          account,
          connectivity,
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ContestActivityPage(contestId: matrixContestId),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _wrap(
  UiAccount? account,
  FakeAppConnectivity? connectivity,
  Widget child,
) {
  var wrapped = child;
  if (connectivity != null) {
    wrapped = AppConnectivityInherited(monitor: connectivity, child: wrapped);
  }
  if (account != null) {
    wrapped = UiAccountInherited(account: account, child: wrapped);
  }
  return wrapped;
}

/// A web account: the storage id is the sign-in subject, the audit id is the
/// database account id.
class _WebAccount extends FixedUiAccount implements AuditActorSource {
  const _WebAccount(this.auditActorId) : super('user:auth0|abc');

  @override
  final String? auditActorId;
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

  testWidgets('shows who acted: two accounts and the system differ', (
    tester,
  ) async {
    final alice = Id.parse('019c0000-0000-7000-8000-00000000a11c');
    final bob = Id.parse('019c0000-0000-7000-8000-0000000000b0');
    final api = FakeAuditApi([
      auditEvent(1, AuditAction.matrixDrawn, actor: alice),
      auditEvent(2, AuditAction.matrixDrawn, actor: bob),
      auditEvent(3, AuditAction.matrixDrawn, authority: Authority.system),
    ]);
    await _pump(tester, api);

    expect(find.textContaining('· Account 0000a11c'), findsOneWidget);
    expect(find.textContaining('· Account 000000b0'), findsOneWidget);
    expect(find.textContaining('· System'), findsOneWidget);
  });

  testWidgets('publications on the publishing server are listed', (
    tester,
  ) async {
    final api = FakeAuditApi([auditEvent(1, AuditAction.configurationSaved)]);
    final hosted = FakeAuditApi([
      auditEvent(
        2,
        AuditAction.publicationAttempt,
        authority: Authority.system,
      ),
    ]);
    await _pump(tester, api, hosted: hosted);

    expect(find.text('The published results were updated'), findsOneWidget);
    expect(find.text('The contest configuration was saved'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('activity-filter-publication')));
    await tester.pumpAndSettle();
    expect(find.text('The published results were updated'), findsOneWidget);
    expect(find.text('The contest configuration was saved'), findsNothing);
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
    final api = FakeAuditApi([for (var n = 1; n <= 30; n++) _lock(n)]);
    await _pump(tester, api);

    expect(find.byKey(const ValueKey('activity-load-more')), findsOneWidget);
    final before = find.text('Administration was locked').evaluate().length;
    expect(before, lessThan(30));

    final more = find.byKey(const ValueKey('activity-load-more'));
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();

    expect(find.text('Administration was locked').evaluate().length, 30);
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
    // The first read holds a page of lines and routine entries after them, so
    // the next page needs a second read.
    final api = FakeAuditApi([
      for (var n = 1; n <= 5; n++) _lock(n),
      for (var n = 50; n < 75; n++)
        auditEvent(n, AuditAction.scoreAttempt, minute: n),
      for (var n = 100; n < 125; n++) _lock(n),
    ]);
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
    expect(find.text('Administration was locked').evaluate().length, 30);
  });

  testWidgets('an unknown contest says so', (tester) async {
    final api = FakeAuditApi([])..missingContest = true;
    await _pump(tester, api);

    expect(find.text('This contest was not found'), findsOneWidget);
  });

  testWidgets('web: the signed-in director is You, by the account id, not the '
      'sign-in subject', (tester) async {
    final me = Id.parse('019c0000-0000-7000-8000-000000000aaa');
    final other = Id.parse('019c0000-0000-7000-8000-000000000bbb');
    final api = FakeAuditApi([
      auditEvent(1, AuditAction.matrixDrawn, actor: me),
      auditEvent(2, AuditAction.matrixDrawn, actor: other),
      auditEvent(3, AuditAction.matrixDrawn, authority: Authority.system),
    ]);
    await _pump(tester, api, account: _WebAccount(me.value));

    expect(find.textContaining('· You'), findsOneWidget);
    expect(find.textContaining('· Account 00000bbb'), findsOneWidget);
    expect(find.textContaining('· System'), findsOneWidget);
    expect(find.text('You drew the matrix'), findsOneWidget);
  });

  group('during an outage', () {
    FakeAuditApi localWith(int events) => FakeAuditApi([
      for (var n = 1; n <= events; n++)
        auditEvent(n, AuditAction.configurationSaved, minute: n),
    ]);

    FakeAuditApi hostedWith(int minute) => FakeAuditApi([
      auditEvent(
        900,
        AuditAction.publicationAttempt,
        authority: Authority.system,
        minute: minute,
      ),
    ]);

    for (final down in ['503', 'network']) {
      void breakIt(FakeAuditApi api) {
        if (down == '503') {
          api.auditStatus = 503;
        } else {
          api.networkDown = true;
        }
      }

      void fix(FakeAuditApi api) {
        api.auditStatus = null;
        api.networkDown = false;
      }

      testWidgets('hosted $down on first load keeps local history, says '
          'publications are missing and recovers in order', (tester) async {
        final local = localWith(3);
        final hosted = hostedWith(2)..auditStatus = null;
        breakIt(hosted);
        await _pump(tester, local, hosted: hosted);

        expect(
          find.text('The contest configuration was saved'),
          findsNWidgets(3),
        );
        expect(
          find.byKey(const ValueKey('activity-page-incomplete')),
          findsOne,
        );
        expect(find.text('The published results were updated'), findsNothing);
        expect(find.byKey(const ValueKey('activity-filter-matrix')), findsOne);

        fix(hosted);
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('activity-page-incomplete')),
          findsNothing,
        );
        final published = find.text('The published results were updated');
        expect(published, findsOneWidget);
        final saved = find.text('The contest configuration was saved');
        expect(saved, findsNWidgets(3));
        // Published at minute 2 sits between saves 3 and 1 (newest first).
        final y = tester.getTopLeft(published).dy;
        expect(tester.getTopLeft(saved.at(0)).dy, lessThan(y));
        expect(tester.getTopLeft(saved.at(2)).dy, greaterThan(y));
      });

      testWidgets('hosted $down on Load more keeps local paging', (
        tester,
      ) async {
        // 60 publications are all newer than the 60 local saves, so the
        // third page is the first to need more of the hosted history.
        final local = localWith(60);
        final hosted = FakeAuditApi([
          for (var n = 1; n <= 60; n++)
            auditEvent(
              900 + n,
              AuditAction.publicationAttempt,
              authority: Authority.system,
              minute: 100 + n,
            ),
        ]);
        await _pump(tester, local, hosted: hosted);
        final more = find.byKey(const ValueKey('activity-load-more'));
        await tester.ensureVisible(more);
        await tester.tap(more);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('activity-page-incomplete')),
          findsNothing,
        );

        breakIt(hosted);
        await tester.ensureVisible(more);
        await tester.tap(more);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('activity-more-failed')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('activity-page-incomplete')),
          findsOne,
        );
        expect(
          find.text('The contest configuration was saved').evaluate().length,
          25,
        );
        expect(
          find.text('The published results were updated').evaluate().length,
          50,
        );
      });

      testWidgets('Publication with hosted $down offers Retry', (tester) async {
        final local = localWith(2);
        final hosted = hostedWith(1);
        breakIt(hosted);
        await _pump(tester, local, hosted: hosted);

        await tester.tap(
          find.byKey(const ValueKey('activity-filter-publication')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Activity could not be loaded'), findsOneWidget);
        expect(find.byKey(const ValueKey('activity-filter-matrix')), findsOne);

        fix(hosted);
        await tester.tap(find.byKey(const ValueKey('page-state-retry')));
        await tester.pumpAndSettle();
        expect(find.text('The published results were updated'), findsOneWidget);
      });

      testWidgets('local $down on first load keeps the page, the offline '
          'notice and the filters', (tester) async {
        final local = localWith(2);
        // Only the feed fails: the contest comes from another route.
        local.failAudit = true;
        final connectivity = FakeAppConnectivity()
          ..internetStatus = ConnectivityStatus.unavailable;
        await _pump(tester, local, connectivity: connectivity);

        expect(find.text('Activity could not be loaded'), findsOneWidget);
        expect(find.byKey(const ValueKey('activity-page-offline')), findsOne);
        expect(find.byKey(const ValueKey('activity-filter-matrix')), findsOne);
      });
    }
  });
}
