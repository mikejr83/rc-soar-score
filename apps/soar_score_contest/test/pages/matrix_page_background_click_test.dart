import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/contest_draft_provider.dart';
import 'package:soar_score_contest/pages/matrix_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft_store.dart';
import 'package:soar_score_contest/widgets/contest_shell.dart';

import '../support/matrix_test_support.dart';

void main() {
  // In the app a page sits in the shell's nested navigator, whose modal
  // barrier plays the system alert when a click lands where the page has
  // nothing to catch it.
  testWidgets('clicking the empty background makes no alert sound', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final server = MatrixServer(
      configuration: matrixConfiguration({}),
      matrix: drawnMatrix(),
    );
    final router = GoRouter(
      initialLocation: contestMatrixPath(matrixContestId),
      routes: [
        ShellRoute(
          builder: (context, state, child) =>
              ContestShell(state: state, child: child),
          routes: [
            GoRoute(
              path: '$contestsPath/:contestId/matrix',
              builder: (context, state) =>
                  MatrixPage(contestId: state.pathParameters['contestId']!),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ApiClientInherited(
        client: ApiClient(
          baseUrl: Uri.parse('http://localhost'),
          httpClient: MockClient(server.handle),
        ),
        child: ContestDraftInherited(
          store: ContestDraftStore(),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final sounds = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemSound.play') {
          sounds.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final search = tester.getRect(find.byKey(const ValueKey('find-pilot')));
    await tester.tapAt(Offset(search.right + 200, search.center.dy));
    await tester.pump(const Duration(milliseconds: 50));

    expect(sounds, isEmpty);
  });
}
