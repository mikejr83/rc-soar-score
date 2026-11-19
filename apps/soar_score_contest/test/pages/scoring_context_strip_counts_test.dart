import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scoring_test_support.dart';

const _flight = {'time_flown': 540, 'launch_height': 120};

void main() {
  testWidgets('the strip counts pending submissions as entered, not official', (
    tester,
  ) async {
    final server = ScoringServer()
      ..seedScore(scoringAssignmentId(1, 1), _flight)
      ..seedPendingSubmission(scoringAssignmentId(1, 2), _flight)
      ..seedPendingSubmission(
        scoringAssignmentId(1, 3),
        _flight,
        inReview: true,
      );
    await pumpScoringPage(tester, server, round: 1, group: 1);

    final strip = find.byKey(const ValueKey('scoring-context-strip'));
    expect(
      find.descendant(
        of: strip,
        matching: find.textContaining(RegExp(r'^2 of 2 entered · 1 official$')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: strip,
        matching: find.textContaining('Round in progress'),
      ),
      findsOneWidget,
    );
  });
}
