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
}
