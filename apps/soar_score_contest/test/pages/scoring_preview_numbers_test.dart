import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scoring_test_support.dart';

const _flight = {'time_flown': 540, 'launch_height': 120};

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  testWidgets('a preview score is italic and says it is a preview', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedScore(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await tester.tap(_key('score-row-${first.value}'));
    await tester.pumpAndSettle();
    await tester.enterText(_key('score-time-${first.value}'), '8:30');
    await tester.pumpAndSettle();

    // No caption stands in for the preview; the number carries the meaning.
    expect(find.text('Preview, not saved'), findsNothing);
    expect(
      find.byTooltip('Preview. Saved when you save the row.'),
      findsOneWidget,
    );
    final number = tester.widget<Text>(
      find.descendant(
        of: find.byTooltip('Preview. Saved when you save the row.'),
        matching: find.byType(Text),
      ),
    );
    expect(number.style?.fontStyle, FontStyle.italic);
  });

  testWidgets('a partly entered row says Incomplete under Raw score only', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer();
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await tester.tap(_key('score-row-${first.value}'));
    await tester.pumpAndSettle();
    await tester.enterText(_key('score-time-${first.value}'), '8:30');
    await tester.pumpAndSettle();

    expect(find.text('Incomplete'), findsOneWidget);
  });

  testWidgets('a saved score has no preview marks', (tester) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedScore(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    expect(
      find.byTooltip('Preview. Saved when you save the row.'),
      findsNothing,
    );
    expect(find.text('Incomplete'), findsNothing);
  });
}
