import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_public/contest_routes.dart';
import 'package:soar_score_public/widgets/results/overall_results_table.dart';
import 'package:soar_score_public/widgets/results/round_selector.dart';

import 'support/fake_publication.dart';

void main() {
  test('contestResultsPath builds both route shapes', () {
    expect(contestResultsPath('abc'), '/results/contests/abc');
    expect(
      contestResultsPath('abc', round: 2),
      '/results/contests/abc/rounds/2',
    );
  });

  testWidgets('the selector changes the route and the table follows', (
    tester,
  ) async {
    final router = await pumpContestRoutes(
      tester,
      contestResultsPath(fakeContestId),
    );
    // Latest round by default: on the last round, next and last are off.
    expect(find.text('Round 3'), findsNWidgets(2)); // dropdown and column
    expect(
      tester.widget<IconButton>(find.byKey(RoundSelector.nextKey)).onPressed,
      isNull,
    );

    await tester.tap(find.byKey(RoundSelector.previousKey));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, contestResultsPath(fakeContestId, round: 2));
    expect(find.text('Round 3'), findsNothing);
    expect(find.text('2${OverallResultsTable.tieIndicator}'), findsNWidgets(2));

    await tester.tap(find.byKey(RoundSelector.firstKey));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, contestResultsPath(fakeContestId, round: 1));
    expect(find.text('Round 2'), findsNothing);
    expect(
      tester.widget<IconButton>(find.byKey(RoundSelector.firstKey)).onPressed,
      isNull,
    );

    await tester.tap(find.byKey(RoundSelector.lastKey));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, contestResultsPath(fakeContestId, round: 3));

    await tester.tap(find.byKey(RoundSelector.dropdownKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Round 2').last);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, contestResultsPath(fakeContestId, round: 2));
  });

  testWidgets('a round without standings keeps the selector live', (
    tester,
  ) async {
    await pumpContestRoutes(
      tester,
      contestResultsPath(fakeContestId, round: 7),
    );
    expect(find.text('There are no results for round 7.'), findsOneWidget);
    expect(find.byKey(RoundSelector.dropdownKey), findsOneWidget);
  });
}
