import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

ReFlight make({
  ReFlightType type = ReFlightType.reflyEntireGroup,
  ReFlightStatus status = ReFlightStatus.proposed,
  int? requestedSize,
  int? seed,
  Id? groupBy,
  DateTime? groupAt,
  Id? finalBy,
  DateTime? finalAt,
  Id? cancelBy,
  DateTime? cancelAt,
  String? cancelReason,
  String reason = 'Landing area obstructed',
}) => ReFlight(
  id: exampleId(1),
  contestId: exampleId(2),
  creditedRoundId: exampleId(3),
  sourceRoundId: exampleId(3),
  sourceGroup: 1,
  type: type,
  status: status,
  reason: reason,
  scheduledRoundId: exampleId(4),
  flownGroup: 3,
  requestedGroupSize: requestedSize,
  randomSeed: seed,
  configRevisionId: exampleId(5),
  createdBy: exampleId(6),
  createdAt: t0,
  groupFinalizedBy: groupBy,
  groupFinalizedAt: groupAt,
  finalizedBy: finalBy,
  finalizedAt: finalAt,
  cancelledBy: cancelBy,
  cancelledAt: cancelAt,
  cancelReason: cancelReason,
);

void main() {
  group('ReFlight', () {
    test('round trips with defaults', () {
      final r = make();
      expect(r.status, ReFlightStatus.proposed);
      expect(r.sequence, 1);
      expect(r.revision, 0);
      expect(r.deviationAcknowledged, isFalse);
      expect(r.toJson()['type'], 'ReflyEntireGroup');
      expect(r.toJson()['status'], 'Proposed');
      expect(ReFlight.fromJson(r.toJson()), r);
      expect(r.syncScope, SyncScope.contest);
    });

    test('type and status values use their documented text', () {
      expect(
        make(type: ReFlightType.moveToGroup).toJson()['type'],
        'MoveToGroup',
      );
      final r = make(status: ReFlightStatus.awaitingResponses)
          .toJson()['status'];
      expect(r, 'AwaitingResponses');
    });

    test('draw fields belong to a RandomDraw', () {
      expect(() => make(requestedSize: 4), throwsArgumentError);
      expect(() => make(seed: 1), throwsArgumentError);
      final draw = make(
        type: ReFlightType.randomDraw,
        requestedSize: 4,
        seed: 7,
      );
      expect(draw.randomSeed, 7);
      expect(
        () => make(type: ReFlightType.randomDraw, seed: -1),
        throwsArgumentError,
      );
    });

    test('a ready re-flight has its group finalized', () {
      expect(
        () => make(status: ReFlightStatus.readyToFly),
        throwsArgumentError,
      );
      final ok = make(
        status: ReFlightStatus.readyToFly,
        groupBy: exampleId(6),
        groupAt: t0,
      );
      expect(ok.isCancelled, isFalse);
      expect(
        () => make(groupBy: exampleId(6)),
        throwsArgumentError,
        reason: 'by and at are set together',
      );
    });

    test('finalizer fields are set exactly when Finalized', () {
      final ok = make(
        status: ReFlightStatus.finalized,
        groupBy: exampleId(6),
        groupAt: t0,
        finalBy: exampleId(6),
        finalAt: t0,
      );
      expect(ReFlight.fromJson(ok.toJson()), ok);
      expect(
        () => make(finalBy: exampleId(6), finalAt: t0),
        throwsArgumentError,
      );
    });

    test('cancellation fields are set exactly when Cancelled', () {
      final ok = make(
        status: ReFlightStatus.cancelled,
        cancelBy: exampleId(6),
        cancelAt: t0,
        cancelReason: 'Not needed',
      );
      expect(ok.isCancelled, isTrue);
      expect(() => make(status: ReFlightStatus.cancelled), throwsArgumentError);
      expect(() => make(cancelReason: 'x'), throwsArgumentError);
    });

    test('needs a reason and positive group numbers', () {
      expect(() => make(reason: ' '), throwsArgumentError);
    });
  });
}
