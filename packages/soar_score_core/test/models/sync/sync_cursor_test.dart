import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import 'ids.dart';

SyncCursor make({Id? contest, Id? owner, int seq = 412}) => SyncCursor(
  id: exampleId(0xc2),
  installationId: exampleId(0xc0),
  contestId: contest,
  ownerAccountId: owner,
  lastSyncedSequence: seq,
  updatedAt: t0,
);

void main() {
  group('SyncCursor', () {
    test('round trips for a contest and for a director', () {
      for (final cursor in [
        make(contest: exampleId(0x10)),
        make(owner: exampleId(1)),
      ]) {
        expect(SyncCursor.fromJson(cursor.toJson()), cursor);
      }
      expect(make(owner: exampleId(1)).toJson()['contest_id'], isNull);
    });

    test('needs exactly one of contest and owner', () {
      expect(() => make(), throwsArgumentError);
      expect(
        () => make(contest: exampleId(0x10), owner: exampleId(1)),
        throwsArgumentError,
      );
    });

    test('defaults to sequence 0 and rejects a negative one', () {
      expect(
        SyncCursor(
          id: exampleId(1),
          installationId: exampleId(2),
          contestId: exampleId(3),
          updatedAt: t0,
        ).lastSyncedSequence,
        0,
      );
      expect(
        () => make(contest: exampleId(0x10), seq: -1),
        throwsArgumentError,
      );
    });

    test('is backend only', () {
      expect(make(contest: exampleId(0x10)), isA<BackendOnly>());
    });
  });
}
