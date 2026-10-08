import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/contest_workspace_page.dart';
import 'package:soar_score_core/soar_score_core.dart';

const _id = '019c0000-0000-7000-8000-000000000017';

Contest _contest({
  LifecycleState state = LifecycleState.configuring,
  ScoringAccess access = ScoringAccess.closed,
  AdminLock lock = AdminLock.unlocked,
}) => Contest(
  id: Id.parse(_id),
  name: 'Front Range ALES Open',
  startDateTime: DateTime.utc(2026, 10, 17, 14),
  endDateTime: DateTime.utc(2026, 10, 18, 14),
  timezone: 'America/Denver',
  host: 'Front Range Soaring',
  lifecycleState: state,
  scoringAccess: access,
  adminLock: lock,
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
);

Widget _app(http.Client httpClient) => ApiClientInherited(
  client: ApiClient(
    baseUrl: Uri.parse('http://localhost'),
    httpClient: httpClient,
  ),
  child: const MaterialApp(
    home: Scaffold(body: ContestWorkspacePage(contestId: _id)),
  ),
);

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  testWidgets('shows the contest details', (tester) async {
    await tester.pumpWidget(
      _app(
        MockClient(
          (_) async => _json(
            _contest(
              access: ScoringAccess.open,
              lock: AdminLock.locked,
            ).toJson(),
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Front Range Soaring'), findsOneWidget);
  });

  testWidgets('summarises the contest pages, those not built yet disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(MockClient((_) async => _json(_contest().toJson()))),
    );
    await tester.pumpAndSettle();

    for (final label in [
      'Configuration',
      'Participants',
      'Matrix',
      'Scoring',
      'Reports',
      'Publication',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.textContaining('Not available yet.'), findsNWidgets(5));
  });

  testWidgets('reports a load failure and retries', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _app(
        MockClient((_) async {
          calls++;
          return calls == 1
              ? _json({
                  'error': {'code': 'not_found', 'message': 'No such contest.'},
                }, 404)
              : _json(_contest().toJson());
        }),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The contest could not be loaded.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Front Range Soaring'), findsOneWidget);
  });
}
