import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_public/pages/results/results_page.dart';
import 'package:soar_score_public/widgets/results/contest_filter_bar.dart';

import 'results_page_helpers.dart';

void main() {
  final data = [
    summary(
      name: 'Contest Alpha',
      start: DateTime(2026, 10, 10, 9),
      city: 'Dayton',
    ),
    summary(
      name: 'Contest Beta',
      start: DateTime(2026, 10, 3, 9),
      city: 'Muncie',
    ),
    summary(
      name: 'Contest Gamma',
      start: DateTime(2026, 9, 20, 9),
      city: 'Dayton',
    ),
  ];

  testWidgets('name filter narrows the list and updates the URL', (
    tester,
  ) async {
    final router = await pumpResults(tester, data);
    await tester.enterText(find.byKey(ContestFilterBar.nameField), 'be');
    await tester.pumpAndSettle();

    expect(listedNames(tester), ['Contest Beta']);
    expect(router.state.uri.toString(), '${ResultsPage.path}?name=be');
  });

  testWidgets('typing keeps the text across URL rebuilds', (tester) async {
    await pumpResults(tester, data);
    await tester.enterText(find.byKey(ContestFilterBar.nameField), 'g');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(ContestFilterBar.nameField), 'ga');
    await tester.pumpAndSettle();
    expect(find.text('ga'), findsOneWidget);
    expect(listedNames(tester), ['Contest Gamma']);
  });

  testWidgets('venue filter narrows the list', (tester) async {
    await pumpResults(tester, data);
    await tester.enterText(find.byKey(ContestFilterBar.venueField), 'dayton');
    await tester.pumpAndSettle();
    expect(listedNames(tester), ['Contest Alpha', 'Contest Gamma']);
  });

  testWidgets('start date range filters inclusively', (tester) async {
    await pumpResults(
      tester,
      data,
      location: '${ResultsPage.path}?from=2026-10-03&to=2026-10-10',
    );
    expect(listedNames(tester), ['Contest Alpha', 'Contest Beta']);
  });

  testWidgets('a bookmarked URL restores the filters', (tester) async {
    await pumpResults(
      tester,
      data,
      location: '${ResultsPage.path}?name=alpha&venue=day&from=2026-10-01',
    );
    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('day'), findsOneWidget);
    expect(find.text('2026-10-01'), findsOneWidget);
    expect(listedNames(tester), ['Contest Alpha']);
  });

  testWidgets('clear removes every filter and the query', (tester) async {
    final router = await pumpResults(
      tester,
      data,
      location: '${ResultsPage.path}?name=alpha',
    );
    await tester.tap(find.byKey(ContestFilterBar.clearButton));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), ResultsPage.path);
    expect(listedNames(tester), hasLength(3));
    expect(find.byKey(ContestFilterBar.clearButton), findsNothing);
  });

  testWidgets('summary counts contests active in the last 30 days', (
    tester,
  ) async {
    await pumpResults(tester, [
      // Inside the window: ended 29 days ago.
      summary(
        name: 'Contest Recent',
        start: DateTime(2026, 9, 14, 9),
        end: DateTime(2026, 9, 15, 17),
      ),
      // Outside the window: ended 31 days ago.
      summary(
        name: 'Contest Old',
        start: DateTime(2026, 9, 12, 9),
        end: DateTime(2026, 9, 13, 17),
      ),
      // In progress today.
      summary(
        name: 'Contest Now',
        start: DateTime(2026, 10, 14, 9),
        end: DateTime(2026, 10, 14, 17),
      ),
      // Future weekend: listed but not counted.
      summary(name: 'Contest Weekend', start: DateTime(2026, 10, 17, 9)),
    ]);
    expect(
      find.text('2 contests completed or in progress in the last 30 days'),
      findsOneWidget,
    );
  });
}
