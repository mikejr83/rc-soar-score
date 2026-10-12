import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/contest/workspace_page.dart';
import 'package:soar_score_contest/widgets/contest_name_loader.dart';
import 'package:soar_score_contest/widgets/shell_status_panel.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_frame.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_live_region.dart';
import 'package:soar_score_contest/widgets/workspace/workspace_scope.dart';
import 'package:soar_score_core/soar_score_core.dart';

const _id = '019c0000-0000-7000-8000-000000000017';

Contest _contest(AdminLock lock) => Contest(
  id: Id.parse(_id),
  name: 'Front Range ALES Open',
  startDateTime: DateTime.utc(2026, 10, 17, 14),
  endDateTime: DateTime.utc(2026, 10, 18, 14),
  timezone: 'America/Denver',
  host: 'Front Range Soaring',
  lifecycleState: LifecycleState.running,
  scoringAccess: ScoringAccess.open,
  adminLock: lock,
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
);

void main() {
  testWidgets('a refresh updates the shell status panel and announces', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var lock = AdminLock.unlocked;
    var requests = 0;
    await tester.pumpWidget(
      ApiClientInherited(
        client: ApiClient(
          baseUrl: Uri.parse('http://localhost'),
          httpClient: MockClient((request) async {
            if (request.url.path.endsWith('/contests/$_id')) {
              requests++;
            }
            return http.Response(
              jsonEncode(_contest(lock).toJson()),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: ContestNameLoader(
              contestId: _id,
              builder: (context, contest) => Column(
                children: [
                  if (contest != null) ShellStatusPanel(contest: contest),
                  const Expanded(child: ContestWorkspacePage(contestId: _id)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Unlocked'), findsOneWidget);
    expect(requests, 1, reason: 'shell and page share one load');

    lock = AdminLock.locked;
    final scope = WorkspaceScope.of(
      tester.element(find.byType(WorkspaceFrame)),
    );
    final done = scope.refresh();
    scope.announce('Administration locked');
    await tester.pumpAndSettle();
    await done;

    expect(requests, 2, reason: 'a refresh is one request');
    expect(find.textContaining('Unlocked'), findsNothing);
    expect(find.textContaining('Locked'), findsOneWidget);
    expect(
      tester
          .widget<WorkspaceLiveRegion>(find.byType(WorkspaceLiveRegion))
          .message,
      'Administration locked',
    );
  });

  testWidgets('inside a shell a load failure shows retry that reloads once', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      ApiClientInherited(
        client: ApiClient(
          baseUrl: Uri.parse('http://localhost'),
          httpClient: MockClient((request) async {
            if (!request.url.path.endsWith('/contests/$_id')) {
              return http.Response('{}', 404);
            }
            requests++;
            return requests == 1
                ? http.Response(
                    jsonEncode({
                      'error': {'code': 'boom', 'message': 'Server broke.'},
                    }),
                    500,
                    headers: {'content-type': 'application/json'},
                  )
                : http.Response(
                    jsonEncode(_contest(AdminLock.unlocked).toJson()),
                    200,
                    headers: {'content-type': 'application/json'},
                  );
          }),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: ContestNameLoader(
              contestId: _id,
              builder: (context, contest) =>
                  const ContestWorkspacePage(contestId: _id),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('The contest could not be loaded.'), findsOneWidget);
    expect(requests, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.text('Front Range Soaring'), findsOneWidget);
  });
}
