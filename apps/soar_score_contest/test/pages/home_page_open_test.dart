import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/home_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_core/soar_score_core.dart';

const _id = '019c0000-0000-7000-8000-000000000017';

Contest _contest(LifecycleState state) => Contest(
  id: Id.parse(_id),
  name: 'Front Range ALES Open',
  startDateTime: DateTime.utc(2026, 10, 17, 14),
  endDateTime: DateTime.utc(2026, 10, 18, 14),
  timezone: 'America/Denver',
  lifecycleState: state,
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
);

Widget _app(LifecycleState state) {
  final client = ApiClient(
    baseUrl: Uri.parse('http://localhost'),
    httpClient: MockClient(
      (_) async => http.Response(
        jsonEncode({
          'contests': [_contest(state).toJson()],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    ),
  );
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: HomePage()),
      ),
      GoRoute(
        path: contestWorkspacePath(_id),
        builder: (context, state) => const Text('workspace page'),
      ),
      GoRoute(
        path: contestConfigurationPath(_id),
        builder: (context, state) => const Text('configuration page'),
      ),
    ],
  );
  return ApiClientInherited(
    client: client,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  final open = find.byKey(const ValueKey('open-contest'));
  final row = find.byKey(const ValueKey('contest-$_id'));

  for (final (state, label, page) in [
    (LifecycleState.created, 'Open', 'configuration page'),
    (LifecycleState.configuring, 'Open', 'configuration page'),
    (LifecycleState.ready, 'Continue', 'workspace page'),
    (LifecycleState.running, 'Continue', 'workspace page'),
    (LifecycleState.completed, 'View', 'workspace page'),
  ]) {
    testWidgets('a $state contest offers $label', (tester) async {
      await tester.pumpWidget(_app(state));
      await tester.pumpAndSettle();

      expect(find.descendant(of: open, matching: find.text(label)), findsOne);
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.text(page), findsOneWidget);
    });
  }

  testWidgets('a double-click opens the contest', (tester) async {
    await tester.pumpWidget(_app(LifecycleState.running));
    await tester.pumpAndSettle();

    await tester.tap(row);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('workspace page'), findsOneWidget);
  });

  testWidgets('Enter on a focused row opens the contest', (tester) async {
    await tester.pumpWidget(_app(LifecycleState.running));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('workspace page'), findsOneWidget);
  });
}
