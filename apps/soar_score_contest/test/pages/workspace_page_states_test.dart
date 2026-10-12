import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/widgets/shell_rail.dart';

import '../support/matrix_test_support.dart';
import '../support/next_step_widget_support.dart';

const _action = ValueKey('workspace-state-action');

WorkspaceServer _server() => WorkspaceServer();

void main() {
  group('loading', () {
    testWidgets('shows the page frame with a progress bar and announces it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final server = _server();
      await pumpWorkspaceNoSettle(tester, server);

      expect(
        find.byKey(const ValueKey('workspace-loading-bar')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Loading contest'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      handle.dispose();
    });

    testWidgets('the progress bar does not animate with reduced motion', (
      tester,
    ) async {
      await pumpShellWorkspaceNoSettle(
        tester,
        _server(),
        disableAnimations: true,
      );
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('workspace-loading-bar')),
      );
      expect(bar.value, isNotNull);
    });

    testWidgets('otherwise the bar is indeterminate', (tester) async {
      await pumpShellWorkspaceNoSettle(tester, _server());
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('workspace-loading-bar')),
      );
      expect(bar.value, isNull);
    });
  });

  group('contest not found', () {
    testWidgets('a 404 offers Back to Contests and no retry', (tester) async {
      final server = _server()..contestStatus = 404;
      await pumpShellWorkspace(tester, server);

      expect(find.text('Contest not found'), findsOneWidget);
      expect(
        find.text(
          "This link doesn't match a contest on this device or the server. It "
          'may have been deleted, or the link is incomplete.',
        ),
        findsOneWidget,
      );
      expect(find.text('Back to Contests'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(find.text('Retry'), findsNothing);
      // The shell stays; only the content changes.
      expect(find.byType(ShellRail), findsOneWidget);
    });

    testWidgets('Back to Contests goes to the main page', (tester) async {
      final server = _server()..contestStatus = 404;
      final router = await pumpShellWorkspace(tester, server);

      await tester.tap(find.byKey(_action));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, homePath);
      expect(find.text('Home stub'), findsOneWidget);
    });

    testWidgets('an id that is not an id is not found without a request', (
      tester,
    ) async {
      final server = _server();
      await pumpWorkspace(tester, server, contestId: 'not-an-id');

      expect(find.text('Contest not found'), findsOneWidget);
      expect(server.contestReads, 0);
    });
  });

  group('load failed', () {
    testWidgets('a 500 shows the server message and Try again', (tester) async {
      final server = _server()..contestStatus = 500;
      await pumpShellWorkspace(tester, server);

      expect(find.text("Couldn't load this contest"), findsOneWidget);
      expect(
        find.text('Contest lookup failed. Nothing has changed.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Back to Contests'), findsNothing);
      expect(find.byType(ShellRail), findsOneWidget);
    });

    testWidgets('a network error is a load failure too', (tester) async {
      final server = _server()..networkDown = true;
      await pumpShellWorkspace(tester, server);

      expect(find.text("Couldn't load this contest"), findsOneWidget);
      expect(
        find.text('The server could not be reached. Nothing has changed.'),
        findsOneWidget,
      );
    });

    testWidgets('Try again reloads, and a second tap reloads again', (
      tester,
    ) async {
      final server = _server()..contestStatus = 500;
      await pumpShellWorkspace(tester, server);
      expect(server.contestReads, 1);

      await tester.tap(find.byKey(_action));
      await tester.pumpAndSettle();
      expect(server.contestReads, 2);
      expect(find.text("Couldn't load this contest"), findsOneWidget);

      await tester.tap(find.byKey(_action));
      await tester.pumpAndSettle();
      expect(server.contestReads, 3);

      server.contestStatus = 200;
      await tester.tap(find.byKey(_action));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load this contest"), findsNothing);
      expect(find.text('Front Range Soaring'), findsNothing);
      expect(
        find.byKey(const ValueKey('workspace-section-next-step')),
        findsOneWidget,
      );
    });
  });

  testWidgets('every state fits at 200% text scale in a narrow window', (
    tester,
  ) async {
    final server = _server()..contestStatus = 500;
    await pumpWorkspace(
      tester,
      server,
      size: const Size(320, 600),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.text("Couldn't load this contest"), findsOneWidget);
    expect(matrixContestId, isNotEmpty);
  });
}
