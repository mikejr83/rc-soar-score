import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/pages/participant_editor_page.dart';
import 'package:soar_score_contest/pages/participants_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_core/soar_score_core.dart';

const String ownerId = '019c0000-0000-7000-8000-000000000001';

ParticipantProfile profile(
  String first,
  String last, {
  int n = 10,
  String? email,
  String? club,
  int revision = 0,
}) => ParticipantProfile(
  id: Id.parse('019c0000-0000-7000-8000-0000000000$n'),
  ownerAccountId: Id.parse(ownerId),
  firstName: first,
  lastName: last,
  email: email ?? '${first.toLowerCase()}@example.com',
  club: club,
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
  revision: revision,
);

http.Response json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

http.Response errorResponse(int status, String code, String message) => json({
  'error': {'code': code, 'message': message},
}, status);

/// An [ApiClient] whose requests are answered by [respond] and recorded.
ApiClient clientFor(
  Future<http.Response> Function(http.Request) respond, {
  List<http.Request>? requests,
}) => ApiClient(
  baseUrl: Uri.parse('http://localhost'),
  httpClient: MockClient((request) {
    requests?.add(request);
    return respond(request);
  }),
);

/// A window tall enough that the editor's form fits without scrolling.
void useTallWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Pumps the participant routes (list, create and edit) under [client].
Widget participantsApp(ApiClient client, {String initial = participantsPath}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: participantsPath,
        builder: (_, _) => const Scaffold(body: ParticipantsPage()),
      ),
      GoRoute(
        path: newParticipantPath,
        builder: (_, _) => const Scaffold(body: ParticipantEditorPage()),
      ),
      GoRoute(
        path: '$participantsPath/:participantId',
        builder: (_, state) => Scaffold(
          body: ParticipantEditorPage(
            participantId: state.pathParameters['participantId'],
          ),
        ),
      ),
    ],
  );
  return ApiClientInherited(
    client: client,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// Types [text] into the editor field with [key] and lets the page react, so
/// buttons that depend on the change are up to date.
Future<void> enterField(WidgetTester tester, String key, String text) async {
  await tester.enterText(find.byKey(ValueKey(key)), text);
  await tester.pump();
}

/// Moves focus out of the field with [key] by focusing [next].
Future<void> leaveField(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('first-name')));
  await tester.pump();
}

/// Taps the editor's Save button and waits for the result.
Future<void> saveEditor(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('save-participant')));
  await tester.pumpAndSettle();
}

/// Pumps a lone [ParticipantEditorPage] built by [page] under [client].
Widget editorApp(ApiClient client, ParticipantEditorPage page) =>
    ApiClientInherited(
      client: client,
      child: MaterialApp(home: Scaffold(body: page)),
    );
