import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scoring_test_support.dart';

Finder _menu(int round, int pilot) =>
    find.byKey(ValueKey('row-menu-${scoringAssignmentId(round, pilot).value}'));

Future<void> _openMenuItem(
  WidgetTester tester,
  int round,
  int pilot,
  String key,
) async {
  await tester.tap(_menu(round, pilot));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the dialog names what changes in the round counts', (
    tester,
  ) async {
    await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);

    await _openMenuItem(tester, 1, 2, 'menu-retire');

    expect(find.text('Retire Bo Ray?'), findsOneWidget);
    expect(find.text('Round 1 counts 3 flights instead of 4.'), findsOneWidget);
    expect(find.text('Round 2 counts 3 flights instead of 4.'), findsOneWidget);
    expect(find.textContaining('already entered'), findsNothing);
  });

  testWidgets('retiring sends the round, keeps the class and marks the row', (
    tester,
  ) async {
    final server = ScoringServer();
    await pumpScoringPage(tester, server, round: 1, group: 1);
    expect(find.text('0 of 2 entered · 0 official'), findsOneWidget);

    await _openMenuItem(tester, 1, 2, 'menu-retire');
    await tester.tap(find.byKey(const ValueKey('retire-confirm')));
    await tester.pumpAndSettle();

    final update = server.matrixServer.participationUpdates.single;
    expect(update['pilot'], 2);
    expect((update['body'] as Map)['retired_at_round'], 1);
    expect((update['body'] as Map)['base_revision'], 0);
    // The retired flight is shown as retired and is not missing.
    expect(find.text('Retired'), findsOneWidget);
    expect(find.text('Retired from round 1'), findsOneWidget);
    expect(find.text('0 of 1 entered · 0 official'), findsOneWidget);
    expect(find.text('Bo Ray retired from round 1.'), findsOneWidget);
  });

  testWidgets('a retired flight is not asked about in Score check', (
    tester,
  ) async {
    final server = ScoringServer();
    server.matrixServer.retirements[2] = 1;
    server.seedScore(scoringAssignmentId(1, 1), {
      'time_flown': 540,
      'launch_height': 200,
    });
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await tester.tap(find.byKey(const ValueKey('score-check')));
    await tester.pumpAndSettle();

    expect(find.text('1 of 1 entered · 1 official'), findsOneWidget);
    expect(find.textContaining('Bo Ray'), findsOneWidget); // The row only.
  });

  testWidgets('a retired pilot cannot be scored but a score still counts', (
    tester,
  ) async {
    final server = ScoringServer();
    server.matrixServer.retirements[1] = 2;
    server.matrixServer.retirements[2] = 1;
    server.seedScore(scoringAssignmentId(1, 2), {
      'time_flown': 480,
      'launch_height': 150,
    });
    await pumpScoringPage(tester, server, round: 1, group: 1);

    // Bo has a score from before the retirement: it stays official.
    expect(find.text('Official'), findsOneWidget);
    expect(find.text('Retired from round 1'), findsOneWidget);
    expect(find.text('1 of 2 entered · 1 official'), findsOneWidget);
    // Ann flies round 1; she retired at round 2, so round 2 shows her retired.
    await tester.tap(find.byKey(const ValueKey('round-next')));
    await tester.pumpAndSettle();
    expect(find.text('Retired'), findsOneWidget);
    final time = find.byKey(
      ValueKey('score-time-${scoringAssignmentId(2, 1).value}'),
    );
    expect(tester.widget<TextField>(time).enabled, isFalse);
  });

  testWidgets('the dialog says which scores stay', (tester) async {
    final server = ScoringServer();
    server.seedScore(scoringAssignmentId(2, 1), {
      'time_flown': 480,
      'launch_height': 150,
    });
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await _openMenuItem(tester, 1, 1, 'menu-retire');

    expect(find.text('Round 1 counts 3 flights instead of 4.'), findsOneWidget);
    expect(find.text('Round 2 counts 4 flights instead of 4.'), findsNothing);
    expect(
      find.text(
        '1 score already entered from round 1 on stays and still counts.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a pending submission counts, as the server counts it', (
    tester,
  ) async {
    final server = ScoringServer();
    server.seedPendingSubmission(scoringAssignmentId(1, 2), {
      'time_flown': 480,
      'launch_height': 150,
    });
    server.seedPendingSubmission(scoringAssignmentId(2, 2), {
      'time_flown': 470,
      'launch_height': 150,
    });
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await _openMenuItem(tester, 1, 2, 'menu-retire');

    // Round 1 and round 2 both keep Bo's slot in their count.
    expect(find.text('No round count changes.'), findsOneWidget);
    expect(
      find.text(
        '2 scores already entered from round 1 on stay and still count.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a pending submission on a retired pilot is not missing', (
    tester,
  ) async {
    final server = ScoringServer();
    server.matrixServer.retirements[2] = 1;
    server.seedPendingSubmission(scoringAssignmentId(1, 2), {
      'time_flown': 480,
      'launch_height': 150,
    });
    await pumpScoringPage(tester, server, round: 1, group: 1);

    // The submission still waits for a decision, so it is not "Retired".
    // The pilot's values fill the form, so the status reads Unsaved and the
    // Pilot entry indicator marks where they came from.
    expect(find.text('Pilot entry'), findsOneWidget);
    expect(find.text('Retired'), findsNothing);
  });

  testWidgets('a failed recalculation shows the stale-results notice', (
    tester,
  ) async {
    final server = ScoringServer();
    server.matrixServer.participationWarning =
        'Recalculation failed; the results are stale';
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await _openMenuItem(tester, 1, 2, 'menu-retire');
    await tester.tap(find.byKey(const ValueKey('retire-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Retired'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('scoring-recalculation-warning')),
      findsOneWidget,
    );
    expect(
      find.text('Recalculation failed; the results are stale'),
      findsOneWidget,
    );
  });

  testWidgets('reinstating clears the retirement', (tester) async {
    final server = ScoringServer();
    server.matrixServer.retirements[2] = 1;
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await _openMenuItem(tester, 1, 2, 'menu-reinstate');
    expect(find.text('Reinstate Bo Ray?'), findsOneWidget);
    expect(find.text('Round 1 counts 4 flights instead of 3.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('retire-confirm')));
    await tester.pumpAndSettle();

    final update = server.matrixServer.participationUpdates.single;
    expect((update['body'] as Map)['retired_at_round'], isNull);
    expect(find.text('Retired'), findsNothing);
    expect(find.text('0 of 2 entered · 0 official'), findsOneWidget);
  });

  testWidgets('Cancel changes nothing', (tester) async {
    final server = ScoringServer();
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await _openMenuItem(tester, 1, 2, 'menu-retire');
    await tester.tap(find.byKey(const ValueKey('retire-cancel')));
    await tester.pumpAndSettle();

    expect(server.matrixServer.participationUpdates, isEmpty);
    expect(find.text('Retired'), findsNothing);
  });

  testWidgets('a refused change stays in the dialog with the reason', (
    tester,
  ) async {
    final server = ScoringServer();
    server.matrixServer.participationStatus = 409;
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await _openMenuItem(tester, 1, 2, 'menu-retire');
    await tester.tap(find.byKey(const ValueKey('retire-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('The change was rejected.'), findsOneWidget);
    expect(find.byKey(const ValueKey('retire-dialog')), findsOneWidget);
    expect(find.text('Retired'), findsNothing);
  });
}
