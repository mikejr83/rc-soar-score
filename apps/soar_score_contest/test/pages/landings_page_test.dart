import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../support/landing_test_support.dart';
import '../support/participant_test_support.dart';

void main() {
  final system = landingView('F5J Standard', 1, system: true);
  final unused = landingView('Club table', 2);
  final used = landingView('Spring table', 3, inUse: true);

  Future<void> open(
    WidgetTester tester,
    Future<http.Response> Function(http.Request) respond,
  ) async {
    await tester.pumpWidget(landingsApp(clientFor(respond)));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the director\'s tables before the system ones', (
    tester,
  ) async {
    await open(tester, (_) async => json(landingList([system, used, unused])));

    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title! as Text).data)
        .toList();
    expect(titles, ['Club table', 'Spring table', 'F5J Standard']);
    expect(find.text('Landings'), findsOneWidget);
    // Only the table in use shows a lock in the list.
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
  });

  testWidgets('shows the entries of the selected table', (tester) async {
    await open(tester, (_) async => json(landingList([unused])));

    expect(find.text('Label within_1m'), findsOneWidget);
    // Keys are internal and never shown.
    expect(find.text('within_1m'), findsNothing);
    expect(find.text('Key'), findsNothing);
    expect(find.text('10'), findsOneWidget);
    expect(find.byKey(const ValueKey('landing-locked-notice')), findsNothing);
    expect(find.byKey(const ValueKey('delete-landing')), findsOneWidget);
  });

  testWidgets('a system table is read-only and cannot be deleted', (
    tester,
  ) async {
    await open(tester, (_) async => json(landingList([system])));

    expect(find.byKey(const ValueKey('landing-locked-notice')), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-landing')), findsNothing);
    final locked = tester.widget<IconButton>(
      find.byKey(const ValueKey('delete-landing-locked')),
    );
    expect(locked.onPressed, isNull);
    expect(find.byKey(const ValueKey('copy-landing')), findsOneWidget);
  });

  testWidgets('a table a contest uses is locked and says why', (tester) async {
    await open(tester, (_) async => json(landingList([used])));

    expect(find.byKey(const ValueKey('delete-landing')), findsNothing);
    final locked = tester.widget<IconButton>(
      find.byKey(const ValueKey('delete-landing-locked')),
    );
    expect(locked.onPressed, isNull);
    expect(find.textContaining('a contest uses this table'), findsOneWidget);
    // Changing it means a copy, which stays available.
    expect(find.byKey(const ValueKey('copy-landing')), findsOneWidget);
  });

  testWidgets('deleting an unused table asks, then removes it', (tester) async {
    final requests = <http.Request>[];
    var deleted = false;
    final client = clientFor((request) async {
      if (request.method == 'DELETE') {
        deleted = true;
        return http.Response('', 204);
      }
      return json(landingList(deleted ? [system] : [unused, system]));
    }, requests: requests);
    await tester.pumpWidget(landingsApp(client));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('delete-landing')));
    await tester.pumpAndSettle();
    expect(find.text('Delete landing table?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    final delete = requests.singleWhere((r) => r.method == 'DELETE');
    expect(delete.url.path, '/api/v1/landing-tables/${unused.table.id.value}');
    expect(find.widgetWithText(ListTile, 'Club table'), findsNothing);
  });

  testWidgets('a refused delete shows the server\'s reason and reloads', (
    tester,
  ) async {
    var loads = 0;
    await open(tester, (request) async {
      if (request.method == 'DELETE') {
        return errorResponse(409, 'in_use', 'the landing table is used');
      }
      loads++;
      return json(landingList(loads == 1 ? [unused] : [used]));
    });

    await tester.tap(find.byKey(const ValueKey('delete-landing')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('the landing table is used'), findsOneWidget);
    // The reloaded list now shows the table locked.
    expect(find.byKey(const ValueKey('delete-landing-locked')), findsOneWidget);
  });

  testWidgets('Create copy opens the form filled from the table', (
    tester,
  ) async {
    await open(tester, (_) async => json(landingList([used])));

    await tester.tap(find.byKey(const ValueKey('copy-landing')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('landing-name')))
          .controller!
          .text,
      'Copy of Spring table',
    );
    expect(find.byKey(const ValueKey('entry-label-1')), findsOneWidget);
  });

  testWidgets('a failed load offers Retry', (tester) async {
    var calls = 0;
    await open(tester, (_) async {
      calls++;
      return calls == 1
          ? errorResponse(500, 'internal', 'boom')
          : json(landingList([unused]));
    });

    expect(find.text('Landing tables could not be loaded.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Club table'), findsOneWidget);
  });
}
