import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/participant_test_support.dart';

/// A server whose copy of the profile changed elsewhere: the first save is
/// refused as stale, later reads return [theirs] at a newer revision.
({
  Future<http.Response> Function(http.Request) respond,
  List<http.Request> requests,
})
_staleServer(ParticipantProfile opened, ParticipantProfile theirs) {
  final requests = <http.Request>[];
  var refused = false;
  Future<http.Response> respond(http.Request request) async {
    requests.add(request);
    if (request.method == 'PUT') {
      if (!refused) {
        refused = true;
        return errorResponse(409, 'stale_revision', 'It changed elsewhere.');
      }
      return json(theirs.toJson());
    }
    return json((refused ? theirs : opened).toJson());
  }

  return (respond: respond, requests: requests);
}

ParticipantProfile _changedElsewhere(ParticipantProfile base) =>
    ParticipantProfile(
      id: base.id,
      ownerAccountId: base.ownerAccountId,
      firstName: base.firstName,
      lastName: base.lastName,
      email: base.email,
      club: 'Orlando Soaring Society',
      city: 'Orlando',
      createdAt: base.createdAt,
      updatedAt: DateTime.utc(2026, 10),
      revision: base.revision + 1,
    );

Future<void> _openEdited(
  WidgetTester tester,
  ParticipantProfile opened,
  Future<http.Response> Function(http.Request) respond,
) async {
  useTallWindow(tester);
  await tester.pumpWidget(
    participantsApp(
      clientFor(respond),
      initial: participantPath(opened.id.value),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final opened = profile('Ada', 'Lovelace', revision: 3, club: 'Tampa Bay');
  final theirs = _changedElsewhere(opened);

  testWidgets('a stale save names the fields that changed and blocks Save', (
    tester,
  ) async {
    final server = _staleServer(opened, theirs);
    await _openEdited(tester, opened, server.respond);
    await enterField(tester, 'last-name', 'King');
    await saveEditor(tester);

    expect(
      find.text('This participant was changed elsewhere since you opened it.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Club and City were changed elsewhere.'),
      findsOneWidget,
    );
    expect(find.text('King'), findsOneWidget);
    expect(find.text('Resolve the conflict above to save.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('save-participant')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('Reload their version drops the edits', (tester) async {
    final server = _staleServer(opened, theirs);
    await _openEdited(tester, opened, server.respond);
    await enterField(tester, 'last-name', 'King');
    await saveEditor(tester);
    await tester.tap(find.byKey(const ValueKey('reload-latest')));
    await tester.pumpAndSettle();

    expect(find.text('Orlando Soaring Society'), findsWidgets);
    expect(find.text('King'), findsNothing);
    expect(find.byKey(const ValueKey('save-participant')), findsNothing);
  });

  testWidgets('review starts on mine where edited and theirs elsewhere', (
    tester,
  ) async {
    final server = _staleServer(opened, theirs);
    await _openEdited(tester, opened, server.respond);
    // The director changes the club; the other device changed club and city.
    await enterField(tester, 'club', 'My Club');
    await saveEditor(tester);
    await tester.tap(find.byKey(const ValueKey('review-start')));
    await tester.pumpAndSettle();

    expect(find.text('Review differences'), findsWidgets);
    Finder picked(String field, String side) => find.descendant(
      of: find.byKey(ValueKey('review-$field-$side')),
      matching: find.byIcon(Icons.radio_button_checked),
    );
    expect(picked('club', 'mine'), findsOneWidget);
    expect(picked('club', 'theirs'), findsNothing);
    expect(picked('city', 'theirs'), findsOneWidget);
  });

  testWidgets('applying the review saves the picks against the new revision', (
    tester,
  ) async {
    final server = _staleServer(opened, theirs);
    await _openEdited(tester, opened, server.respond);
    await enterField(tester, 'club', 'My Club');
    await saveEditor(tester);
    await tester.tap(find.byKey(const ValueKey('review-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('review-city-mine')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('review-apply')));
    await tester.pumpAndSettle();

    final puts = server.requests.where((r) => r.method == 'PUT').toList();
    expect(puts, hasLength(2));
    final body = jsonDecode(puts.last.body) as Map<String, dynamic>;
    expect(body['base_revision'], theirs.revision);
    expect(body['club'], 'My Club');
    // The director chose their own (empty) city over Orlando.
    expect(body['city'], isNull);
  });
}
