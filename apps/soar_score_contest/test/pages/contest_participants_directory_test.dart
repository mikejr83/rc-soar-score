import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:soar_score_core/soar_score_core.dart';

import '../support/fake_app_connectivity.dart';
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
    // Typing never asks for an ID with an @; the button does.
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('directory-lookup')));
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

  Finder searchField() => find.descendant(
    of: find.byKey(const ValueKey('participant-search')),
    matching: find.byType(TextField),
  );

  testWidgets('offline, the lookup button is there but off', (tester) async {
    final connectivity = FakeAppConnectivity();
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(),
      auth: FakeAuthSession(signedIn: true),
      connectivity: connectivity,
      intercept: _directory,
    );
    await tester.enterText(searchField(), 'F9999');
    await tester.pump();
    IconButton button() => tester.widget<IconButton>(
      find.byKey(const ValueKey('directory-lookup')),
    );
    expect(button().onPressed, isNotNull);

    connectivity.internetStatus = ConnectivityStatus.unavailable;
    connectivity.notifyListeners();
    await tester.pump();

    await tester.pump(const Duration(seconds: 1));
    expect(button().onPressed, isNull);
    expect(button().tooltip, contains('only be searched online'));
  });

  testWidgets('a refused lookup says to wait', (tester) async {
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(),
      auth: FakeAuthSession(signedIn: true),
      intercept: (request) async {
        if (request.url.path.contains('/directory/')) {
          return errorResponse(429, 'rate_limited', 'slow down');
        }
        return null;
      },
    );
    await tester.enterText(searchField(), 'F9999');
    await tester.tap(find.byKey(const ValueKey('directory-lookup')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('directory-lookup-rate-limited')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('directory-lookup-failed')), findsNothing);
  });

  testWidgets('pilots sharing an ID are told apart by country', (tester) async {
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(),
      auth: FakeAuthSession(signedIn: true),
      intercept: (request) async {
        if (!request.url.path.endsWith('/directory/lookups')) return null;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return json({
          'results': body['key'] == 'fai_number'
              ? [
                  {..._match(), 'email': null, 'country': 'US'},
                  {
                    ..._match(),
                    'entry_id': '019c0000-0000-7000-8000-0000000000a2',
                    'first_name': 'Pia',
                    'last_name': 'Wardt',
                    'email': null,
                    'country': 'DE',
                  },
                ]
              : [],
        });
      },
    );
    await tester.enterText(searchField(), 'F9999');
    await tester.tap(find.byKey(const ValueKey('directory-lookup')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Pia Ward'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Pia Wardt'), findsOneWidget);
    expect(find.textContaining('US'), findsOneWidget);
    expect(find.textContaining('DE'), findsOneWidget);
    expect(find.textContaining('ID F9999'), findsNWidgets(2));
  });
}
