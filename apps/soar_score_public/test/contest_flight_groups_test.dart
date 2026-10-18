import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_public/contest_routes.dart';
import 'package:soar_score_public/models/results/published_contest.dart';
import 'package:soar_score_public/widgets/results/flight_group_table.dart';

import 'support/fake_publication.dart';

void main() {
  test('contestFlightGroupsPath carries the round and the pilot', () {
    expect(
      contestFlightGroupsPath('abc', 2),
      '/results/contests/abc/rounds/2/flight-groups',
    );
    expect(
      contestFlightGroupsPath('abc', 2, pilotKey: 'waters'),
      '/results/contests/abc/rounds/2/flight-groups?pilot=waters',
    );
  });

  test('flight groups keep every flight and split out the re-flight', () {
    final contest = PublishedContest.fromDto(
      PublicPublicationDto.fromJson(fakePublicationJson()),
    );
    final groups = contest.flightGroupsOf(3);
    expect(groups.map((g) => g.title), [
      'Group 1',
      'Group 2',
      'Group 2, re-flight 1',
    ]);
    expect(groups[1].flights.map((f) => f.groupScore), [850, 400]);
    expect(groups[1].flights[1].isSelected, isFalse);
    expect(groups[2].flights.single.pilotKey, 'waters');
    expect(groups[2].detailKeys, ['launch_height']);
    expect(contest.flightGroupsOf(1).single.hasRawComponents, isFalse);
    expect(contest.flightGroupsOf(9), isEmpty);
  });

  test('times format as minutes and seconds', () {
    expect(FlightGroupTable.formatTime(600), '10:00');
    expect(FlightGroupTable.formatTime(598.8), '9:58.8');
    expect(FlightGroupTable.formatTime(null), '-');
  });

  testWidgets('round 3 shows a table per group with the raw columns', (
    tester,
  ) async {
    await pumpContestRoutes(tester, contestFlightGroupsPath(fakeContestId, 3));
    expect(find.text('Flight Group Scores'), findsOneWidget);
    expect(find.byType(FlightGroupTable), findsNWidgets(3));
    expect(find.text('Group 2, re-flight 1'), findsOneWidget);
    expect(find.text('Time'), findsNWidgets(3));
    expect(find.text('Launch height'), findsNWidgets(3));
    expect(find.text('Landing'), findsNWidgets(3));
    expect(find.text('9:58.8'), findsOneWidget);
    expect(find.text('Chuck Waters'), findsNWidgets(2));
    // Points and score both read 400; the score is struck through.
    final replaced = tester.widget<Text>(find.text('400').last);
    expect(replaced.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('a round without raw components hides time and details', (
    tester,
  ) async {
    await pumpContestRoutes(tester, contestFlightGroupsPath(fakeContestId, 1));
    expect(find.byType(FlightGroupTable), findsOneWidget);
    expect(find.text('Time'), findsNothing);
    expect(find.text('Launch height'), findsNothing);
    expect(find.text('Landing'), findsOneWidget);
  });

  testWidgets('a discipline without a landing bonus has no landing column', (
    tester,
  ) async {
    await pumpContestRoutes(
      tester,
      contestFlightGroupsPath(fakeContestId, 3),
      client: fakeServer(publication: fakePublicationJson(discipline: 'F3K')),
    );
    expect(find.byType(FlightGroupTable), findsNWidgets(3));
    expect(find.text('Landing'), findsNothing);
    expect(find.text('Time'), findsNWidgets(3));
  });
}
