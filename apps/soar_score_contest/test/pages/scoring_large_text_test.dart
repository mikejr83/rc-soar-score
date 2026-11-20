import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scoring_test_support.dart';

const _flight = {'time_flown': 540, 'launch_height': 120};

/// Extra large text (1.5 times) in the wide grid: a label that no longer fits
/// its column wraps and its chip or button grows, instead of cutting it off.
/// (The test font is wider than the real one, so these checks hold the
/// no-clipping rule, not the exact widths.)
/// Whether every line of the text lies inside the box the text was given: a
/// label that is cut off lays out wider or taller than its box. A wrapped
/// line's selection box can run a few pixels past the box (its trailing
/// space), hence the margin on the width.
bool _textFits(WidgetTester tester, Finder text) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: text, matching: find.byType(RichText)).first,
  );
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(
      baseOffset: 0,
      extentOffset: paragraph.text.toPlainText().length,
    ),
  );
  return boxes.every(
    (box) =>
        box.right <= paragraph.size.width + 6 &&
        box.bottom <= paragraph.size.height + 0.5,
  );
}

void main() {
  final first = scoringAssignmentId(1, 1);

  Future<void> pump(WidgetTester tester, double scale) async {
    final server = ScoringServer()..seedPendingSubmission(first, _flight);
    await pumpScoringPage(
      tester,
      server,
      size: const Size(1600, 1400),
      round: 1,
      group: 1,
      textScale: scale,
    );
  }

  testWidgets('the Pilot entry badge shows all of its text at Extra large', (
    tester,
  ) async {
    await pump(tester, 1.5);
    expect(tester.takeException(), isNull);
    final chip = tester.getRect(
      find.byKey(ValueKey('score-indicator-pilot-entry-${first.value}')),
    );
    expect(_textFits(tester, find.text('Pilot entry')), isTrue);
    // The column is narrower than the label, so the badge wrapped and grew.
    expect(chip.height, greaterThan(22));
  });

  testWidgets('Mark official grows with its label at Extra large', (
    tester,
  ) async {
    await pump(tester, 1.5);
    expect(tester.takeException(), isNull);
    final button = tester.getRect(
      find.widgetWithText(TextButton, 'Mark official'),
    );
    expect(button.height, greaterThanOrEqualTo(32));
    expect(_textFits(tester, find.text('Mark official')), isTrue);

    await tester.tap(find.text('Mark official'));
    await tester.pumpAndSettle();
    expect(find.text('Mark official'), findsNothing);
    expect(find.text('Official'), findsOneWidget);
  });
}
