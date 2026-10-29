import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

Map<String, Object?> fairness({
  int unmet = 0,
  int maxDuplicate = 1,
  double cost = 10,
}) => {
  'unmet_opponent_count': unmet,
  'max_duplicate_matchups': maxDuplicate,
  'cost': cost,
};

void main() {
  group('RedrawPreview', () {
    test('round trips', () {
      final p = RedrawPreview(
        seed: 7,
        candidateFairness: fairness(unmet: 1),
        currentFairness: fairness(),
      );
      final again = RedrawPreview.fromJson(p.toJson());
      expect(again, p);
      expect(again.seed, 7);
      expect(again.candidateFairness['unmet_opponent_count'], 1);
    });

    test('a response without a better falls back to the comparison', () {
      expect(
        RedrawPreview.fromJson({
          'seed': 1,
          'candidate_fairness': fairness(unmet: 1),
          'current_fairness': fairness(unmet: 2),
        }).better,
        true,
      );
      expect(
        RedrawPreview.fromJson({
          'seed': 1,
          'candidate_fairness': fairness(unmet: 2),
          'current_fairness': fairness(unmet: 1),
        }).better,
        false,
      );
    });

    test('beats on fewer never-met pairs', () {
      expect(
        RedrawPreview(
          seed: 1,
          candidateFairness: fairness(unmet: 1),
          currentFairness: fairness(unmet: 2),
        ).better,
        true,
      );
      expect(
        RedrawPreview(
          seed: 1,
          candidateFairness: fairness(unmet: 2),
          currentFairness: fairness(unmet: 1),
        ).better,
        false,
      );
    });

    test('then on the lower maximum repeat', () {
      expect(
        RedrawPreview(
          seed: 1,
          candidateFairness: fairness(maxDuplicate: 2),
          currentFairness: fairness(maxDuplicate: 3),
        ).better,
        true,
      );
      expect(
        RedrawPreview(
          seed: 1,
          candidateFairness: fairness(maxDuplicate: 3),
          currentFairness: fairness(maxDuplicate: 2),
        ).better,
        false,
      );
    });

    test('then on the lower total cost', () {
      expect(
        RedrawPreview(
          seed: 1,
          candidateFairness: fairness(cost: 9),
          currentFairness: fairness(cost: 10),
        ).better,
        true,
      );
      expect(
        RedrawPreview(
          seed: 1,
          candidateFairness: fairness(cost: 11),
          currentFairness: fairness(cost: 10),
        ).better,
        false,
      );
    });

    test('never wins when the current fairness is missing or a cost is', () {
      expect(
        RedrawPreview(
          seed: 1,
          candidateFairness: fairness(unmet: 0),
        ).better,
        false,
        reason: 'nothing to beat when there is no current fairness',
      );
      expect(
        RedrawPreview(
          seed: 1,
          candidateFairness: fairness(cost: 9),
          currentFairness: {
            'unmet_opponent_count': 0,
            'max_duplicate_matchups': 1,
          },
        ).better,
        false,
        reason: 'a missing cost is not beatable',
      );
    });

    test('an equal fairness is not better', () {
      expect(
        RedrawPreview(
          seed: 1,
          candidateFairness: fairness(),
          currentFairness: fairness(),
        ).better,
        false,
      );
    });

    test('keeps the passed-in maps untouched', () {
      final map = fairness();
      RedrawPreview(seed: 1, candidateFairness: map);
      expect(map['cost'], 10.0);
    });

    test('a given better overrides the comparison', () {
      expect(
        RedrawPreview(
          seed: 1,
          candidateFairness: fairness(unmet: 1),
          currentFairness: fairness(unmet: 2),
          better: false,
        ).better,
        false,
      );
    });
  });
}
