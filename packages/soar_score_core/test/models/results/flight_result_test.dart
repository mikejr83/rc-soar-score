import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

FlightResult make({
  double raw = 625,
  double? landing = 40,
  double? penalty,
  int? cumulative,
  double group = 1040,
  String version = '1.0.0',
  FlightOutcome outcome = FlightOutcome.scored,
}) => FlightResult(
  id: exampleId(1),
  contestId: exampleId(2),
  scorePlaceholderId: exampleId(3),
  officialScoreId: exampleId(4),
  contestParticipationId: exampleId(5),
  creditedRoundId: exampleId(6),
  outcome: outcome,
  rawPoints: raw,
  landingPoints: landing,
  flightPenaltyPoints: penalty,
  cumulativePenalty: cumulative,
  groupScore: group,
  isPreliminary: false,
  configRevisionId: exampleId(7),
  matrixRevisionId: exampleId(8),
  calculationVersion: version,
  computedAt: t0,
);

void main() {
  group('FlightResult', () {
    test('round trips and is derived data', () {
      final r = make();
      expect(r.isSelected, isTrue);
      expect(r.toJson()['outcome'], 'Scored');
      expect(r.toJson().containsKey('revision'), isFalse);
      expect(FlightResult.fromJson(r.toJson()), r);
      expect(r.syncScope, SyncScope.derived);
    });

    test('reads whole numbers as scores', () {
      final json = make().toJson()
        ..['raw_points'] = 625
        ..['group_score'] = 1040;
      final r = FlightResult.fromJson(json);
      expect(r.rawPoints, 625.0);
      expect(r.groupScore, 1040.0);
    });

    test('a zero outcome uses the documented text', () {
      final r = make(outcome: FlightOutcome.zero, raw: 0, group: 0);
      expect(r.toJson()['outcome'], 'Zero');
    });

    test('points and penalties are never negative', () {
      expect(() => make(raw: -1), throwsArgumentError);
      expect(() => make(landing: -1), throwsArgumentError);
      expect(() => make(penalty: -1), throwsArgumentError);
      expect(() => make(cumulative: -1), throwsArgumentError);
      expect(() => make(group: -0.5), throwsArgumentError);
      expect(() => make(raw: double.nan), throwsArgumentError);
    });

    test('a zero cumulative penalty is kept, a missing one stays null', () {
      expect(make(cumulative: 0).toJson()['cumulative_penalty'], 0);
      expect(make().toJson()['cumulative_penalty'], isNull);
    });

    test('needs a calculation version', () {
      expect(() => make(version: ' '), throwsArgumentError);
    });

    test('is stale when any version stamp differs', () {
      final r = make();
      bool stale({Id? config, Id? matrix, String? version}) => r.isStale(
        currentConfigRevisionId: config ?? exampleId(7),
        currentMatrixRevisionId: matrix ?? exampleId(8),
        currentCalculationVersion: version ?? '1.0.0',
      );
      expect(stale(), isFalse);
      expect(stale(config: exampleId(9)), isTrue);
      expect(stale(matrix: exampleId(9)), isTrue);
      expect(stale(version: '1.1.0'), isTrue);
    });
  });
}
