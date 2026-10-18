import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_public/models/results/published_contest.dart';
import 'package:soar_score_public/widgets/results/overall_results_table.dart';

import 'support/fake_publication.dart';

void main() {
  final contest = PublishedContest.fromDto(
    PublicPublicationDto.fromJson(fakePublicationJson()),
    now: () => DateTime.utc(2026, 10, 12),
  );

  test('rounds come from the standings and the latest is the default', () {
    expect(contest.rounds, [1, 2, 3]);
    expect(contest.latestRound, 3);
    expect(contest.rowsAsOf(9), isEmpty);
  });

  test('status derives from the end date until the projection carries it', () {
    expect(contest.header.isCompleted, isTrue);
    final running = PublishedContest.fromDto(
      PublicPublicationDto.fromJson(fakePublicationJson()),
      now: () => DateTime.utc(2026, 10, 10, 15),
    );
    expect(running.header.status, 'In progress');
    final stated = PublishedContest.fromDto(
      PublicPublicationDto.fromJson(
        fakePublicationJson(contestStatus: 'Running'),
      ),
      now: () => DateTime.utc(2027),
    );
    expect(stated.header.status, 'In progress');
  });

  test('as of round 2 nothing is dropped and ties sort by last name', () {
    final rows = contest.rowsAsOf(2);
    expect(rows.map((r) => r.lastName), ['Smith', 'Adams', 'Baker', 'Waters']);
    expect(rows.map((r) => r.place), [1, 2, 2, 4]);
    expect(rows[1].isTied, isTrue);
    expect(rows[3].droppedRounds, isEmpty);
    expect(rows[3].roundScores, {1: 900, 2: 990});
    expect(rows[3].percentOfWinner, closeTo(94.5, 0.01));
  });

  test('as of round 3 the dropped round and penalty show', () {
    final rows = contest.rowsAsOf(3);
    expect(rows.map((r) => r.lastName), ['Smith', 'Baker', 'Waters', 'Adams']);
    final waters = rows[2];
    expect(waters.droppedRounds, {1});
    expect(waters.roundScores, {1: 900, 2: 990, 3: 990});
    expect(waters.penaltyTotal, 50);
    expect(waters.rawTotal, 2030);
  });

  testWidgets('the table marks ties and strikes through dropped rounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OverallResultsTable(rows: contest.rowsAsOf(3), round: 3),
        ),
      ),
    );
    expect(find.text('Round 3'), findsOneWidget);
    expect(find.text('Round 4'), findsNothing);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('66%'), findsOneWidget);
    final dropped = tester.widget<Text>(find.text('900'));
    expect(dropped.style?.decoration, TextDecoration.lineThrough);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OverallResultsTable(rows: contest.rowsAsOf(2), round: 2),
        ),
      ),
    );
    expect(find.text('Round 3'), findsNothing);
    expect(find.text('2${OverallResultsTable.tieIndicator}'), findsNWidgets(2));
    final kept = tester.widget<Text>(find.text('900'));
    expect(kept.style?.decoration, isNull);
  });
}
