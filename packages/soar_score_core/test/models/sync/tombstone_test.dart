import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'ids.dart';

Tombstone make({Id? contest, Id? owner}) => Tombstone(
  id: exampleId(0xc5),
  contestId: contest,
  ownerAccountId: owner,
  entityType: 'Contest',
  entityId: exampleId(0x10),
  deletedAt: t0,
);

void main() {
  group('Tombstone', () {
    test('round trips pending and acknowledged', () {
      final pending = make(owner: exampleId(1));
      expect(pending.toJson()['status'], 'Pending');
      expect(Tombstone.fromJson(pending.toJson()), pending);

      final acked = pending.acknowledge(t0.add(const Duration(minutes: 1)));
      expect(acked.toJson()['status'], 'Acknowledged');
      expect(Tombstone.fromJson(acked.toJson()), acked);
    });

    test('acknowledging sets the purge date 90 days later', () {
      final acked = make(owner: exampleId(1)).acknowledge(t0);
      expect(acked.status, TombstoneStatus.acknowledged);
      expect(acked.acknowledgedAt, t0);
      expect(acked.purgeAfter, t0.add(const Duration(days: 90)));
      expect(Tombstone.retention, const Duration(days: 90));
    });

    test('moves from Pending to Acknowledged only once', () {
      final acked = make(owner: exampleId(1)).acknowledge(t0);
      expect(() => acked.acknowledge(t0), throwsStateError);
    });

    test('a pending tombstone has no acknowledgement', () {
      expect(
        () => Tombstone(
          id: exampleId(1),
          ownerAccountId: exampleId(2),
          entityType: 'Contest',
          entityId: exampleId(3),
          deletedAt: t0,
          acknowledgedAt: t0,
        ),
        throwsArgumentError,
      );
    });

    test('needs exactly one of contest and owner', () {
      expect(() => make(), throwsArgumentError);
      expect(
        () => make(contest: exampleId(0x10), owner: exampleId(1)),
        throwsArgumentError,
      );
    });

    test('scope follows the owner of the data', () {
      expect(make(contest: exampleId(0x10)).syncScope, SyncScope.contest);
      expect(make(owner: exampleId(1)).syncScope, SyncScope.director);
    });
  });
}
