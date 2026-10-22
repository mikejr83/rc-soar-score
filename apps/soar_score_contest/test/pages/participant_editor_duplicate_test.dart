import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/pages/participant_editor_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/participant_test_support.dart';

ApiClient _directory(
  List<ParticipantProfile> profiles, {
  List<http.Request>? requests,
}) => clientFor((request) async {
  if (request.method == 'POST') {
    return json(profile('Ada', 'Lovelace', n: 12).toJson(), 201);
  }
  final byId = request.url.pathSegments.last;
  for (final p in profiles) {
    if (p.id.value == byId) {
      return json(p.toJson());
    }
  }
  return json({'participants': profiles.map((p) => p.toJson()).toList()});
}, requests: requests);

Future<void> _fillDuplicate(WidgetTester tester) async {
  await enterField(tester, 'first-name', 'Ada');
  await enterField(tester, 'last-name', 'L');
  await enterField(tester, 'email', 'ADA@example.com');
}

void main() {
  testWidgets('a matching email is mentioned when the field is left', (
    tester,
  ) async {
    useTallWindow(tester);
    final client = _directory([profile('Ada', 'Lovelace')]);

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await enterField(tester, 'email', 'ada@example.com');
    await leaveField(tester, 'email');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('A participant with this email already exists'),
      findsOneWidget,
    );
  });

  testWidgets('an unused email is reported as free', (tester) async {
    useTallWindow(tester);
    final client = _directory([profile('Ada', 'Lovelace')]);

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await enterField(tester, 'email', 'new.person@example.com');
    await leaveField(tester, 'email');
    await tester.pumpAndSettle();

    expect(
      find.text('No existing participant uses this email.'),
      findsOneWidget,
    );
  });

  testWidgets('save shows the decision, masked, and creates nothing yet', (
    tester,
  ) async {
    useTallWindow(tester);
    final requests = <http.Request>[];
    final client = _directory([profile('Ada', 'Lovelace')], requests: requests);

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await _fillDuplicate(tester);
    await saveEditor(tester);

    expect(find.byKey(const ValueKey('duplicate-notice')), findsOneWidget);
    expect(find.text('Someone with this email already exists'), findsOneWidget);
    expect(find.text('a***@example.com'), findsOneWidget);
    expect(find.text('A***@example.com'), findsOneWidget);
    expect(find.text('ada@example.com'), findsNothing);
    expect(find.text('Choose an option above to continue.'), findsOneWidget);
    expect(requests.where((r) => r.method == 'POST'), isEmpty);
    // Save is off while a decision is open.
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('save-participant')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('a second participant with the same email cannot be created', (
    tester,
  ) async {
    useTallWindow(tester);
    final requests = <http.Request>[];
    final client = _directory([profile('Ada', 'Lovelace')], requests: requests);

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await _fillDuplicate(tester);
    await saveEditor(tester);

    expect(find.byKey(const ValueKey('create-separate')), findsNothing);
    expect(find.text('Create a separate participant'), findsNothing);
    expect(find.text('Change the email'), findsOneWidget);
    expect(requests.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('Use existing participant opens it', (tester) async {
    useTallWindow(tester);
    final existing = profile('Ada', 'Lovelace');
    final client = _directory([existing]);

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await _fillDuplicate(tester);
    await saveEditor(tester);
    await tester.tap(find.byKey(const ValueKey('use-existing')));
    await tester.pumpAndSettle();

    // The edit page for the existing profile shows its saved name.
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.byKey(const ValueKey('first-name')), findsOneWidget);
  });

  testWidgets('from the wizard, Use existing hands it to the host', (
    tester,
  ) async {
    useTallWindow(tester);
    final existing = profile('Ada', 'Lovelace');
    ParticipantProfile? chosen;
    await tester.pumpWidget(
      editorApp(
        _directory([existing]),
        ParticipantEditorPage(onDone: (p) => chosen = p),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add to contest'), findsOneWidget);

    await _fillDuplicate(tester);
    await saveEditor(tester);
    expect(
      find.textContaining('Adds Ada Lovelace to this contest.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('use-existing')));
    await tester.pumpAndSettle();

    expect(chosen?.id, existing.id);
  });

  testWidgets('Change the email returns to the form and saves with a new one', (
    tester,
  ) async {
    useTallWindow(tester);
    final requests = <http.Request>[];
    final client = _directory([profile('Ada', 'Lovelace')], requests: requests);

    await tester.pumpWidget(
      participantsApp(client, initial: newParticipantPath),
    );
    await tester.pumpAndSettle();
    await _fillDuplicate(tester);
    await saveEditor(tester);
    await tester.tap(find.byKey(const ValueKey('change-email')));
    await tester.pump();

    expect(find.byKey(const ValueKey('duplicate-notice')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('email')))
          .focusNode!
          .hasFocus,
      isTrue,
    );
    // The entries are kept, and a different email saves.
    expect(find.text('Ada'), findsOneWidget);
    await enterField(tester, 'email', 'ada.l@example.com');
    await saveEditor(tester);
    expect(requests.where((r) => r.method == 'POST'), hasLength(1));
  });
}
