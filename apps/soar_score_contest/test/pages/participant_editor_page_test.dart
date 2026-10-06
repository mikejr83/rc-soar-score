import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:soar_score_contest/router.dart';

import '../support/participant_test_support.dart';

Future<void> _enter(WidgetTester tester, String key, String text) =>
    tester.enterText(find.byKey(ValueKey(key)), text);

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('save-participant')));
  await tester.pumpAndSettle();
}

Map<String, dynamic> _body(http.Request request) =>
    jsonDecode(request.body) as Map<String, dynamic>;

void main() {
  testWidgets('requires first name, last name and a valid email', (
    tester,
  ) async {
    useTallWindow(tester);
    final requests = <http.Request>[];
    final client = clientFor(
      (_) async => json({'participants': []}),
      requests: requests,
    );

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await _enter(tester, 'email', 'not-an-email');
    await _save(tester);

    expect(find.text('First name is required.'), findsOneWidget);
    expect(find.text('Last name is required.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('creates a participant and returns to the list', (tester) async {
    useTallWindow(tester);
    final requests = <http.Request>[];
    final client = clientFor((request) async {
      if (request.method == 'POST') {
        return json(profile('Ada', 'Lovelace').toJson(), 201);
      }
      return json({'participants': []});
    }, requests: requests);

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await _enter(tester, 'first-name', ' Ada ');
    await _enter(tester, 'last-name', 'Lovelace');
    await _enter(tester, 'email', 'ada@example.com');
    await _save(tester);

    final post = requests.singleWhere((r) => r.method == 'POST');
    final body = _body(post);
    expect(body['first_name'], 'Ada');
    expect(body['last_name'], 'Lovelace');
    expect(body['email'], 'ada@example.com');
    expect(body['club'], isNull);
    expect(find.text('Participants'), findsOneWidget);
  });

  testWidgets('shows a duplicate email before creating a second profile', (
    tester,
  ) async {
    useTallWindow(tester);
    final requests = <http.Request>[];
    final client = clientFor((request) async {
      if (request.method == 'POST') {
        return json(profile('Ada', 'Lovelace', n: 12).toJson(), 201);
      }
      return json({
        'participants': [profile('Ada', 'Lovelace').toJson()],
      });
    }, requests: requests);

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await _enter(tester, 'first-name', 'Ada');
    await _enter(tester, 'last-name', 'L');
    await _enter(tester, 'email', 'ADA@example.com');
    await _save(tester);

    expect(find.byKey(const ValueKey('duplicate-notice')), findsOneWidget);
    expect(requests.where((r) => r.method == 'POST'), isEmpty);

    await tester.tap(find.byKey(const ValueKey('create-separate')));
    await tester.pumpAndSettle();
    expect(requests.where((r) => r.method == 'POST'), hasLength(1));
  });

  testWidgets('keeps entered values when the save fails', (tester) async {
    useTallWindow(tester);
    final client = clientFor((request) async {
      if (request.method == 'POST') {
        return errorResponse(400, 'invalid', 'Last name is too long.');
      }
      return json({'participants': []});
    });

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await _enter(tester, 'first-name', 'Ada');
    await _enter(tester, 'last-name', 'Lovelace');
    await _enter(tester, 'email', 'ada@example.com');
    await _save(tester);

    expect(find.text('Last name is too long.'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Add participant'), findsOneWidget);
  });

  testWidgets('edits a profile with its base revision', (tester) async {
    useTallWindow(tester);
    final requests = <http.Request>[];
    final existing = profile('Ada', 'Lovelace', revision: 3);
    final client = clientFor((request) async {
      if (request.method == 'PUT') {
        return json(existing.toJson());
      }
      return json(existing.toJson());
    }, requests: requests);

    await tester.pumpWidget(
      participantsApp(client, initial: participantPath(existing.id.value)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit participant'), findsOneWidget);
    expect(find.text('ada@example.com'), findsOneWidget);

    await _enter(tester, 'last-name', 'King');
    await _save(tester);

    final put = requests.singleWhere((r) => r.method == 'PUT');
    expect(_body(put)['base_revision'], 3);
    expect(_body(put)['last_name'], 'King');
  });

  testWidgets('shows a stale-revision conflict', (tester) async {
    useTallWindow(tester);
    final existing = profile('Ada', 'Lovelace');
    final client = clientFor((request) async {
      if (request.method == 'PUT') {
        return errorResponse(409, 'stale_revision', 'It changed elsewhere.');
      }
      return json(existing.toJson());
    });

    await tester.pumpWidget(
      participantsApp(client, initial: participantPath(existing.id.value)),
    );
    await tester.pumpAndSettle();
    await _enter(tester, 'last-name', 'King');
    await _save(tester);

    expect(find.text('It changed elsewhere.'), findsOneWidget);
  });

  testWidgets('cancel confirms before discarding changes', (tester) async {
    useTallWindow(tester);
    final client = clientFor((_) async => json({'participants': []}));

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await _enter(tester, 'first-name', 'Ada');

    await tester.tap(find.byKey(const ValueKey('cancel-participant')));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Add participant'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cancel-participant')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Participants'), findsOneWidget);
  });

  testWidgets('cancel leaves at once when nothing changed', (tester) async {
    useTallWindow(tester);
    final client = clientFor((_) async => json({'participants': []}));

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cancel-participant')));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Participants'), findsOneWidget);
  });
}
