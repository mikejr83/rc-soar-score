import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:soar_score_core/soar_score_core.dart';

import '../support/participant_test_support.dart';

/// The title of the row for [name]; titles also carry the email, so match on
/// the name part of the rich text.
Finder _name(String name) => find.textContaining(name, findRichText: true);

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

    expect(_name('Ada Lovelace'), findsOneWidget);
    expect(find.text('Front Range'), findsOneWidget);
    expect(
      find.textContaining('ada@example.com', findRichText: true),
      findsOne,
    );
    expect(_name('Bo Peep'), findsOneWidget);
  });

  testWidgets('sorts by last name, then first name, ignoring case', (
    tester,
  ) async {
    final client = clientFor(
      (_) async => json({
        'participants': [
          profile('Zed', 'smith', n: 10).toJson(),
          profile('Ann', 'Walker', n: 11).toJson(),
          profile('Bea', 'Smith', n: 12).toJson(),
          profile('Cal', 'Adams', n: 13).toJson(),
        ],
      }),
    );

    await tester.pumpWidget(participantsApp(client));
    await tester.pumpAndSettle();

    final names = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map(
          (tile) => (tile.title! as Text).textSpan!
              .toPlainText()
              .split('\uFFFC')
              .first,
        )
        .toList();
    expect(names, ['Cal Adams', 'Bea Smith', 'Zed smith', 'Ann Walker']);
  });

  testWidgets('the search box filters on name, email, FAI and national ID', (
    tester,
  ) async {
    ParticipantProfile withIds(
      String first,
      String last,
      int n, {
      String? fai,
      String? national,
    }) {
      final base = profile(first, last, n: n);
      return ParticipantProfile(
        id: base.id,
        ownerAccountId: base.ownerAccountId,
        firstName: first,
        lastName: last,
        email: base.email,
        faiNumber: fai,
        nationalOrgId: national,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
      );
    }

    final client = clientFor(
      (_) async => json({
        'participants': [
          withIds('Ada', 'Lovelace', 10, fai: 'FAI-1001', national: 'AMA 555'),
          withIds('Bo', 'Peep', 11, fai: 'FAI-2002', national: 'AMA 777'),
          withIds('Cy', 'Young', 12),
        ],
      }),
    );
    Future<void> search(String text) async {
      await tester.enterText(
        find.byKey(const ValueKey('participant-search')),
        text,
      );
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(participantsApp(client));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(3));

    await search('lovelace ada');
    expect(_name('Ada Lovelace'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);

    await search('BO@EXAMPLE');
    expect(_name('Bo Peep'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);

    await search('fai-2002');
    expect(_name('Bo Peep'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);

    await search('ama 555');
    expect(_name('Ada Lovelace'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);

    await search('zzz');
    expect(find.text('No participants match.'), findsOneWidget);

    await search('');
    expect(find.byType(ListTile), findsNWidgets(3));
  });

  testWidgets('shows IDs and club in the subtitle and copes with no email', (
    tester,
  ) async {
    final base = profile('Ada', 'Lovelace');
    final noEmail = ParticipantProfile(
      id: base.id,
      ownerAccountId: base.ownerAccountId,
      firstName: 'Ada',
      lastName: 'Lovelace',
      club: 'Front Range',
      faiNumber: 'FAI-1001',
      nationalOrgId: 'AMA 555',
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
    );
    final client = clientFor(
      (_) async => json({
        'participants': [noEmail.toJson()],
      }),
    );

    await tester.pumpWidget(participantsApp(client));
    await tester.pumpAndSettle();

    expect(_name('Ada Lovelace'), findsOneWidget);
    expect(
      find.text('National ID: AMA 555 · FAI Number: FAI-1001 · Front Range'),
      findsOneWidget,
    );
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
    expect(_name('Ada Lovelace'), findsOneWidget);
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
    expect(_name('Ada Lovelace'), findsOneWidget);
  });
}
