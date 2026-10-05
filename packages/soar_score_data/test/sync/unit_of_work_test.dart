import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../support/fixtures.dart';

void main() {
  late Installation inst;
  setUp(() => inst = Installation.open());
  tearDown(() => inst.db.close());

  Future<List<core.MutationRecord>> mutations() async => [
    for (final row in await inst.db.select(inst.db.mutationRecords).get())
      core.MutationRecord.fromJson({
        'id': row.id,
        'contest_id': row.contestId,
        'owner_account_id': row.ownerAccountId,
        'sequence': row.sequence,
        'entity_type': row.entityType,
        'entity_id': row.entityId,
        'base_revision': row.baseRevision,
        'client_mutation_id': row.clientMutationId,
        'actor_id': row.actorId,
        'authority': row.authority,
        'source_installation_id': row.sourceInstallationId,
        'source_device': row.sourceDevice,
        'client_time': row.clientTime,
        'server_acceptance_time': row.serverAcceptanceTime,
        'server_rejection_time': row.serverRejectionTime,
        'payload': {
          'version': 1,
          'data': {'operation': 'save'},
        },
        'outcome': row.outcome,
        'reason_code': row.reasonCode,
        'error_message': row.errorMessage,
        'depends_on_mutation_id': row.dependsOnMutationId,
      }),
  ];

  group('save', () {
    test('stores a new entity and records one pending mutation', () async {
      final saved = await inst.unitOfWork.run(
        (c) => c.save(contest(), metadata: metadata(requestId: 'r1')),
      );

      expect(saved.revision, 0);
      expect(await inst.count('contests'), 1);
      final records = await mutations();
      expect(records, hasLength(1));
      expect(records.single.outcome, core.MutationOutcome.pending);
      expect(records.single.entityType, 'Contest');
      expect(records.single.entityId, saved.id);
      expect(records.single.contestId, saved.id);
      expect(records.single.baseRevision, isNull);
      expect(records.single.clientMutationId, 'r1');
    });

    test('bumps the revision of a stored entity', () async {
      final first = await inst.unitOfWork.run(
        (c) => c.save(contest(), metadata: metadata()),
      );
      final second = await inst.unitOfWork.run(
        (c) => c.save(
          contest(name: 'Renamed', id: first.id),
          metadata: metadata(),
        ),
      );

      expect(second.revision, 1);
      final records = await mutations();
      expect(records, hasLength(2));
      expect(records.map((r) => r.baseRevision), unorderedEquals([null, 0]));
      expect(await inst.count('contests'), 1);
    });

    test('refuses a write based on an older revision', () async {
      final first = await inst.unitOfWork.run(
        (c) => c.save(contest(), metadata: metadata()),
      );
      await inst.unitOfWork.run((c) => c.save(first, metadata: metadata()));

      await expectLater(
        inst.unitOfWork.run((c) => c.save(first, metadata: metadata())),
        throwsA(
          isA<core.StaleRevisionError>()
              .having((e) => e.expectedRevision, 'expected', 0)
              .having((e) => e.storedRevision, 'stored', 1),
        ),
      );
      expect(await inst.count('mutation_records'), 2);
    });

    test('keeps nothing when the body throws', () async {
      await expectLater(
        inst.unitOfWork.run((c) async {
          await c.save(contest(), metadata: metadata());
          throw StateError('boom');
        }),
        throwsStateError,
      );
      expect(await inst.count('contests'), 0);
      expect(await inst.count('mutation_records'), 0);
    });

    test('a retried client mutation id is refused and keeps nothing', () async {
      final saved = await inst.unitOfWork.run(
        (c) => c.save(contest(), metadata: metadata(requestId: 'same')),
      );
      await expectLater(
        inst.unitOfWork.run(
          (c) => c.save(saved, metadata: metadata(requestId: 'same')),
        ),
        throwsA(anything),
      );
      expect(
        (await inst.stores.of('Contest').findJson(saved.id))!['revision'],
        0,
      );
      expect(await inst.count('mutation_records'), 1);
    });
  });

  group('delete', () {
    test('removes the entity, writes a tombstone and a mutation', () async {
      final saved = await inst.unitOfWork.run(
        (c) => c.save(contest(), metadata: metadata()),
      );
      await inst.unitOfWork.run((c) => c.delete(saved, metadata: metadata()));

      expect(await inst.count('contests'), 0);
      expect(await inst.count('mutation_records'), 2);
      final tombstone = (await inst.db.select(inst.db.tombstones).get()).single;
      expect(tombstone.entityType, 'Contest');
      expect(tombstone.entityId, saved.id.value);
      expect(tombstone.contestId, saved.id.value);
      expect(tombstone.status, 'Pending');
      expect(tombstone.deletedAt, '2026-05-01T12:00:00Z');
    });

    test('is a no-op for an entity that is not stored', () async {
      await inst.unitOfWork.run(
        (c) => c.delete(contest(), metadata: metadata()),
      );
      expect(await inst.count('tombstones'), 0);
      expect(await inst.count('mutation_records'), 0);
    });

    test('refuses a delete based on an older revision', () async {
      final saved = await inst.unitOfWork.run(
        (c) => c.save(contest(), metadata: metadata()),
      );
      await inst.unitOfWork.run((c) => c.save(saved, metadata: metadata()));
      await expectLater(
        inst.unitOfWork.run((c) => c.delete(saved, metadata: metadata())),
        throwsA(isA<core.StaleRevisionError>()),
      );
      expect(await inst.count('contests'), 1);
      expect(await inst.count('tombstones'), 0);
    });
  });
}
