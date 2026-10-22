import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:soar_score_contest/router.dart';

import '../support/participant_test_support.dart';

Future<List<http.Request>> _open(WidgetTester tester) async {
  useTallWindow(tester);
  final requests = <http.Request>[];
  final client = clientFor((request) async {
    if (request.method == 'POST') {
      return json(profile('Sam', 'Okafor', n: 12).toJson(), 201);
    }
    return json({'participants': []});
  }, requests: requests);
  await tester.pumpWidget(participantsApp(client, initial: newParticipantPath));
  await tester.pumpAndSettle();
  return requests;
}

Future<void> _fillSam(WidgetTester tester) async {
  await enterField(tester, 'first-name', 'Sam');
  await enterField(tester, 'last-name', 'Okafor');
  await enterField(tester, 'email', 'sam.okafor@example.com');
  await enterField(tester, 'club', 'Tampa Bay Soaring Society');
  await enterField(tester, 'city', 'Tampa');
  await enterField(tester, 'fai-number', 'USA-1');
}

Future<void> _saveAndAddAnother(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('save-add-another')));
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;

void main() {
  testWidgets('clears the form and keeps club and location', (tester) async {
    final requests = await _open(tester);
    await _fillSam(tester);
    await _saveAndAddAnother(tester);

    expect(requests.where((r) => r.method == 'POST'), hasLength(1));
    expect(find.text('Sam Okafor added'), findsOneWidget);
    expect(_text(tester, 'first-name'), isEmpty);
    expect(_text(tester, 'email'), isEmpty);
    expect(_text(tester, 'fai-number'), isEmpty);
    expect(_text(tester, 'club'), 'Tampa Bay Soaring Society');
    expect(_text(tester, 'city'), 'Tampa');
    expect(
      find.text('Club and location kept from Sam Okafor.'),
      findsOneWidget,
    );
  });

  testWidgets('Clear them empties the kept values', (tester) async {
    await _open(tester);
    await _fillSam(tester);
    await _saveAndAddAnother(tester);
    await tester.tap(find.text('Clear them'));
    await tester.pump();

    expect(_text(tester, 'club'), isEmpty);
    expect(_text(tester, 'city'), isEmpty);
    expect(find.byKey(const ValueKey('kept-values')), findsNothing);
  });

  testWidgets('unchecking Keep clears club and location too', (tester) async {
    await _open(tester);
    await _fillSam(tester);
    await tester.ensureVisible(
      find.byKey(const ValueKey('keep-club-location')),
    );
    await tester.tap(find.byKey(const ValueKey('keep-club-location')));
    await tester.pump();
    await _saveAndAddAnother(tester);

    expect(_text(tester, 'club'), isEmpty);
    expect(find.byKey(const ValueKey('kept-values')), findsNothing);
  });

  testWidgets('the saved participant is sent without kept fields blanked', (
    tester,
  ) async {
    final requests = await _open(tester);
    await _fillSam(tester);
    await _saveAndAddAnother(tester);

    final body = jsonDecode(
      requests.firstWhere((r) => r.method == 'POST').body,
    ) as Map<String, dynamic>;
    expect(body['club'], 'Tampa Bay Soaring Society');
    expect(body['fai_number'], 'USA-1');
  });

  testWidgets('it is not offered when editing', (tester) async {
    useTallWindow(tester);
    final existing = profile('Ada', 'Lovelace');
    await tester.pumpWidget(
      participantsApp(
        clientFor((_) async => json(existing.toJson())),
        initial: participantPath(existing.id.value),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('save-add-another')), findsNothing);
  });
}
