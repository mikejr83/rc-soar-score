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
import 'package:soar_score_ui/soar_score_ui.dart';

import '../support/matrix_test_support.dart';
import '../support/next_step_widget_support.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _pump(
  WidgetTester tester,
  WorkspaceServer server, {
  Size size = const Size(1000, 1200),
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
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
        theme: ContestAppTheme.lightTheme,
        darkTheme: ContestAppTheme.darkTheme,
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
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
  for (final brightness in Brightness.values) {
    testWidgets('publication content uses the $brightness theme card', (
      tester,
    ) async {
      final server = WorkspaceServer(
        state: brightness == Brightness.light
            ? LifecycleState.ready
            : LifecycleState.running,
        configuration: matrixConfiguration(),
      )..startPublished();
      await _pump(tester, server, brightness: brightness);
      final card = _key('publication-page-card');
      expect(card, findsOneWidget);
      for (final key in [
        'publication-page-state',
        'publication-page-policy',
        'publication-publish',
        'publication-page-copy',
        'publication-page-history',
      ]) {
        expect(find.descendant(of: card, matching: _key(key)), findsOneWidget);
      }
      expect(tester.getSize(card).width, 720);
      final material = tester.widget<Material>(
        find.descendant(of: card, matching: find.byType(Material)).first,
      );
      final theme = Theme.of(tester.element(card));
      expect(material.color, theme.cardTheme.color);
      expect(material.shape, theme.cardTheme.shape);
      expect(material.elevation, theme.cardTheme.elevation);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('narrow publication card wraps actions and scrolls history', (
    tester,
  ) async {
    final server = _server()..startPublished(visibility: 'Public');
    await _pump(tester, server, size: const Size(320, 480));
    final card = _key('publication-page-card');
    expect(tester.getTopLeft(card).dx, 16);
    expect(tester.getSize(card).width, 288);
    expect(tester.getTopLeft(_key('publication-page-state')).dx, 32);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(_key('publication-history-1'));
    await tester.pumpAndSettle();
    expect(_key('publication-history-1').hitTestable(), findsOneWidget);
    await tester.ensureVisible(_key('publication-publish'));
    expect(_key('publication-publish').hitTestable(), findsOneWidget);
    expect(
      tester.widget<ButtonStyleButton>(_key('publication-publish')).onPressed,
      isNotNull,
    );
    expect(
      tester.getTopLeft(_key('publication-request-delisting')).dy,
      greaterThan(tester.getTopLeft(_key('publication-publish')).dy),
    );
    expect(tester.takeException(), isNull);
  });

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
    expect(_key('publication-page-card'), findsNothing);
  });

  testWidgets('a failed load offers Retry', (tester) async {
    final server = _server()..contestStatus = 500;
    await _pump(tester, server);
    expect(
      find.descendant(
        of: _key('publication-page-card'),
        matching: _key('publication-page-failed'),
      ),
      findsOneWidget,
    );
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
    final server = _server()..startPublished(visibility: 'Public');
    await _pump(tester, server);
    await tester.tap(_key('publication-request-delisting'));
    await tester.pumpAndSettle();
    await tester.tap(_key('delist-dialog-confirm'));
    await tester.pumpAndSettle();
    expect(server.delistReasons, [null]);
    expect(_key('publication-page-delist-pending'), findsOneWidget);
  });

  testWidgets('reads the history in pages until it has every copy', (
    tester,
  ) async {
    final server = _server()..startPublished();
    server.publication!['current_projection'] = {
      'projection_revision': 230,
      'contest_revision': 1,
      'published_at': '2026-10-17T15:00:00.000Z',
    };
    await _pump(tester, server);
    expect(server.historyRequests, [
      {'limit': '100', 'offset': '0'},
      {'limit': '100', 'offset': '100'},
      {'limit': '100', 'offset': '200'},
    ]);
    expect(_key('publication-history-230'), findsOneWidget);
    expect(_key('publication-history-1'), findsOneWidget);
  });
}
