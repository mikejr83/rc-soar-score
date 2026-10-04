import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

Round makeRound({
  int ordinal = 1,
  int groups = 2,
  RoundStatus status = RoundStatus.open,
  Id? superseded,
}) => Round(
  id: exampleId(1),
  contestId: exampleId(2),
  matrixRevisionId: exampleId(3),
  ordinal: ordinal,
  groupCount: groups,
  status: status,
  supersededByRoundId: superseded,
);

RoundGroup makeGroup({
  GroupStatus status = GroupStatus.open,
  Id? by,
  DateTime? at,
}) => RoundGroup(
  id: exampleId(4),
  contestId: exampleId(2),
  roundId: exampleId(1),
  groupNumber: 1,
  status: status,
  lockedBy: by,
  lockedAt: at,
);

void main() {
  group('Round', () {
    test('round trips with status text and defaults', () {
      final r = makeRound();
      expect(r.status, RoundStatus.open);
      expect(r.revision, 0);
      expect(r.toJson()['status'], 'Open');
      expect(Round.fromJson(r.toJson()), r);
      expect(r.syncScope, SyncScope.contest);
    });

    test('ordinal and group count start at 1', () {
      expect(() => makeRound(ordinal: 0), throwsArgumentError);
      expect(() => makeRound(groups: 0), throwsArgumentError);
    });

    test('is current unless superseded or cancelled', () {
      expect(makeRound().isCurrent, isTrue);
      expect(makeRound(superseded: exampleId(9)).isCurrent, isFalse);
      expect(makeRound(status: RoundStatus.cancelled).isCurrent, isFalse);
      expect(makeRound(status: RoundStatus.locked).isCurrent, isTrue);
    });

    test('cannot supersede itself', () {
      expect(() => makeRound(superseded: exampleId(1)), throwsArgumentError);
    });
  });

  group('RoundGroup', () {
    test('round trips open and locked', () {
      final open = makeGroup();
      expect(RoundGroup.fromJson(open.toJson()), open);
      final locked = makeGroup(
        status: GroupStatus.locked,
        by: exampleId(5),
        at: t0,
      );
      expect(locked.toJson()['status'], 'Locked');
      expect(locked.isLocked, isTrue);
      expect(RoundGroup.fromJson(locked.toJson()), locked);
    });

    test('lock fields are set exactly when locked', () {
      expect(() => makeGroup(status: GroupStatus.locked), throwsArgumentError);
      expect(() => makeGroup(by: exampleId(5), at: t0), throwsArgumentError);
      expect(
        () => makeGroup(status: GroupStatus.locked, by: exampleId(5)),
        throwsArgumentError,
      );
    });
  });
}
