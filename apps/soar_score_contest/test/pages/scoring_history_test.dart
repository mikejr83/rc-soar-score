import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scoring_test_support.dart';

const _first = {'time_flown': 540, 'launch_height': 200};

Finder _menu(int round, int pilot) =>
    find.byKey(ValueKey('row-menu-${scoringAssignmentId(round, pilot).value}'));

Future<void> _openHistory(WidgetTester tester, int round, int pilot) async {
  await tester.tap(_menu(round, pilot));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('menu-history')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows every revision with its reason, newest first', (
    tester,
  ) async {
    final server = ScoringServer();
    final slot = scoringAssignmentId(1, 1);
    server.seedScore(slot, _first);
    server.seedCorrection(slot, {
      'time_flown': 500,
      'launch_height': 200,
      'late_landing': true,
    }, 'Timer misread');
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await _openHistory(tester, 1, 1);

    expect(find.text('Score history · Ann Lee'), findsOneWidget);
    expect(find.text('Revision 2'), findsOneWidget);
    expect(find.text('Revision 1'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Replaced'), findsOneWidget);
    expect(find.text('Reason: Timer misread'), findsOneWidget);
    expect(find.text('Reason: seeded'), findsOneWidget);
    expect(find.text('8:20 · 200 m · Late landing'), findsOneWidget);
    expect(find.text('9:00 · 200 m'), findsOneWidget);
    // Newest first: revision 2 sits above revision 1.
    expect(
      tester.getTopLeft(find.text('Revision 2')).dy,
      lessThan(tester.getTopLeft(find.text('Revision 1')).dy),
    );
    // Times are in the contest zone.
    expect(find.textContaining('America/Denver'), findsOneWidget);
    expect(find.textContaining('Director · Sat Oct 17'), findsWidgets);
  });

  testWidgets('lists a submission that lost to the official score', (
    tester,
  ) async {
    final server = ScoringServer();
    final slot = scoringAssignmentId(1, 1);
    server.seedScore(slot, _first);
    server.seedLostSubmission(slot, {'time_flown': 600, 'launch_height': 120});
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await _openHistory(tester, 1, 1);

    expect(find.text('Not adopted'), findsOneWidget);
    expect(find.text('Submission'), findsOneWidget);
    expect(find.text('10:00 · 120 m'), findsOneWidget);
    expect(find.text('Participant'), findsOneWidget);
  });

  testWidgets('a submission awaiting the director is pending, not lost', (
    tester,
  ) async {
    final server = ScoringServer();
    server.seedPendingSubmission(scoringAssignmentId(1, 1), {
      'time_flown': 600,
      'launch_height': 120,
    });
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await _openHistory(tester, 1, 1);

    expect(find.text('Awaiting decision'), findsOneWidget);
    expect(find.text('Not adopted'), findsNothing);
  });

  testWidgets('a waiting submission fills the form, not the row text', (
    tester,
  ) async {
    final server = ScoringServer();
    final slot = scoringAssignmentId(1, 1);
    server.seedPendingSubmission(slot, {
      'time_flown': 600,
      'launch_height': 120,
    });
    await pumpScoringPage(tester, server, round: 1, group: 1);

    // The pilot entry is marked by the chip alone; the values show in the
    // form, not as text on the row.
    expect(find.text('Pilot entry'), findsOneWidget);
    expect(find.text('time flown: 600, launch height: 120'), findsNothing);
    final slotValue = slot.value;
    expect(
      tester.widget<TextField>(
        find.byKey(ValueKey('score-time-$slotValue')),
      ).controller!.text,
      '10:00',
    );
    expect(
      tester.widget<TextField>(
        find.byKey(ValueKey('score-height-$slotValue')),
      ).controller!.text,
      '120',
    );
  });

  testWidgets('a submission in review fills the form too', (tester) async {
    final server = ScoringServer();
    final slot = scoringAssignmentId(1, 1);
    server.seedPendingSubmission(
      slot,
      {'time_flown': 600, 'launch_height': 120},
      inReview: true,
    );
    await pumpScoringPage(tester, server, round: 1, group: 1);

    expect(find.text('Pilot entry'), findsOneWidget);
    expect(find.text('time flown: 600, launch height: 120'), findsNothing);
    expect(
      tester.widget<TextField>(
        find.byKey(ValueKey('score-time-${slot.value}')),
      ).controller!.text,
      '10:00',
    );
    expect(
      tester.widget<TextField>(
        find.byKey(ValueKey('score-height-${slot.value}')),
      ).controller!.text,
      '120',
    );
  });

  testWidgets('an official score hides the pilot values', (tester) async {
    final server = ScoringServer();
    server.seedPendingSubmission(scoringAssignmentId(1, 1), {
      'time_flown': 600,
      'launch_height': 120,
    });
    server.seedScore(scoringAssignmentId(1, 1), {
      'time_flown': 590,
      'launch_height': 110,
    });
    await pumpScoringPage(tester, server, round: 1, group: 1);

    expect(find.text('Pilot entry'), findsNothing);
    expect(find.text('time flown: 600, launch height: 120'), findsNothing);
  });

  testWidgets('says so when nothing was entered', (tester) async {
    await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);

    await _openHistory(tester, 1, 1);

    expect(find.byKey(const ValueKey('score-history-empty')), findsOneWidget);
  });

  testWidgets('shows why the history could not be read', (tester) async {
    final server = ScoringServer()..historyStatus = 403;
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await _openHistory(tester, 1, 1);

    expect(find.text('No history for you.'), findsOneWidget);
  });

  testWidgets('Close leaves the dialog', (tester) async {
    await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
    await _openHistory(tester, 1, 1);

    await tester.tap(find.byKey(const ValueKey('score-history-close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('score-history-dialog')), findsNothing);
  });

  testWidgets('the group history lists each pilot with changes', (
    tester,
  ) async {
    final server = ScoringServer();
    final ann = scoringAssignmentId(1, 1);
    server.seedScore(ann, _first);
    server.seedCorrection(ann, {
      'time_flown': 500,
      'launch_height': 200,
    }, 'Timer misread');
    server.seedScore(scoringAssignmentId(1, 2), {
      'time_flown': 480,
      'launch_height': 150,
    });
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await tester.tap(find.byKey(const ValueKey('group-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-group-history')));
    await tester.pumpAndSettle();

    expect(find.text('Group history'), findsOneWidget);
    final dialog = find.byKey(const ValueKey('score-history-dialog'));
    expect(
      find.descendant(of: dialog, matching: find.text('Ann Lee')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text('Bo Ray')),
      findsOneWidget,
    );
    expect(find.text('Revision 2'), findsOneWidget);
    expect(find.text('Revision 1'), findsNWidgets(2));
    expect(find.text('Reason: Timer misread'), findsOneWidget);
  });
}
