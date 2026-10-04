import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../sync/ids.dart';

MatrixRevision make({
  int number = 1,
  Id? previous,
  int first = 1,
  int last = 8,
  int seed = 2918374651,
  Id? finalizedBy,
  DateTime? finalizedAt,
}) => MatrixRevision(
  id: exampleId(1),
  contestId: exampleId(2),
  revisionNumber: number,
  previousRevisionId: previous,
  firstRound: first,
  lastRound: last,
  drawMode: DrawMode.standardManOnMan,
  randomSeed: seed,
  algorithmVersion: '1.0.0',
  drawConfig: const {'schema_version': 1},
  seedingSnapshot: const {'pilots': []},
  createdBy: exampleId(3),
  createdAt: t0,
  finalizedBy: finalizedBy,
  finalizedAt: finalizedAt,
);

void main() {
  group('MatrixRevision', () {
    test('round trips and is contest data', () {
      final r = make();
      expect(r.toJson()['draw_mode'], 'StandardManOnMan');
      expect(r.toJson()['fairness_summary'], isNull);
      expect(MatrixRevision.fromJson(r.toJson()), r);
      expect(r.syncScope, SyncScope.contest);
    });

    test('is a draft until finalized, with both finalizer fields', () {
      expect(make().isFinalized, isFalse);
      expect(
        make(finalizedBy: exampleId(3), finalizedAt: t0).isFinalized,
        true,
      );
      expect(() => make(finalizedBy: exampleId(3)), throwsArgumentError);
      expect(() => make(finalizedAt: t0), throwsArgumentError);
    });

    test('only the first revision lacks a previous revision', () {
      expect(() => make(number: 2), throwsArgumentError);
      expect(() => make(previous: exampleId(9)), throwsArgumentError);
      expect(
        make(number: 2, previous: exampleId(9), first: 5, last: 8).firstRound,
        5,
      );
    });

    test('the first revision starts at round 1', () {
      expect(() => make(first: 2), throwsArgumentError);
    });

    test('round range must be ordered and positive', () {
      expect(() => make(first: 5, last: 4), throwsArgumentError);
      expect(() => make(number: 0), throwsArgumentError);
    });

    test('the seed is an unsigned 32-bit number', () {
      expect(() => make(seed: -1), throwsArgumentError);
      expect(() => make(seed: 0x100000000), throwsArgumentError);
      expect(make(seed: 0xFFFFFFFF).randomSeed, 0xFFFFFFFF);
    });

    test('copies the draw maps', () {
      final config = <String, Object?>{'a': 1};
      final r = MatrixRevision(
        id: exampleId(1),
        contestId: exampleId(2),
        revisionNumber: 1,
        firstRound: 1,
        lastRound: 1,
        drawMode: DrawMode.seededManOnMan,
        randomSeed: 1,
        algorithmVersion: '1.0.0',
        drawConfig: config,
        seedingSnapshot: const {},
        createdBy: exampleId(3),
        createdAt: t0,
      );
      config['a'] = 2;
      expect(r.drawConfig['a'], 1);
    });
  });
}
