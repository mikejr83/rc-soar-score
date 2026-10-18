import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_public/contest_routes.dart';
import 'package:soar_score_public/pages/results/contest_page.dart';

import 'support/fake_publication.dart';

void main() {
  testWidgets('a round URL opened fresh shows that contest and round', (
    tester,
  ) async {
    final router = await pumpContestRoutes(
      tester,
      contestResultsPath(fakeContestId, round: 2),
    );
    expect(router.state.uri.path, contestResultsPath(fakeContestId, round: 2));
    final page = tester.widget<ContestPage>(find.byType(ContestPage));
    expect(page.contestId, fakeContestId);
    expect(page.round, 2);
    expect(find.text('Front Range ALES Open'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('2026-10-10 to 2026-10-11'), findsOneWidget);
    expect(find.text('Front Range Soaring, Boulder, CO, USA'), findsOneWidget);
    expect(find.text('Round 2'), findsNWidgets(2));
    expect(find.text('Round 3'), findsNothing);
  });

  testWidgets('a contest URL opened fresh shows the latest round', (
    tester,
  ) async {
    await pumpContestRoutes(tester, contestResultsPath(fakeContestId));
    expect(find.text('Round 3'), findsNWidgets(2));
    expect(find.text('John Smith'), findsOneWidget);
  });
}
