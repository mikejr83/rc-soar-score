import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/home_page.dart';
import 'package:soar_score_core/soar_score_core.dart';

Contest _contest(String name, {int day = 17}) => Contest(
  id: Id.parse('019c0000-0000-7000-8000-0000000000$day'),
  name: name,
  startDateTime: DateTime.utc(2026, 10, day, 14),
  endDateTime: DateTime.utc(2026, 10, day + 1, 14),
  timezone: 'America/Denver',
  createdAt: DateTime.utc(2026, 9),
  updatedAt: DateTime.utc(2026, 9),
);

Widget _app(ApiClient? client) {
  const page = MaterialApp(home: HomePage());
  return client == null
      ? page
      : ApiClientInherited(client: client, child: page);
}

ApiClient _client(Future<http.Response> Function(http.Request) respond) =>
    ApiClient(
      baseUrl: Uri.parse('http://localhost'),
      httpClient: MockClient(respond),
    );

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  testWidgets('lists the contests the API returns', (tester) async {
    final client = _client(
      (_) async => _json({
        'contests': [
          _contest('Front Range ALES Open').toJson(),
          _contest('Second Open', day: 24).toJson(),
        ],
      }),
    );

    await tester.pumpWidget(_app(client));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Front Range ALES Open'), findsOneWidget);
    expect(find.text('Second Open'), findsOneWidget);
    expect(find.text('Created'), findsNWidgets(2));
    expect(find.text('Oct 17, 2026 to Oct 18, 2026'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no contests', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_client((_) async => _json({'contests': <Object>[]}))),
    );
    await tester.pumpAndSettle();

    expect(find.text('No contests yet.'), findsOneWidget);
  });

  testWidgets('shows the error and retries', (tester) async {
    var calls = 0;
    final client = _client((_) async {
      calls++;
      if (calls == 1) {
        return http.Response('boom', 500);
      }
      return _json({
        'contests': [_contest('Recovered Open').toJson()],
      });
    });

    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();
    expect(find.text('Contests could not be loaded.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered Open'), findsOneWidget);
    expect(find.text('Contests could not be loaded.'), findsNothing);
  });

  testWidgets('shows the error when no API client is provided', (tester) async {
    await tester.pumpWidget(_app(null));
    await tester.pumpAndSettle();

    expect(find.text('Contests could not be loaded.'), findsOneWidget);
  });
}
