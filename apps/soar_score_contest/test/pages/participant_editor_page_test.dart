import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:soar_score_contest/router.dart';

import '../support/participant_test_support.dart';

Map<String, dynamic> _body(http.Request request) =>
    jsonDecode(request.body) as Map<String, dynamic>;

void main() {
  testWidgets('a pristine add form cannot be saved', (tester) async {
    useTallWindow(tester);
    final client = clientFor((_) async => json({'participants': []}));

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();

    Finder button(String key) => find.byKey(ValueKey(key));
    expect(
      tester.widget<FilledButton>(button('save-participant')).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(button('save-add-another')).onPressed,
      isNull,
    );

    await enterField(tester, 'first-name', 'Sam');
    expect(
      tester.widget<FilledButton>(button('save-participant')).onPressed,
      isNotNull,
    );
    expect(
      tester.widget<OutlinedButton>(button('save-add-another')).onPressed,
      isNotNull,
    );
  });

  testWidgets('shows field errors after a failed save and keeps entries', (
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
    expect(find.text('Enter a first name'), findsNothing);

    await enterField(tester, 'first-name', 'Sam');
    await enterField(tester, 'email', 'sam.okafor@example');
    await saveEditor(tester);

    // The inline message and the summary entry both say it.
    expect(find.text('Enter a last name'), findsOneWidget);
    expect(find.text('Enter an email like name@example.com'), findsOneWidget);
    expect(find.text('2 fields need attention'), findsOneWidget);
    expect(find.text('Last name: Enter a last name'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('the summary moves focus to the field', (tester) async {
    useTallWindow(tester);
    final client = clientFor((_) async => json({'participants': []}));

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await enterField(tester, 'club', 'Tampa Bay');
    await saveEditor(tester);

    final lastName = tester.widget<TextField>(
      find.byKey(const ValueKey('last-name')),
    );
    expect(lastName.focusNode!.hasFocus, isFalse);
    // Focus first moved to the first invalid field.
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('first-name')))
          .focusNode!
          .hasFocus,
      isTrue,
    );
    await tester.tap(find.text('Last name: Enter a last name'));
    await tester.pump();
    expect(lastName.focusNode!.hasFocus, isTrue);
  });

  testWidgets('a field shows its error once it is left', (tester) async {
    useTallWindow(tester);
    final client = clientFor((_) async => json({'participants': []}));

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await enterField(tester, 'email', 'nope');
    expect(find.text('Enter an email like name@example.com'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('first-name')));
    await tester.pump();
    expect(find.text('Enter an email like name@example.com'), findsOneWidget);
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
    await enterField(tester, 'first-name', ' Ada ');
    await enterField(tester, 'last-name', 'Lovelace');
    await enterField(tester, 'email', 'ada@example.com');
    await enterField(tester, 'country', 'united states');
    await saveEditor(tester);

    final post = requests.singleWhere((r) => r.method == 'POST');
    final body = _body(post);
    expect(body['first_name'], 'Ada');
    expect(body['last_name'], 'Lovelace');
    expect(body['email'], 'ada@example.com');
    expect(body['club'], isNull);
    // A typed country that matches the list uses the list's spelling.
    expect(body['country'], 'United States');
    expect(find.text('No participants yet.'), findsOneWidget);
  });

  testWidgets('keeps entered values when the save fails and retries', (
    tester,
  ) async {
    useTallWindow(tester);
    var failing = true;
    final client = clientFor((request) async {
      if (request.method == 'POST') {
        return failing
            ? errorResponse(400, 'invalid', 'Last name is too long.')
            : json(profile('Ada', 'Lovelace').toJson(), 201);
      }
      return json({'participants': []});
    });

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await enterField(tester, 'first-name', 'Ada');
    await enterField(tester, 'last-name', 'Lovelace');
    await enterField(tester, 'email', 'ada@example.com');
    await saveEditor(tester);

    expect(find.byKey(const ValueKey('save-error')), findsOneWidget);
    expect(find.text('Last name is too long.'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Add participant'), findsWidgets);

    failing = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('No participants yet.'), findsOneWidget);
  });

  testWidgets('edits a profile with its base revision', (tester) async {
    useTallWindow(tester);
    final requests = <http.Request>[];
    final existing = profile('Ada', 'Lovelace', revision: 3);
    final client = clientFor((request) async {
      return json(existing.toJson());
    }, requests: requests);

    await tester.pumpWidget(
      participantsApp(client, initial: participantPath(existing.id.value)),
    );
    await tester.pumpAndSettle();
    // The title is the saved name; the bar waits for the first change.
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.byKey(const ValueKey('save-participant')), findsNothing);
    expect(find.byKey(const ValueKey('cancel-participant')), findsNothing);
    expect(find.text('ada@example.com'), findsOneWidget);

    await enterField(tester, 'last-name', 'King');
    expect(find.byKey(const ValueKey('save-participant')), findsOneWidget);
    expect(find.text('Unsaved changes'), findsOneWidget);
    // The title still shows the saved name.
    expect(find.text('Ada Lovelace'), findsOneWidget);
    await saveEditor(tester);

    final put = requests.singleWhere((r) => r.method == 'PUT');
    expect(_body(put)['base_revision'], 3);
    expect(_body(put)['last_name'], 'King');
  });

  testWidgets('an existing profile without an email asks for one', (
    tester,
  ) async {
    useTallWindow(tester);
    final existing = profile('Ada', 'Lovelace');
    final json0 = existing.toJson()..remove('email');
    final client = clientFor((_) async => json(json0));

    await tester.pumpWidget(
      participantsApp(client, initial: participantPath(existing.id.value)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No email on file. Add an email to save.'),
      findsOneWidget,
    );
  });

  testWidgets('a profile that cannot load offers Try again', (tester) async {
    useTallWindow(tester);
    final existing = profile('Ada', 'Lovelace');
    var failing = true;
    final client = clientFor((_) async {
      return failing
          ? errorResponse(500, 'oops', 'The server is busy.')
          : json(existing.toJson());
    });

    await tester.pumpWidget(
      participantsApp(client, initial: participantPath(existing.id.value)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t load this participant'), findsOneWidget);
    expect(find.text('The server is busy.'), findsOneWidget);

    failing = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });

  testWidgets('cancel confirms before discarding changes', (tester) async {
    useTallWindow(tester);
    final client = clientFor((_) async => json({'participants': []}));

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await enterField(tester, 'first-name', 'Ada');

    await tester.tap(find.byKey(const ValueKey('cancel-participant')));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('first-name')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cancel-participant')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('No participants yet.'), findsOneWidget);
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
    expect(find.text('No participants yet.'), findsOneWidget);
  });
}
