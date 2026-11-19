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

  test('the medium table follows the design (700 px sheet)', () {
    expect(ScoreGridMode.mediumMin, 700);
    expect(ScoreGridColumns.mediumLane, 44);
    expect(ScoreGridColumns.mediumTime, 120);
    expect(ScoreGridColumns.mediumHeight, 104);
    expect(ScoreGridColumns.mediumLand, 136);
    expect(ScoreGridColumns.mediumMenu, 44);
    // The left block must stay wider than its three score columns need.
    const right =
        ScoreGridColumns.mediumTime +
        ScoreGridColumns.mediumHeight +
        ScoreGridColumns.mediumLand +
        ScoreGridColumns.mediumMenu +
        ScoreGridColumns.gap * 4;
    const left =
        ScoreGridMode.mediumMin -
        ScoreGridColumns.rowPadding * 2 -
        ScoreGridColumns.mediumLane -
        ScoreGridColumns.gap -
        right;
    expect(left, greaterThan(180));
  });

  test('a width picks wide, medium or compact', () {
    expect(ScoreGridMode.of(1200), ScoreGridMode.wide);
    expect(ScoreGridMode.of(900), ScoreGridMode.medium);
    expect(ScoreGridMode.of(699), ScoreGridMode.compact);
  });
}
