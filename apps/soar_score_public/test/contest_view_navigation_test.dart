import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_public/contest_routes.dart';
import 'package:soar_score_public/pages/results/contest_page.dart';
import 'package:soar_score_public/widgets/results/pilot_standing_cells.dart';

import 'support/fake_publication.dart';

void main() {
  testWidgets('a round score opens the flight groups scrolled to the pilot', (
    tester,
  ) async {
    // Small enough that the groups view has to scroll.
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var requests = 0;
    final router = await pumpContestRoutes(
      tester,
      contestResultsPath(fakeContestId),
      client: fakeServer(onRequest: () => requests++),
    );

    // Waters' round 3 score is the last 990 in the overall table.
    await tester.ensureVisible(find.text('990').last);
    await tester.tap(find.text('990').last);
    await tester.pumpAndSettle();
    expect(
      router.state.uri.toString(),
      contestFlightGroupsPath(fakeContestId, 3, pilotKey: 'waters'),
    );
    expect(find.text('Flight Group Scores'), findsOneWidget);
    // The selected flight is the re-flight, the last of Waters' two rows.
    final target = find.text('Chuck Waters').last;
    // Scrolled as far toward the flight as the content allows: it is on
    // screen and the first group is above the top.
    expect(tester.getTopLeft(target).dy, lessThan(400));
    expect(tester.getTopLeft(find.text('Group 1')).dy, lessThan(0));

    // Browser back and forward arrive as pushed route information.
    final provider = router.routeInformationProvider;
    await provider.didPushRouteInformation(
      RouteInformation(uri: Uri.parse(contestResultsPath(fakeContestId))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Overall Individual Results'), findsOneWidget);
    await provider.didPushRouteInformation(
      RouteInformation(
        uri: Uri.parse(contestFlightGroupsPath(fakeContestId, 3)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Flight Group Scores'), findsOneWidget);
    expect(requests, 1);
  });

  testWidgets('links move between the views and keep the round', (
    tester,
  ) async {
    final router = await pumpContestRoutes(
      tester,
      contestResultsPath(fakeContestId, round: 2),
    );
    await tester.tap(find.byKey(ContestPage.teamsLinkKey));
    await tester.pumpAndSettle();
    expect(
      router.state.uri.path,
      contestTeamResultsPath(fakeContestId, round: 2),
    );
    expect(find.text('Round 2'), findsNWidgets(2));

    await tester.ensureVisible(find.byKey(roundHeaderKey(1)));
    await tester.tap(find.byKey(roundHeaderKey(1)));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, contestFlightGroupsPath(fakeContestId, 1));
    expect(find.text('Group 1'), findsOneWidget);

    await tester.tap(find.byKey(ContestPage.overallLinkKey));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, contestResultsPath(fakeContestId, round: 1));

    await tester.tap(find.byKey(ContestPage.flightGroupsLinkKey));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, contestFlightGroupsPath(fakeContestId, 1));
  });
}
