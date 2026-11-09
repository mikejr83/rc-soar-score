import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

ScoreAttempt make({
  Map<String, Object?> raw = const {'time_flown': 585},
  Authority authority = Authority.director,
  String mutationId = '01J9ZM5B2E4G6H8K0N2Q4S6U8W',
  int base = 0,
}) => ScoreAttempt(
  id: exampleId(1),
  contestId: exampleId(2),
  scorePlaceholderId: exampleId(3),
  configRevisionId: exampleId(4),
  matrixRevisionId: exampleId(5),
  rawComponents: raw,
  actorId: exampleId(6),
  authority: authority,
  clientMutationId: mutationId,
  baseScoreRevision: base,
  acceptedAt: DateTime.utc(2026, 10, 17, 15, 10),
);

void main() {
  group('ScoreAttempt', () {
    test('round trips and is contest data without a row revision', () {
      final a = make();
      final json = a.toJson();
      expect(json['authority'], 'Director');
      expect(json.containsKey('revision'), isFalse);
      expect(ScoreAttempt.fromJson(json), a);
      expect(a.syncScope, SyncScope.contest);
    });

    test('copies the components so later edits do not leak in', () {
      final raw = <String, Object?>{'time_flown': 1};
      final a = make(raw: raw);
      raw['time_flown'] = 2;
      expect(a.rawComponents['time_flown'], 1);
    });

    test('needs a mutation id and a non-negative base revision', () {
      expect(() => make(mutationId: ' '), throwsArgumentError);
      expect(() => make(base: -1), throwsArgumentError);
    });

    test('flight penalty is a non-negative integer or null', () {
      expect(make(raw: const {'flight_penalty': null}).baseScoreRevision, 0);
      expect(make(raw: const {'flight_penalty': 20}).baseScoreRevision, 0);
      expect(
        () => make(raw: const {'flight_penalty': -1}),
        throwsArgumentError,
      );
      expect(
        () => make(raw: const {'flight_penalty': 'a lot'}),
        throwsArgumentError,
      );
    });

    test('only director authority sets a cumulative penalty', () {
      expect(make(raw: const {'cumulative_penalty': 100}).authority, isNotNull);
      expect(
        () => make(
          raw: const {'cumulative_penalty': 100},
          authority: Authority.participant,
        ),
        throwsArgumentError,
      );
      expect(
        make(
          raw: const {'cumulative_penalty': null},
          authority: Authority.participant,
        ).authority,
        Authority.participant,
      );
    });
  });
}
