import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  late List<core.SyncScopeKey> heard;
  setUp(() async {
    inst = await Installation.open(backend);
    heard = [];
    inst.db.localChanges.listen(heard.add);
  });
  tearDown(() => inst.close());

  test('announces the contest scope after a write commits', () async {
    final saved = await inst.unitOfWork.run(
      (c) => c.save(contest(), metadata: metadata()),
    );
    await Future<void>.delayed(Duration.zero);

    expect(heard, [core.ContestScopeKey(saved.id)]);
  });

  test('announces nothing when the write is rolled back', () async {
    await expectLater(
      inst.unitOfWork.run((c) async {
        await c.save(contest(), metadata: metadata());
        throw StateError('abandon');
      }),
      throwsStateError,
    );
    await Future<void>.delayed(Duration.zero);

    expect(heard, isEmpty);
  });

  test('announces a scope once per unit of work', () async {
    await inst.unitOfWork.run((c) async {
      final first = await c.save(contest(), metadata: metadata(requestId: 'a'));
      await c.save(
        contest(name: 'Again', id: first.id),
        metadata: metadata(requestId: 'b'),
      );
    });
    await Future<void>.delayed(Duration.zero);

    expect(heard, hasLength(1));
  });

  test('applying a replicated change is not announced', () async {
    final saved = await inst.unitOfWork.run(
      (c) => c.save(contest(), metadata: metadata()),
    );
    await Future<void>.delayed(Duration.zero);
    heard.clear();

    await inst.applier.apply(
      core.ReplicatedChange(
        scope: core.ContestScopeKey(saved.id),
        sequence: 1,
        entityType: 'Contest',
        entityId: saved.id,
        revision: saved.revision + 1,
        payload: {...saved.toJson(), 'name': 'From server'},
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(heard, isEmpty);
  });
}
