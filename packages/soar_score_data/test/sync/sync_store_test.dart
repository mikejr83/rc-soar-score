import 'package:drift/drift.dart' show Variable;
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart' show portableSql;
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

void _tests(Backend backend) {
  late Installation inst;
  setUp(() async => inst = await Installation.open(backend));
  tearDown(() => inst.close());

  late core.Contest a;
  late core.Contest b;
  setUp(() async {
    a = await inst.unitOfWork.run(
      (c) => c.save(contest(), metadata: metadata()),
    );
    b = await inst.unitOfWork.run(
      (c) => c.save(contest(), metadata: metadata()),
    );
  });

  group('outbox', () {
    test(
      'lists only the pending mutations of the scope, oldest first',
      () async {
        await inst.unitOfWork.run((c) => c.save(a, metadata: metadata()));
        final pending = await inst.syncStore.pendingMutations(
          core.ContestScopeKey(a.id),
        );
        expect(pending, hasLength(2));
        expect(pending.every((m) => m.contestId == a.id), isTrue);
        expect(
          pending.map((m) => m.id.value),
          orderedEquals([...pending.map((m) => m.id.value)]..sort()),
        );
      },
    );

    test('records an accepted outcome with its sequence', () async {
      final scope = core.ContestScopeKey(a.id);
      final mutation = (await inst.syncStore.pendingMutations(scope)).single;
      await inst.syncStore.recordOutcome(
        mutationId: mutation.id,
        outcome: core.MutationOutcome.accepted,
        sequence: 7,
        serverAcceptanceTime: DateTime.utc(2026, 5, 1, 13),
      );
      expect(await inst.syncStore.pendingMutations(scope), isEmpty);
    });

    test('an accepted outcome needs a sequence', () async {
      final mutation = (await inst.syncStore.pendingMutations(
        core.ContestScopeKey(a.id),
      )).single;
      await expectLater(
        inst.syncStore.recordOutcome(
          mutationId: mutation.id,
          outcome: core.MutationOutcome.accepted,
        ),
        throwsArgumentError,
      );
    });

    test(
      'recording the same outcome again is harmless, a different one is not',
      () async {
        final mutation = (await inst.syncStore.pendingMutations(
          core.ContestScopeKey(a.id),
        )).single;
        Future<void> accept(int sequence) => inst.syncStore.recordOutcome(
          mutationId: mutation.id,
          outcome: core.MutationOutcome.accepted,
          sequence: sequence,
        );
        await accept(7);
        await accept(7);
        await expectLater(accept(8), throwsStateError);
        await expectLater(
          inst.syncStore.recordOutcome(
            mutationId: mutation.id,
            outcome: core.MutationOutcome.rejected,
            reasonCode: 'x',
          ),
          throwsStateError,
        );
      },
    );

    test('refuses a mutation that is not in the outbox', () async {
      await expectLater(
        inst.syncStore.recordOutcome(
          mutationId: core.Id.create(),
          outcome: core.MutationOutcome.rejected,
        ),
        throwsArgumentError,
      );
    });
  });

  group('cursor', skip: _clientOnly(backend), () {
    test('starts at zero and keeps what was written', () async {
      final scope = core.ContestScopeKey(a.id);
      expect(await inst.syncStore.readCursor(scope), 0);
      await inst.syncStore.writeCursor(
        scope,
        5,
        syncedAt: DateTime.utc(2026, 5, 1, 14),
      );
      expect(await inst.syncStore.readCursor(scope), 5);
      expect(await inst.syncStore.readCursor(core.ContestScopeKey(b.id)), 0);
    });

    test('never moves back', () async {
      final scope = core.ContestScopeKey(a.id);
      await inst.syncStore.writeCursor(scope, 5);
      await inst.syncStore.writeCursor(scope, 5);
      await inst.syncStore.writeCursor(scope, 9);
      await expectLater(
        inst.syncStore.writeCursor(scope, 8),
        throwsArgumentError,
      );
      expect(await inst.syncStore.readCursor(scope), 9);
    });

    test('keeps a director scope apart from a contest scope', () async {
      final director = core.DirectorScopeKey(core.Id.create());
      await inst.syncStore.writeCursor(director, 3);
      expect(await inst.syncStore.readCursor(director), 3);
      expect(await inst.syncStore.readCursor(core.ContestScopeKey(a.id)), 0);
    });
  });

  group('status', skip: _clientOnly(backend), () {
    test('counts the outbox, conflicts and the position', () async {
      final scope = core.ContestScopeKey(a.id);
      await inst.syncStore.writeCursor(
        scope,
        4,
        syncedAt: DateTime.utc(2026, 5, 1, 14),
      );
      final competing = core.Id.create();
      await _conflict(inst, a.id, competing, requiresAction: true);
      await _conflict(inst, a.id, core.Id.create(), requiresAction: false);

      final status = await inst.syncStore.status(scope);
      expect(status.pendingMutations, 1);
      expect(status.conflictsNeedingAction, 1);
      expect(status.lastSyncedSequence, 4);
      expect(status.lastSyncedAt, DateTime.utc(2026, 5, 1, 14));

      final conflicts = await inst.syncStore.conflictsNeedingAction(scope);
      expect(conflicts.single.competingMutationId, competing);
      expect(
        await inst.syncStore.conflictsNeedingAction(core.ContestScopeKey(b.id)),
        isEmpty,
      );
    });
  });
}

Future<void> _conflict(
  Installation inst,
  core.Id contestId,
  core.Id competing, {
  required bool requiresAction,
}) => inst.db.customInsert(
  portableSql(
    inst.db,
    'INSERT INTO conflict_records (id, contest_id, entity_type, entity_id, '
    'competing_mutation_id, reason_code, requires_action, resolution, created_at) '
    "VALUES (?, ?, 'Contest', ?, ?, 'stale', ?, ?, '2026-05-01T10:00:00Z')",
  ),
  variables: [
    Variable(core.Id.create().value),
    Variable(contestId.value),
    Variable(contestId.value),
    Variable(competing.value),
    Variable(requiresAction),
    Variable(requiresAction ? 'Pending' : 'Automatic'),
  ],
);

/// The sync position table exists only on an installation; the server keeps a
/// `SyncCursor` per installation instead.
Object _clientOnly(Backend backend) => backend == Backend.postgres
    ? 'client-only table, not on the server'
    : false;
