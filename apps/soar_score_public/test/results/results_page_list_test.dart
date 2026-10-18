import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_public/pages/results/results_page.dart';

import 'results_page_helpers.dart';

// Hidden-contest rules, one by one. Delisted, deleted, unpublished and
// private contests never arrive from `GET /public/publications` (the server
// lists Public publications only), so the client has nothing to hide and
// nothing to test for them. The future-date rule is the only one applied
// here; it moves to the server with #455.
void main() {
  testWidgets('lists the 10 most recent contests by start, newest first', (
    tester,
  ) async {
    final data = [
      // Published out of start order to show the client sorts.
      for (var i = 1; i <= 12; i++)
        summary(
          name: 'Contest $i',
          start: now.subtract(Duration(days: 3 * ((i * 7) % 12 + 1))),
        ),
    ];
    await pumpResults(tester, data);

    final names = listedNames(tester);
    expect(names, hasLength(ResultsPage.defaultCount));
    final starts = {for (final d in data) d.contest['name']: d.publishedAt};
    for (var i = 1; i < names.length; i++) {
      expect(starts[names[i - 1]]!.isAfter(starts[names[i]]!), isTrue);
    }
  });

  testWidgets('shows a contest starting on or before the coming Sunday', (
    tester,
  ) async {
    await pumpResults(tester, [
      summary(name: 'Contest Saturday', start: DateTime(2026, 10, 17, 9)),
      summary(name: 'Contest Sunday', start: DateTime(2026, 10, 18, 9)),
    ]);
    expect(listedNames(tester), ['Contest Sunday', 'Contest Saturday']);
  });

  testWidgets('hides a contest starting after the coming Sunday', (
    tester,
  ) async {
    await pumpResults(tester, [
      summary(name: 'Contest Monday', start: DateTime(2026, 10, 19, 9)),
      summary(name: 'Contest Past', start: DateTime(2026, 10, 10, 9)),
    ]);
    expect(listedNames(tester), ['Contest Past']);
  });

  testWidgets('derives the status from the end date', (tester) async {
    await pumpResults(tester, [
      summary(
        name: 'Contest Done',
        start: DateTime(2026, 10, 10, 9),
        end: DateTime(2026, 10, 11, 17),
      ),
      summary(
        name: 'Contest Flying',
        start: DateTime(2026, 10, 13, 9),
        end: DateTime(2026, 10, 15, 17),
      ),
    ]);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
  });

  testWidgets('a status from the projection wins over the end date', (
    tester,
  ) async {
    await pumpResults(tester, [
      summary(
        name: 'Contest Scoring',
        start: DateTime(2026, 10, 10, 9),
        end: DateTime(2026, 10, 11, 17),
        status: 'in_progress',
      ),
    ]);
    expect(find.text('In progress'), findsOneWidget);
  });

  testWidgets('shows the venue from host, city, state and country', (
    tester,
  ) async {
    await pumpResults(tester, [
      summary(
        name: 'Contest Venue',
        start: DateTime(2026, 10, 10, 9),
        host: 'Club',
        city: 'Dayton',
        state: 'OH',
        country: 'USA',
      ),
    ]);
    expect(find.text('Club, Dayton, OH, USA'), findsOneWidget);
  });

  testWidgets('tapping a row opens the contest', (tester) async {
    final id = Id.create();
    await pumpResults(tester, [
      summary(name: 'Contest Tap', start: DateTime(2026, 10, 10, 9), id: id),
    ]);
    await tester.tap(find.text('Contest Tap'));
    await tester.pumpAndSettle();
    expect(find.text('contest ${id.value}'), findsOneWidget);
  });

  testWidgets('refresh reloads the list without a navigation', (tester) async {
    var calls = 0;
    await pumpResults(
      tester,
      const [],
      loader: () async {
        calls++;
        return [
          summary(name: 'Contest $calls', start: DateTime(2026, 10, 10, 9)),
        ];
      },
    );
    expect(listedNames(tester), ['Contest 1']);

    await tester.tap(find.byKey(ResultsPage.refreshButton));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(listedNames(tester), ['Contest 2']);
  });

  testWidgets('shows the load error', (tester) async {
    await pumpResults(
      tester,
      const [],
      loader: () async => throw StateError('down'),
    );
    expect(find.textContaining('Could not load contests'), findsOneWidget);
  });
}
