import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:soar_score_contest/router.dart';

import '../support/landing_test_support.dart';
import '../support/participant_test_support.dart';

void main() {
  late List<http.Request> requests;

  Future<void> open(
    WidgetTester tester, {
    Future<http.Response> Function(http.Request)? respond,
  }) async {
    useTallWindow(tester);
    requests = [];
    await tester.pumpWidget(
      landingsApp(
        clientFor(
          respond ??
              (request) async => request.method == 'POST'
                  ? json(landingView('Club', 4).toJson(), 201)
                  : json(landingList([landingView('Club', 4)])),
          requests: requests,
        ),
        initial: newLandingPath,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String key, String text) async {
    await tester.enterText(find.byKey(ValueKey(key)), text);
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('save-landing')));
    await tester.pumpAndSettle();
  }

  testWidgets('creates a table from the typed entries in order', (
    tester,
  ) async {
    await open(tester);

    await type(tester, 'landing-name', ' Club table ');
    await type(tester, 'entry-key-0', 'within_1m');
    await type(tester, 'entry-points-0', '10');
    await tester.tap(find.byKey(const ValueKey('add-landing-entry')));
    await tester.pumpAndSettle();
    await type(tester, 'entry-key-1', 'within_2m');
    await type(tester, 'entry-label-1', 'Within 2 m');
    await type(tester, 'entry-points-1', '5');
    await save(tester);

    final post = requests.singleWhere((r) => r.method == 'POST');
    expect(post.url.path, '/api/v1/landing-tables');
    final body = jsonDecode(post.body) as Map<String, dynamic>;
    expect(body['name'], 'Club table');
    expect(body['input_unit'], 'points');
    expect(body['entries'], [
      {'entry_key': 'within_1m', 'display_value': '', 'point_value': 10},
      {
        'entry_key': 'within_2m',
        'display_value': 'Within 2 m',
        'point_value': 5,
      },
    ]);
    // Back on the list.
    expect(find.byKey(const ValueKey('save-landing')), findsNothing);
  });

  testWidgets('validates the name, keys and points before sending', (
    tester,
  ) async {
    await open(tester);

    await save(tester);
    expect(find.text('Name is required.'), findsOneWidget);
    expect(find.text('Key is required.'), findsOneWidget);
    expect(find.text('Points is required.'), findsOneWidget);

    await type(tester, 'landing-name', 'Club');
    await type(tester, 'entry-key-0', 'a');
    await type(tester, 'entry-points-0', '-1');
    await save(tester);
    expect(find.text('Points cannot be negative.'), findsOneWidget);

    await type(tester, 'entry-points-0', '1.5');
    await save(tester);
    expect(find.text('Enter a whole number.'), findsOneWidget);
    expect(requests.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('a repeated key is refused on the later row', (tester) async {
    await open(tester);

    await type(tester, 'landing-name', 'Club');
    await type(tester, 'entry-key-0', 'within_1m');
    await type(tester, 'entry-points-0', '10');
    await tester.tap(find.byKey(const ValueKey('add-landing-entry')));
    await tester.pumpAndSettle();
    await type(tester, 'entry-key-1', ' within_1m ');
    await type(tester, 'entry-points-1', '5');
    await save(tester);

    expect(find.text('Key is already used in this table.'), findsOneWidget);
    expect(requests.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('the last entry cannot be removed; others can', (tester) async {
    await open(tester);

    IconButton remove(int i) =>
        tester.widget(find.byKey(ValueKey('remove-entry-$i')));
    expect(remove(0).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('add-landing-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('remove-entry-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('entry-key-1')), findsNothing);
  });

  testWidgets('a failed save keeps the entered values and shows the reason', (
    tester,
  ) async {
    await open(
      tester,
      respond: (_) async =>
          errorResponse(400, 'bad_request', 'the server said no'),
    );

    await type(tester, 'landing-name', 'Club');
    await type(tester, 'entry-key-0', 'a');
    await type(tester, 'entry-points-0', '3');
    await save(tester);

    expect(find.text('the server said no'), findsOneWidget);
    expect(find.text('Club'), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
  });
}
