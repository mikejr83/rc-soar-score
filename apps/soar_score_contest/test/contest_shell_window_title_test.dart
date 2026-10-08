import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'support/shell_test_router.dart';
import 'support/window_title_recorder.dart';

/// An API client that serves one contest named [name] with [testContestId].
ApiClient _client(String name) => ApiClient(
  baseUrl: Uri.parse('http://localhost'),
  httpClient: MockClient(
    (_) async => http.Response(
      jsonEncode(
        Contest(
          id: Id.parse(testContestId),
          name: name,
          startDateTime: DateTime.utc(2026, 10, 17, 14),
          endDateTime: DateTime.utc(2026, 10, 18, 14),
          timezone: 'America/Denver',
          createdAt: DateTime.utc(2026, 9),
          updatedAt: DateTime.utc(2026, 9),
        ).toJson(),
      ),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ),
  ),
);

void main() {
  testWidgets('the window title and header name the selected contest, and '
      'the title returns to the app name on the main page', (tester) async {
    final titles = recordWindowTitles();
    final client = _client('Spring F3J 2026');
    addTearDown(client.close);
    final router = buildShellTestRouter(
      initialLocation: contestWorkspacePath(testContestId),
    );
    addTearDown(router.dispose);

    await pumpShellRouter(tester, router, client: client);

    expect(find.byKey(const ValueKey('contest-title')), findsOneWidget);
    expect(find.text('Spring F3J 2026'), findsNWidgets(2));
    expect(titles.last, 'RC Soar Score: Spring F3J 2026');

    router.go(homePath);
    await tester.pumpAndSettle();

    expect(titles.last, 'RC Soar Score');
  }, variant: windowsOnly);

  testWidgets('the main page uses the application name', (tester) async {
    final titles = recordWindowTitles();
    final router = buildShellTestRouter();
    addTearDown(router.dispose);

    await pumpShellRouter(tester, router);

    expect(titles, ['RC Soar Score']);
  }, variant: windowsOnly);
}
