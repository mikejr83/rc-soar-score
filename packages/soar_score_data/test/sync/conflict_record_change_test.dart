import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  setUp(() async => inst = await Installation.open(backend));
  tearDown(() => inst.close());

  final contestId = core.Id.parse('019c0000-0000-7000-8000-000000000010');
  final scope = core.ContestScopeKey(contestId);

  core.ConflictRecord record({
    String? id,
    bool requiresAction = true,
    core.ConflictResolution resolution = core.ConflictResolution.pending,
    core.ConflictResolutionChoice? choice,
    DateTime? resolvedAt,
  }) => core.ConflictRecord(
    id: core.Id.parse(id ?? '019c0000-0000-7000-8000-0000000000c4'),
    contestId: contestId,
    entityType: 'ScorePlaceholder',
    entityId: core.Id.parse('019c0000-0000-7000-8000-000000000301'),
    acceptedMutationId: core.Id.parse('019c0000-0000-7000-8000-0000000000c3'),
    competingMutationId: core.Id.parse('019c0000-0000-7000-8000-0000000000c7'),
    reasonCode: 'stale_base',
    requiresAction: requiresAction,
    resolution: resolution,
    resolutionChoice: choice,
    createdAt: DateTime.utc(2026, 10, 17, 15, 12),
    resolvedAt: resolvedAt,
    acceptedPayload: const {'state': 'Official', 'score_revision': 2},
    competingPayload: const {'state': 'Submitted', 'score_revision': 1},
    entityRevision: 3,
  );

  core.ReplicatedChange change(core.ConflictRecord r, {int sequence = 1}) =>
      core.ReplicatedChange(
        scope: scope,
        sequence: sequence,
        entityType: 'ConflictRecord',
        entityId: r.id,
        revision: 0,
        payload: r.toJson(),
      );

  test(
    'stores a conflict record with both payloads and the revision',
    () async {
      final r = record();

      await inst.applier.apply(change(r));

      final stored = (await inst.syncStore.conflictsNeedingAction(scope))
          .single;
      expect(stored, r);
      expect(stored.acceptedPayload, {
        'state': 'Official',
        'score_revision': 2,
      });
      expect(stored.competingPayload, {
        'state': 'Submitted',
        'score_revision': 1,
      });
      expect(stored.entityRevision, 3);
    },
  );

  test('applying the same change twice changes nothing', () async {
    final r = record();

    await inst.applier.apply(change(r));
    await inst.applier.apply(change(r));

    expect(await inst.syncStore.conflictsNeedingAction(scope), [r]);
    expect(await inst.count('conflict_records'), 1);
  });

  test(
    'a later change of the record replaces it with the resolution',
    () async {
      await inst.applier.apply(change(record()));
      final resolved = record(
        resolution: core.ConflictResolution.manual,
        choice: core.ConflictResolutionChoice.keptAccepted,
        resolvedAt: DateTime.utc(2026, 10, 17, 16),
      );

      await inst.applier.apply(change(resolved, sequence: 2));

      expect(await inst.syncStore.conflictsNeedingAction(scope), isEmpty);
      expect(await inst.count('conflict_records'), 1);
      final status = await inst.syncStore.status(scope);
      expect(status.conflictsNeedingAction, 0);
    },
  );

  test('a silent record is stored but does not need action', () async {
    final silent = record(
      requiresAction: false,
      resolution: core.ConflictResolution.automatic,
    );

    await inst.applier.apply(change(silent));

    expect(await inst.count('conflict_records'), 1);
    expect(await inst.syncStore.conflictsNeedingAction(scope), isEmpty);
  });

  test('a record without payloads still stores', () async {
    final bare = core.ConflictRecord(
      id: core.Id.parse('019c0000-0000-7000-8000-0000000000c5'),
      contestId: contestId,
      entityType: 'ScorePlaceholder',
      entityId: core.Id.parse('019c0000-0000-7000-8000-000000000301'),
      competingMutationId: core.Id.parse(
        '019c0000-0000-7000-8000-0000000000c7',
      ),
      reasonCode: 'stale_base',
      createdAt: DateTime.utc(2026, 10, 17, 15, 12),
    );

    await inst.applier.apply(change(bare));

    final stored = (await inst.syncStore.conflictsNeedingAction(scope)).single;
    expect(stored.acceptedPayload, isNull);
    expect(stored.entityRevision, isNull);
  });
}
