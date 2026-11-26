import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../support/fake_auth_session.dart';
import '../support/participant_test_support.dart';
import '../support/participants_page_support.dart';

/// A directory pilot who is the director's own Pia Ward (same email, shown by
/// the pilot) under an FAI number only the directory holds.
Map<String, Object?> _match() => {
  'entry_id': '019c0000-0000-7000-8000-0000000000a1',
  'first_name': 'Pia',
  'last_name': 'Ward',
  'club': null,
  'fai_number': 'F9999',
  'national_org_id': null,
  'city': null,
  'state': null,
  'country': null,
  'email': 'p7@example.com',
  'email_available': true,
};

Future<http.Response?> _directory(http.Request request) async {
  if (!request.url.path.contains('/directory/')) return null;
  final body = jsonDecode(request.body) as Map<String, dynamic>;
  return json({
    'results': body['key'] == 'fai_number' ? [_match()] : [],
  });
}

/// The contest Participants page offers the director's own profile, not a
/// second copy, when a directory pilot is one they already hold (#653).
void main() {
  testWidgets('a query only the directory matches still shows the profile', (
    tester,
  ) async {
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(),
      auth: FakeAuthSession(signedIn: true),
      intercept: _directory,
    );

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('participant-search')),
        matching: find.byType(TextField),
      ),
      'F9999',
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Pia Ward'), findsOneWidget);
    expect(find.text('Directory'), findsNothing);
    expect(find.text('Your profiles'), findsOneWidget);
  });

  testWidgets('the same through the lookup button', (tester) async {
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(),
      auth: FakeAuthSession(signedIn: true),
      intercept: _directory,
    );

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('participant-search')),
        matching: find.byType(TextField),
      ),
      'F9999',
    );
    await tester.tap(find.byKey(const ValueKey('directory-lookup')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Pia Ward'), findsWidgets);
    expect(find.text('Directory'), findsNothing);
  });

  testWidgets('a profile whose FAI number differs only by case is not the '
      'directory pilot', (tester) async {
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(),
      auth: FakeAuthSession(signedIn: true),
      intercept: (request) async {
        if (request.url.path.endsWith('/directory/lookups')) {
          return json({
            'results': [
              {
                ..._match(),
                'first_name': 'Dora',
                'last_name': 'Exact',
                'email': null,
              },
            ],
          });
        }
        if (request.url.path.endsWith('/participants') &&
            request.method == 'GET') {
          return json({
            'participants': [
              profile('Cass', 'Lower', n: 77, fai: 'f9999').toJson(),
            ],
          });
        }
        return null;
      },
    );

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('participant-search')),
        matching: find.byType(TextField),
      ),
      'F9999',
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // The match is offered from the directory; Cass is a different pilot.
    expect(find.widgetWithText(ListTile, 'Dora Exact'), findsOneWidget);
    expect(find.text('Directory'), findsOneWidget);
  });

  testWidgets('an ID shaped like an email is not matched to a profile by '
      'that text', (tester) async {
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(),
      auth: FakeAuthSession(signedIn: true),
      intercept: (request) async {
        if (request.url.path.endsWith('/directory/lookups')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return json({
            'results': body['key'] == 'fai_number'
                ? [
                    {
                      ..._match(),
                      'first_name': 'Dora',
                      'last_name': 'Exact',
                      'fai_number': 'f1@club.org1',
                      'email': null,
                    },
                  ]
                : [],
          });
        }
        if (request.url.path.endsWith('/participants') &&
            request.method == 'GET') {
          return json({
            'participants': [
              profile('Cass', 'Local', n: 77, email: 'f1@club.org1').toJson(),
            ],
          });
        }
        return null;
      },
    );

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('participant-search')),
        matching: find.byType(TextField),
      ),
      'f1@club.org1',
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Dora Exact'), findsOneWidget);
    expect(find.text('Directory'), findsOneWidget);
  });

  testWidgets('choosing an autocomplete result drops a lookup still waiting', (
    tester,
  ) async {
    final release = Completer<void>();
    var waiting = false;
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(),
      auth: FakeAuthSession(signedIn: true),
      intercept: (request) async {
        if (request.url.path.endsWith('/directory/lookups')) {
          waiting = true;
          await release.future;
          return json({
            'results': [
              {
                ..._match(),
                'first_name': 'Dora',
                'last_name': 'Exact',
                'email': null,
              },
            ],
          });
        }
        return null;
      },
    );
    final field = find.descendant(
      of: find.byKey(const ValueKey('participant-search')),
      matching: find.byType(TextField),
    );

    await tester.enterText(field, 'Pia');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('directory-lookup')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(waiting, isTrue, reason: 'the lookup was sent');
    await tester.tap(find.widgetWithText(ListTile, 'Pia Ward'));
    await tester.pump();
    release.complete();
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Dora Exact'), findsNothing);
    expect(find.text('Directory'), findsNothing);
  });

  testWidgets('a lookup that answers after the text was cleared is ignored', (
    tester,
  ) async {
    final release = Completer<void>();
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(),
      auth: FakeAuthSession(signedIn: true),
      intercept: (request) async {
        if (request.url.path.contains('/directory/')) await release.future;
        return _directory(request);
      },
    );
    final field = find.descendant(
      of: find.byKey(const ValueKey('participant-search')),
      matching: find.byType(TextField),
    );

    await tester.enterText(field, 'F9999');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('directory-lookup')));
    await tester.pump();
    await tester.enterText(field, '');
    await tester.pump();
    release.complete();
    await tester.pumpAndSettle();

    expect(find.textContaining('Directory results'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Pia Ward'), findsNothing);
  });
}
