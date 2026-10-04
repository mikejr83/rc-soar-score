import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

ParticipationStanding pilot({
  int round = 1,
  int place = 1,
  double raw = 1045,
  double penalty = 0,
  List<int> dropped = const [],
}) => ParticipationStanding(
  id: exampleId(1),
  contestId: exampleId(2),
  contestParticipationId: exampleId(3),
  asOfRound: round,
  place: place,
  rawTotal: raw,
  droppedRounds: dropped,
  penaltyTotal: penalty,
  overallScore: raw - penalty,
  isPreliminary: false,
  configRevisionId: exampleId(7),
  matrixRevisionId: exampleId(8),
  calculationVersion: '1.0.0',
  computedAt: t0,
);

TeamStanding team({
  int round = 1,
  int place = 1,
  List<Id> counted = const [],
}) => TeamStanding(
  id: exampleId(4),
  contestId: exampleId(2),
  teamId: exampleId(5),
  asOfRound: round,
  place: place,
  teamScore: 2069.4,
  countedParticipations: counted,
  isPreliminary: false,
  configRevisionId: exampleId(7),
  matrixRevisionId: exampleId(8),
  calculationVersion: '1.0.0',
  computedAt: t0,
);

void main() {
  group('ParticipationStanding', () {
    test('round trips with defaults and is derived data', () {
      final s = pilot();
      expect(s.isTied, isFalse);
      expect(s.penaltyTotal, 0);
      expect(s.droppedRounds, isEmpty);
      expect(ParticipationStanding.fromJson(s.toJson()), s);
      expect(s.syncScope, SyncScope.derived);
    });

    test('keeps dropped rounds and reads whole-number scores', () {
      final s = pilot(dropped: [2, 5]);
      final json = s.toJson()
        ..['raw_total'] = 1045
        ..['penalty_total'] = 0;
      expect(ParticipationStanding.fromJson(json).droppedRounds, [2, 5]);
      expect(ParticipationStanding.fromJson(json).rawTotal, 1045.0);
    });

    test('rounds and place start at 1', () {
      expect(() => pilot(round: 0), throwsArgumentError);
      expect(() => pilot(place: 0), throwsArgumentError);
      expect(() => pilot(dropped: [0]), throwsArgumentError);
    });

    test('totals are never negative', () {
      expect(() => pilot(raw: -1), throwsArgumentError);
      expect(() => pilot(penalty: -1), throwsArgumentError);
    });

    test('copies the dropped rounds', () {
      final dropped = [2];
      final s = pilot(dropped: dropped);
      dropped.add(3);
      expect(s.droppedRounds, [2]);
    });

    test('is stale when a version stamp differs', () {
      final s = pilot();
      expect(
        s.isStale(
          currentConfigRevisionId: exampleId(7),
          currentMatrixRevisionId: exampleId(8),
          currentCalculationVersion: '1.0.0',
        ),
        isFalse,
      );
      expect(
        s.isStale(
          currentConfigRevisionId: exampleId(7),
          currentMatrixRevisionId: exampleId(8),
          currentCalculationVersion: '2.0.0',
        ),
        isTrue,
      );
    });
  });

  group('TeamStanding', () {
    test('round trips with the counted pilots in order', () {
      final t = team(counted: [exampleId(10), exampleId(11)]);
      final json = t.toJson();
      expect(json['counted_participations'], [
        exampleId(10).toString(),
        exampleId(11).toString(),
      ]);
      expect(TeamStanding.fromJson(json), t);
      expect(t.syncScope, SyncScope.derived);
    });

    test('a team with fewer pilots counts them all, even none', () {
      expect(team().countedParticipations, isEmpty);
    });

    test('a pilot is counted once', () {
      expect(
        () => team(counted: [exampleId(10), exampleId(10)]),
        throwsArgumentError,
      );
    });

    test('rounds and place start at 1', () {
      expect(() => team(round: 0), throwsArgumentError);
      expect(() => team(place: 0), throwsArgumentError);
    });
  });
}
