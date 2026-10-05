import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  setUp(() async => inst = await Installation.open(backend));
  tearDown(() => inst.close());

  core.ReplicatedChange change(
    core.Contest c, {
    int sequence = 1,
    bool isDelete = false,
  }) => core.ReplicatedChange(
    scope: core.ContestScopeKey(c.id),
    sequence: sequence,
    entityType: 'Contest',
    entityId: c.id,
    revision: c.revision,
    payload: c.toJson(),
    isDelete: isDelete,
  );

  Future<core.Contest?> stored(core.Contest c) =>
      (inst.stores.of('Contest').findJson(c.id))
          .then((json) => json == null ? null : core.Contest.fromJson(json));

  test('stores the entity at the revision the service gave it', () async {
    final c = contest(revision: 5);
    await inst.applier.apply(change(c));
    expect(await stored(c), c);
  });

  test('creates no mutation and no tombstone', () async {
    final c = contest(revision: 2);
    await inst.applier.apply(change(c));
    await inst.applier.apply(change(c, isDelete: true));
    expect(await inst.count('mutation_records'), 0);
    expect(await inst.count('tombstones'), 0);
  });

  test('applying the same change again changes nothing', () async {
    final c = contest(revision: 3);
    await inst.applier.apply(change(c));
    await inst.applier.apply(change(c));
    expect(await stored(c), c);
    expect(await inst.count('contests'), 1);
  });

  test('ignores a change older than the stored revision', () async {
    final newer = contest(name: 'Newer', revision: 4);
    final older = contest(name: 'Older', revision: 3, id: newer.id);
    await inst.applier.apply(change(newer));
    await inst.applier.apply(change(older));
    expect((await stored(newer))!.name, 'Newer');
  });

  test('applies a newer revision over the stored one', () async {
    final first = contest(name: 'First', revision: 1);
    final second = contest(name: 'Second', revision: 2, id: first.id);
    await inst.applier.apply(change(first));
    await inst.applier.apply(change(second));
    expect(await stored(first), second);
  });

  test('a delete removes the entity and repeats harmlessly', () async {
    final c = contest(revision: 1);
    await inst.applier.apply(change(c));
    await inst.applier.apply(change(c, isDelete: true));
    await inst.applier.apply(change(c, isDelete: true));
    expect(await stored(c), isNull);
  });

  test('refuses derived entity types', () async {
    for (final type in [
      'FlightResult',
      'ParticipationStanding',
      'TeamStanding',
    ]) {
      await expectLater(
        inst.applier.apply(
          core.ReplicatedChange(
            scope: core.ContestScopeKey(core.Id.create()),
            sequence: 1,
            entityType: type,
            entityId: core.Id.create(),
            revision: 0,
            payload: const {},
          ),
        ),
        throwsArgumentError,
        reason: type,
      );
    }
  });

  test('refuses an entity type with no store', () async {
    await expectLater(
      inst.applier.apply(
        core.ReplicatedChange(
          scope: core.ContestScopeKey(core.Id.create()),
          sequence: 1,
          entityType: 'Unknown',
          entityId: core.Id.create(),
          revision: 0,
          payload: const {},
        ),
      ),
      throwsArgumentError,
    );
  });
}
