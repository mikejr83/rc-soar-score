import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scoring_test_support.dart';

const _flight = {'time_flown': 540, 'launch_height': 120};

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  testWidgets('Mark official on a row accepts the pilot entry', (tester) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedPendingSubmission(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    expect(find.text('Pilot entry'), findsOneWidget);
    // Only the row with a waiting entry offers it.
    expect(find.text('Mark official'), findsOneWidget);
    await tester.tap(_key('score-mark-official-${first.value}'));
    await tester.pumpAndSettle();

    expect(server.promoteRequests, 1);
    expect(server.entries, isEmpty);
    expect(find.text('Pilot entry'), findsNothing);
    expect(find.text('Mark official'), findsNothing);
  });

  testWidgets('a row with typed edits says to save or revert first', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedPendingSubmission(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await tester.tap(_key('score-row-${first.value}'));
    await tester.pumpAndSettle();
    await tester.enterText(_key('score-height-${first.value}'), '99');
    await tester.pumpAndSettle();

    final button = tester.widget<OutlinedButton>(
      _key('score-mark-official-${first.value}'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Save or revert your edits first.'), findsOneWidget);
  });

  testWidgets('a busy server shows Retry, which asks again', (tester) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedPendingSubmission(first, _flight);
    server.promoteFailures[first] = (503, 'service_busy');
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await tester.tap(_key('score-mark-official-${first.value}'));
    await tester.pumpAndSettle();
    expect(_key('score-mark-official-failed'), findsOneWidget);
    expect(find.textContaining('try again'), findsOneWidget);

    server.promoteFailures.clear();
    await tester.tap(_key('score-retry'));
    await tester.pumpAndSettle();

    expect(server.entries, isEmpty);
    expect(_key('score-mark-official-failed'), findsNothing);
    expect(find.text('Pilot entry'), findsNothing);
  });

  testWidgets('no waiting entry, no Mark all', (tester) async {
    final server = ScoringServer();
    await pumpScoringPage(tester, server, round: 1, group: 1);
    expect(find.text('Mark official'), findsNothing);
  });
}
