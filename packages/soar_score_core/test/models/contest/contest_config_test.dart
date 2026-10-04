import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('ContestConfig', () {
    test('round trips exactly as written', () {
      final config = makeConfig();
      final json = config.toJson();
      expect(json.keys, ['core', 'discipline']);
      expect(ContestConfig.fromJson(json), config);
    });

    test('rejects a missing part and makes the maps read-only', () {
      expect(() => ContestConfig.fromJson({'core': {}}), throwsFormatException);
      expect(
        () => ContestConfig.fromJson({'core': 1, 'discipline': {}}),
        throwsFormatException,
      );
      expect(() => makeConfig().core['x'] = 1, throwsUnsupportedError);
    });

    test('resolves core options with platform defaults', () {
      final options = makeConfig().coreOptions;
      expect(options.teamsEnabled, isTrue);
      expect(options.teamPilotCount, 2);
      expect(options.groupScoreMode, GroupScoreMode.time);
      expect(options.dropAfterRounds, [4]);
      expect(options.roundingMode, RoundingMode.round);
      expect(options.decimalPlaces, 1);
      expect(options.reviewRequestsEnabled, isTrue);
      expect(options.publicUpdateMode, PublicUpdateMode.roundCompletion);
    });
  });
}
