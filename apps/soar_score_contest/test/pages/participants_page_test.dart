import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../support/participant_test_support.dart';

void main() {
  testWidgets('lists the participants the API returns', (tester) async {
    final client = clientFor(
      (_) async => json({
        'participants': [
          profile('Ada', 'Lovelace', club: 'Front Range').toJson(),
          profile('Bo', 'Peep', n: 11).toJson(),
        ],
      }),
    );

    await tester.pumpWidget(participantsApp(client));
    await tester.pumpAndSettle();

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Front Range · ada@example.com'), findsOneWidget);
    expect(find.text('Bo Peep'), findsOneWidget);
  });

  testWidgets('shows an empty state', (tester) async {
    final client = clientFor((_) async => json({'participants': []}));

    await tester.pumpWidget(participantsApp(client));
    await tester.pumpAndSettle();

    expect(find.text('No participants yet.'), findsOneWidget);
  });

  testWidgets('shows the failure and retries', (tester) async {
    var calls = 0;
    final client = clientFor((_) async {
      calls++;
      return calls == 1
          ? errorResponse(500, 'internal', 'Something broke.')
          : json({
              'participants': [profile('Ada', 'Lovelace').toJson()],
            });
    });

    await tester.pumpWidget(participantsApp(client));
    await tester.pumpAndSettle();
    expect(find.text('Participants could not be loaded.'), findsOneWidget);
    expect(find.text('Something broke.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });

  testWidgets('add opens the editor and a row opens its profile', (
    tester,
  ) async {
    final client = clientFor(
      (request) async => request.url.path.endsWith('/participants')
          ? json({
              'participants': [profile('Ada', 'Lovelace').toJson()],
            })
          : json(profile('Ada', 'Lovelace').toJson()),
    );

    await tester.pumpWidget(participantsApp(client));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-participant')));
    await tester.pumpAndSettle();
    expect(find.text('Add participant'), findsOneWidget);
  });

  testWidgets('delete asks first, then removes the participant', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final client = clientFor((request) async {
      if (request.method == 'DELETE') {
        return http.Response('', 204);
      }
      return json({
        'participants': [profile('Ada', 'Lovelace').toJson()],
      });
    }, requests: requests);

    await tester.pumpWidget(participantsApp(client));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete Ada Lovelace'));
    await tester.pumpAndSettle();
    expect(find.text('Delete participant?'), findsOneWidget);
    expect(requests.where((r) => r.method == 'DELETE'), isEmpty);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(requests.where((r) => r.method == 'DELETE'), hasLength(1));
  });

  testWidgets('delete shows the server reason when it is refused', (
    tester,
  ) async {
    final client = clientFor((request) async {
      if (request.method == 'DELETE') {
        return errorResponse(
          409,
          'participant_in_use',
          'The participant is in a contest.',
        );
      }
      return json({
        'participants': [profile('Ada', 'Lovelace').toJson()],
      });
    });

    await tester.pumpWidget(participantsApp(client));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete Ada Lovelace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('The participant is in a contest.'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });
}
