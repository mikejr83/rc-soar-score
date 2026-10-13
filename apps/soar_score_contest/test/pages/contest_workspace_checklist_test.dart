import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/contest/workspace_page.dart';
import 'package:soar_score_core/soar_score_core.dart';

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
  testWidgets('a contest being configured shows the checklist', (tester) async {
    await _pump(tester, MatrixServer(configuration: matrixConfiguration()));

    expect(find.byKey(const ValueKey('setup-checklist-card')), findsOneWidget);
    expect(find.text('Setup checklist'), findsOneWidget);
    expect(find.text('Configuration saved and valid'), findsOneWidget);
    expect(find.text('4 scoring pilots'), findsOneWidget);
    expect(find.text('Matrix not drawn'), findsOneWidget);
    expect(find.text('Participant scoring closed'), findsOneWidget);
  });

  testWidgets('a created contest has nothing saved yet', (tester) async {
    await _pump(
      tester,
      MatrixServer(contest: matrixContest(state: LifecycleState.created)),
    );

    expect(find.text('Configuration not saved'), findsOneWidget);
    expect(find.text('1 of 4 required items done'), findsOneWidget);
  });

  testWidgets('a running contest has no checklist', (tester) async {
    await _pump(
      tester,
      MatrixServer(
        contest: matrixContest(state: LifecycleState.running),
        configuration: matrixConfiguration(),
        matrix: drawnMatrix(),
      ),
    );

    expect(find.byKey(const ValueKey('setup-checklist-card')), findsNothing);
    expect(
      find.byKey(const ValueKey('workspace-section-checklist')),
      findsNothing,
    );
  });
}
