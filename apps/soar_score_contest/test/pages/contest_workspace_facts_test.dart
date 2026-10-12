import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/contest_workspace_page.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_frame.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_scope.dart';

import '../support/matrix_test_support.dart';

Future<void> _pump(WidgetTester tester, MatrixServer server) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/scores') || path.endsWith('/publication')) {
            return http.Response('{}', 404);
          }
          return server.handle(request);
        }),
      ),
      child: const MaterialApp(
        home: Scaffold(body: ContestWorkspacePage(contestId: matrixContestId)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('loads the facts and shows the progress section once a matrix '
      'exists', (tester) async {
    await _pump(
      tester,
      MatrixServer(configuration: matrixConfiguration(), matrix: drawnMatrix()),
    );

    final scope = WorkspaceScope.of(
      tester.element(find.byType(WorkspaceFrame)),
    );
    expect(scope.facts?.hasMatrix, isTrue);
    expect(
      find.byKey(const ValueKey('workspace-section-progress')),
      findsOneWidget,
    );
  });

  testWidgets('without a matrix the progress section stays out', (
    tester,
  ) async {
    await _pump(tester, MatrixServer(configuration: matrixConfiguration()));

    final scope = WorkspaceScope.of(
      tester.element(find.byType(WorkspaceFrame)),
    );
    expect(scope.facts?.hasMatrix, isFalse);
    expect(
      find.byKey(const ValueKey('workspace-section-progress')),
      findsNothing,
    );
  });
}
