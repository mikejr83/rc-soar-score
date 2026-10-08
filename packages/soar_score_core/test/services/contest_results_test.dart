import 'package:soar_score_core/services/services.dart';
import 'package:test/test.dart';

void main() {
  group('ContestResults', () {
    test('an empty result is not preliminary', () {
      expect(ContestResults().isPreliminary, isFalse);
    });

    test('a stale result is preliminary', () {
      expect(ContestResults(isStale: true).isPreliminary, isTrue);
    });

    test('survives a JSON round trip with its flags', () {
      final results = ContestResults(asOfRound: 2, isStale: true);

      final json = results.toJson();

      expect(json['as_of_round'], 2);
      expect(json['stale'], isTrue);
      expect(json['preliminary'], isTrue);
      expect(ContestResults.fromJson(json), results);
    });
  });

  group('RoundResults', () {
    test('survives a JSON round trip', () {
      final results = RoundResults(ordinal: 1, isStale: false, flights: []);

      expect(RoundResults.fromJson(results.toJson()), results);
    });

    test('a stale round is preliminary', () {
      expect(
        RoundResults(ordinal: 1, isStale: true, flights: []).isPreliminary,
        isTrue,
      );
    });
  });
}
