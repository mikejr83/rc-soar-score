import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_public/contest_routes.dart';
import 'package:soar_score_public/models/results/published_contest.dart';
import 'package:soar_score_public/widgets/results/round_selector.dart';
import 'package:soar_score_public/widgets/results/team_results_table.dart';

import 'support/fake_publication.dart';

void main() {
  test('contestTeamResultsPath builds both route shapes', () {
    expect(
      contestTeamResultsPath('abc'),
      '/results/contests/abc/teams/results',
    );
    expect(
      contestTeamResultsPath('abc', round: 2),
      '/results/contests/abc/teams/results/rounds/2',
    );
  });

  test('team rows rank teams and list their pilots by place', () {
    final contest = PublishedContest.fromDto(
      PublicPublicationDto.fromJson(fakePublicationJson()),
    );
    expect(contest.hasTeams, isTrue);
    final teams = contest.teamRowsAsOf(3);
    expect(teams.map((t) => t.name), ['Eagles', 'Hawks']);
    expect(teams[0].teamScore, 5846);
    expect(teams[1].percentOfWinner, closeTo(85.08, 0.01));
    expect(teams[0].pilots.map((p) => p.lastName), ['Smith', 'Adams']);
    expect(teams[1].pilots.map((p) => p.lastName), ['Baker', 'Waters']);
    expect(contest.teamRowsAsOf(9), isEmpty);
  });

  testWidgets('the team view renders team and pilot rows', (tester) async {
    await pumpContestRoutes(tester, contestTeamResultsPath(fakeContestId));
    expect(find.text('Team Scores'), findsOneWidget);
    expect(find.byType(TeamResultsTable), findsOneWidget);
    expect(find.text('Eagles'), findsOneWidget);
    expect(find.text('5846'), findsOneWidget);
    expect(find.text('85.1%'), findsOneWidget);
    expect(find.text('Chuck Waters'), findsOneWidget);
    expect(find.text('Round 3'), findsNWidgets(2)); // dropdown and column

    await tester.tap(find.byKey(RoundSelector.previousKey));
    await tester.pumpAndSettle();
    expect(find.text('3996'), findsOneWidget);
    expect(find.text('Round 3'), findsNothing);
  });

  testWidgets('a contest without teams redirects to its root', (tester) async {
    final router = await pumpContestRoutes(
      tester,
      contestTeamResultsPath(fakeContestId, round: 2),
      client: fakeServer(publication: fakePublicationJson(teams: false)),
    );
    expect(router.state.uri.path, contestResultsPath(fakeContestId, round: 2));
    expect(find.text('Overall Individual Results'), findsOneWidget);
    expect(find.text('Team results'), findsNothing);
  });
}
