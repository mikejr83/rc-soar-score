import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/matrix/fairness_view.dart';

void main() {
  test('reads the stored fairness report', () {
    final view = FairnessView.of({
      'fairness_score': 92.4,
      'unmet_opponent_count': 3,
      'max_duplicate_matchups': 2,
      'mean_absolute_deviation': 0.5,
      'feasible_pairs': 190,
      'lane_uniformity_index': 0.8,
      'matchup_histogram': {'0': 3, '1': 120, '2': 60, '3': 5, '4': 2},
    });
    expect(view.scoreText, '92.4%');
    expect(view.tier, FairnessTier.good);
    expect(view.unmet, 3);
    expect(view.bars, [
      ('Never', 3),
      ('Once', 120),
      ('Twice', 60),
      ('3+ times', 7),
    ]);
  });

  test('tiers follow the score', () {
    FairnessTier? tier(num score) =>
        FairnessView.of({'fairness_score': score}).tier;
    expect(tier(0), FairnessTier.poor);
    expect(tier(24.9), FairnessTier.poor);
    expect(tier(41), FairnessTier.average);
    expect(tier(75), FairnessTier.good);
    expect(tier(100), FairnessTier.good);
  });

  test('whole scores have no decimals', () {
    expect(FairnessView.of({'fairness_score': 92.0}).scoreText, '92%');
  });

  test('a missing report reads as unknown, not as zero', () {
    final view = FairnessView.of(null);
    expect(view.scoreText, '–');
    expect(view.tier, isNull);
    expect(view.bars.every((bar) => bar.$2 == 0), isTrue);
  });
}
