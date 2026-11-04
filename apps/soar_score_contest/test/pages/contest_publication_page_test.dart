import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/pages/contest/publication_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_test_support.dart';
import '../support/next_step_widget_support.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _pump(WidgetTester tester, WorkspaceServer server) async {
  tester.view.physicalSize = const Size(1000, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: contestPublicationPath(matrixContestId),
    routes: [
      GoRoute(
        path: contestPublicationPath(matrixContestId),
        builder: (context, state) => const Scaffold(
          body: ContestPublicationPage(contestId: matrixContestId),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(server.handle),
      ),
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

WorkspaceServer _server() => WorkspaceServer(
  state: LifecycleState.completed,
  configuration: matrixConfiguration(),
);

void main() {
  testWidgets('an unpublished contest shows nothing published', (tester) async {
    await _pump(tester, _server());
    expect(find.text('Unpublished'), findsOneWidget);
    expect(_key('publication-page-no-copy'), findsOneWidget);
    expect(_key('publication-publish'), findsOneWidget);
  });

  testWidgets('publishing shows the latest copy', (tester) async {
    final server = _server();
    await _pump(tester, server);
    await tester.tap(_key('publication-publish'));
    await tester.pumpAndSettle();
    await tester.tap(_key('publish-dialog-confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Published, Unlisted'), findsOneWidget);
    expect(find.text('Copy 1'), findsOneWidget);
    expect(find.text('Made from contest revision 1'), findsOneWidget);
  });

  testWidgets('a second publish adds a copy', (tester) async {
    final server = _server()..startPublished();
    await _pump(tester, server);
    expect(find.text('Copy 1'), findsOneWidget);
    await tester.tap(_key('publication-publish'));
    await tester.pumpAndSettle();
    await tester.tap(_key('publish-dialog-confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Copy 2'), findsOneWidget);
  });

  testWidgets('a contest that is not found says so', (tester) async {
    final server = _server()..contestStatus = 404;
    await _pump(tester, server);
    expect(find.text('Contest not found'), findsOneWidget);
  });

  testWidgets('a failed load offers Retry', (tester) async {
    final server = _server()..contestStatus = 500;
    await _pump(tester, server);
    expect(_key('publication-page-failed'), findsOneWidget);
    server.contestStatus = 200;
    await tester.tap(_key('publication-page-retry'));
    await tester.pumpAndSettle();
    expect(_key('publication-page-failed'), findsNothing);
  });

  testWidgets('says so when the update policy could not be read', (
    tester,
  ) async {
    final server = _server()
      ..startPublished()
      ..configurationStatus = 500;
    await _pump(tester, server);
    expect(
      find.text('Public updates: the policy could not be read.'),
      findsOneWidget,
    );
    // The page still renders and still offers publishing.
    await tester.tap(_key('publication-publish'));
    await tester.pumpAndSettle();
    expect(
      find.text('Public updates: the policy could not be read.'),
      findsNWidgets(2),
    );
  });

  testWidgets('lists every published copy, newest first', (tester) async {
    final server = _server()..startPublished();
    await _pump(tester, server);
    // Publish twice more: copies 2 and 3.
    for (var i = 0; i < 2; i++) {
      await tester.tap(_key('publication-publish'));
      await tester.pumpAndSettle();
      await tester.tap(_key('publish-dialog-confirm'));
      await tester.pumpAndSettle();
    }
    expect(_key('publication-history-3'), findsOneWidget);
    expect(_key('publication-history-2'), findsOneWidget);
    expect(_key('publication-history-1'), findsOneWidget);
    expect(
      tester.getTopLeft(_key('publication-history-3')).dy,
      lessThan(tester.getTopLeft(_key('publication-history-1')).dy),
    );
    expect(find.text('Published by you'), findsOneWidget);
    expect(find.text('Updated automatically'), findsNWidgets(2));
    expect(find.textContaining('Copy 3, from contest revision 1,'), findsOne);
  });

  testWidgets('an unpublished contest has no history', (tester) async {
    await _pump(tester, _server());
    expect(find.text('Publication history'), findsNothing);
  });

  testWidgets('says so when the history could not be read', (tester) async {
    final server = _server()
      ..startPublished()
      ..historyStatus = 500;
    await _pump(tester, server);
    expect(_key('publication-page-history-failed'), findsOneWidget);
    // The rest of the page still works.
    expect(_key('publication-publish'), findsOneWidget);
  });

  testWidgets('shows a pending delisting request and withdraws it', (
    tester,
  ) async {
    final server = _server()
      ..startPublished()
      ..startDelistPending();
    await _pump(tester, server);
    expect(find.text('Published, Unlisted. Delisting requested.'), findsOne);
    expect(_key('publication-page-delist-pending'), findsOneWidget);
    await tester.tap(_key('publication-withdraw-delisting'));
    await tester.pumpAndSettle();
    expect(server.delistWithdrawals, 1);
    expect(_key('publication-page-delist-pending'), findsNothing);
    expect(find.text('Published, Unlisted'), findsOneWidget);
  });

  testWidgets('requests delisting from the page', (tester) async {
    final server = _server()..startPublished();
    await _pump(tester, server);
    await tester.tap(_key('publication-request-delisting'));
    await tester.pumpAndSettle();
    await tester.tap(_key('delist-dialog-confirm'));
    await tester.pumpAndSettle();
    expect(server.delistReasons, [null]);
    expect(_key('publication-page-delist-pending'), findsOneWidget);
  });
}
