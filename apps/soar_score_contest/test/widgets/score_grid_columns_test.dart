import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/scoring/score_grid_columns.dart';

void main() {
  test('the wide table keeps the pilot column at its least width', () {
    // The wide mode starts at a width where every column, the lane or number
    // column included, fits with the pilot column at 150 px or more.
    expect(
      ScoreGridColumns.wideNeeds,
      lessThanOrEqualTo(ScoreGridMode.wideMin),
    );
    expect(
      ScoreGridMode.wideMin - ScoreGridColumns.wideNeeds,
      lessThan(40),
      reason: 'the wide mode should not start much later than it needs to',
    );
  });

  test('the columns follow the scoring design', () {
    expect(ScoreGridColumns.time, 116);
    expect(ScoreGridColumns.height, 96);
    expect(ScoreGridColumns.land, 120);
    expect(ScoreGridColumns.pilotMin, 150);
  });

  test('the medium table follows the design at 700 px and up', () {
    expect(ScoreGridMode.mediumDesign, 700);
    expect(MediumColumns.lane, 44);
    expect(MediumColumns.menu, 44);
    for (final width in [700.0, 900.0, 1100.0]) {
      final columns = MediumColumns.of(width);
      expect(columns.time, 120);
      expect(columns.height, 104);
      expect(columns.land, 136);
    }
  });

  test('the medium columns give up width down to a portrait tablet', () {
    // 768 px less the 72 px rail, its 1 px divider and 32 px of padding.
    const portraitTablet = 768.0 - 72 - 1 - 32;
    expect(ScoreGridMode.of(portraitTablet), ScoreGridMode.medium);
    final least = MediumColumns.of(ScoreGridMode.mediumMin);
    expect(least.time, 108);
    expect(least.height, 92);
    expect(least.land, 124);
    final between = MediumColumns.of(680);
    expect(between.time, inExclusiveRange(108, 120));
    // What is left for the three score columns at the narrowest width.
    final left =
        ScoreGridMode.mediumMin -
        ScoreGridColumns.rowPadding * 2 -
        MediumColumns.lane -
        ScoreGridColumns.gap -
        least.right -
        ScoreGridColumns.gap;
    expect((left - ScoreGridColumns.gap * 2) / 3, greaterThan(60));
  });

  test('a width picks wide, medium or compact', () {
    expect(ScoreGridMode.of(1200), ScoreGridMode.wide);
    expect(ScoreGridMode.of(900), ScoreGridMode.medium);
    expect(ScoreGridMode.of(659), ScoreGridMode.compact);
  });
}
