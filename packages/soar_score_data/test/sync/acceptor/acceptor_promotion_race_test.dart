import 'dart:async';

import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// Runs [before] ahead of, and [after] once behind, the first read of a
/// slot's placeholder under a row lock (the read an adoption starts with).
class _HookedPlaceholders extends ScorePlaceholderRepository {
  _HookedPlaceholders(super.db);

  Future<void> Function()? after;

  @override
  Future<core.ScorePlaceholder?> findForAssignmentForUpdate(
    core.Id assignmentId,
  ) async {
    final found = await super.findForAssignmentForUpdate(assignmentId);
    final hook = after;
    after = null;
    await hook?.call();
    return found;
  }
}

class _HookedRepository extends Repository {
  _HookedRepository(super.database, this.placeholders);

  final _HookedPlaceholders placeholders;

  @override
  core.ScorePlaceholderRepository get scorePlaceholderRepository =>
      placeholders;
}

class _CountingRecalculation extends RecalculationService {
  _CountingRecalculation(super.results);

  var runs = 0;

  @override
  Future<String?> recalculateAfterEntry(
    core.Id contestId, {
    String cause = 'a score entry',
  }) async {
    runs++;
    return null;
  }
}

/// Concurrent decisions of one `promote_score` operation by separate service
/// instances over one database, with controlled interleavings.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;
  late core.ContestScopeKey scope;
  late List<core.ScorePlaceholder> slots;
  var seq = 0;

  setUp(() async {
    harness = await AcceptorHarness.open(backend);
    await DemoDataSeeder(
      harness.clientRepository,
      localAccountId: harness.account,
    ).seed();
    final running = (await harness.clientRepository.contestRepository.getAll())
        .firstWhere((c) => c.name == 'Mountain States Team F5J');
    contestId = running.id;
    scope = core.ContestScopeKey(contestId);
    await harness.uploadAll(contestId);
    slots = (await harness.server.stores.of('ScorePlaceholder').all())
        .cast<core.ScorePlaceholder>()
        .where(
          (p) =>
              p.contestId == contestId &&
              p.state == core.ScorePlaceholderState.submitted,
        )
        .toList();
  });
  tearDown(() => harness.close());

  SyncAcceptorService service(
    Repository repository, {
    RecalculationService? recalculation,
  }) => SyncAcceptorService(
    repository,
    versions: const SyncVersions.exactly(1),
    recalculation: recalculation,
  );

  SyncMutation intent(
    core.ScorePlaceholder slot, {
    core.Id? operationId,
    String? clientMutationId,
  }) => SyncMutation(
    id: core.Id.create(),
    clientMutationId: clientMutationId ?? 'race-${seq++}',
    entityType: core.promotionReceiptEntityType,
    entityId: operationId ?? core.Id.create(),
    authority: core.Authority.director,
    clientTime: DateTime.utc(2026, 11, 16),
    payload: {
      'version': 1,
      'data': {
        'operation': core.SyncCapabilities.promoteScore,
        'operation_version': 1,
        'assignment_id': slot.assignmentId.value,
        'source_attempt_id': slot.currentAttemptId!.value,
        'expected_score_revision': slot.scoreRevision,
      },
    },
  );

  Future<MutationResult> send(SyncAcceptorService s, SyncMutation m) async =>
      (await s.exchange(
        accountId: harness.account,
        input: SyncExchangeInput(
          protocolVersion: 1,
          schemaVersion: 1,
          installationId: harness.installationA,
          scope: scope,
          lastAcknowledgedSequence: 0,
          mutations: [m],
        ),
      )).results.single;

  Future<List<core.OfficialScore>> officials(
    Iterable<core.Id> placeholders,
  ) async => (await harness.server.stores.of('OfficialScore').all())
      .cast<core.OfficialScore>()
      .where((o) => placeholders.contains(o.scorePlaceholderId))
      .toList();

  Future<List<core.MutationRecord>> receipts({core.Id? operationId}) async =>
      (await harness.server.stores.of('MutationRecord').all())
          .cast<core.MutationRecord>()
          .where(
            (r) =>
                r.entityType == core.promotionReceiptEntityType &&
                r.outcome == core.MutationOutcome.accepted &&
                (operationId == null || r.entityId == operationId),
          )
          .toList();

  test(
    'one operation id, two request ids and slots, two instances: one decision',
    () async {
      final counting = _CountingRecalculation(
        ResultsService(harness.serverRepository),
      );
      final a = service(harness.serverRepository, recalculation: counting);
      final b = service(harness.serverRepository, recalculation: counting);
      final operationId = core.Id.create();

      final results = await Future.wait([
        send(a, intent(slots[0], operationId: operationId)),
        send(b, intent(slots[1], operationId: operationId)),
      ]);

      final accepted = results.where(
        (r) => r.outcome == core.MutationOutcome.accepted,
      );
      final refused = results.where(
        (r) => r.outcome == core.MutationOutcome.rejected,
      );
      expect(accepted, hasLength(1));
      expect(refused.single.reasonCode, 'operation_mismatch');
      expect(await officials(slots.map((s) => s.id)), hasLength(1));
      expect(await receipts(operationId: operationId), hasLength(1));
      // Only the committed decision recalculates the contest's results.
      expect(counting.runs, 1);
    },
  );

  test('simultaneous identical retries: one receipt, one official', () async {
    final a = service(harness.serverRepository);
    final b = service(harness.serverRepository);
    final m = intent(slots[0]);

    final results = await Future.wait([send(a, m), send(b, m), send(a, m)]);

    for (final r in results) {
      expect(r.outcome, core.MutationOutcome.accepted);
    }
    expect(results.where((r) => !r.replayed), hasLength(1));
    expect(await officials([slots[0].id]), hasLength(1));
    expect(await receipts(), hasLength(1));
  });

  test(
    'a correction cannot land between the replay check and its receipt',
    () async {
      // Another route adopted the submission, so the intent is answered with
      // a receipt of its own after the gate's replay check.
      await ScoresService(harness.serverRepository).promoteSubmission(
        contestId,
        slots[0].assignmentId,
        sourceAttemptId: slots[0].currentAttemptId!,
        expectedScoreRevision: slots[0].scoreRevision,
        actorId: harness.account,
        metadata: core.MutationMetadata(
          clientMutationId: 'route-promote',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 11, 16),
          actorId: harness.account,
        ),
      );
      final adopted = (await officials([slots[0].id])).single;
      final hooked = _HookedPlaceholders(harness.server.db);
      final repository = _HookedRepository(harness.server.db, hooked);
      Future<void>? correction;
      hooked.after = () async {
        // Starts outside the running transaction, so it queues behind it
        // (SQLite's writer lock, PostgreSQL's gate) instead of joining it.
        correction = Zone.root.run(
          () => ScoresService(harness.serverRepository).enterOfficialScore(
            contestId,
            slots[0].assignmentId,
            clientMutationId: 'correction',
            baseScoreRevision: adopted.scoreRevision,
            reason: 'director_correction',
            components: const {
              'time_flown': 300,
              'launch_height': 100,
              'landing': 'points_50',
            },
            actorId: harness.account,
            metadata: core.MutationMetadata(
              clientMutationId: 'correction',
              authority: core.Authority.director,
              clientTime: DateTime.utc(2026, 11, 16),
              actorId: harness.account,
            ),
          ),
        );
        // Let it reach the lock before this decision goes on.
        for (var i = 0; i < 20; i++) {
          await Future<void>.delayed(Duration.zero);
        }
      };

      final result = await send(service(repository), intent(slots[0]));
      await correction;

      expect(result.outcome, core.MutationOutcome.accepted);
      final receipt = (await receipts()).single;
      final data = (receipt.payload['data']! as Map<String, Object?>);
      expect(data['official_score_id'], adopted.id.value);
      expect(data['score_revision'], adopted.scoreRevision);
      // The correction came after the decision, never between its check and
      // its receipt.
      final versions = await officials([slots[0].id]);
      expect(versions, hasLength(2));
      final newer = versions.firstWhere((o) => o.id != adopted.id);
      expect(newer.scoreRevision, adopted.scoreRevision + 1);
      final newerRecord =
          (await harness.server.stores.of('MutationRecord').all())
              .cast<core.MutationRecord>()
              .firstWhere(
                (r) =>
                    r.entityType == 'OfficialScore' && r.entityId == newer.id,
              );
      expect(newerRecord.sequence, greaterThan(receipt.sequence!));
    },
  );

  test(
    'an interrupted decision keeps nothing and a retry decides it',
    () async {
      final hooked = _HookedPlaceholders(harness.server.db);
      final repository = _HookedRepository(harness.server.db, hooked);
      hooked.after = () async => throw StateError('connection lost');
      final m = intent(slots[0]);
      final records = await harness.serverMutationCount();

      await expectLater(
        send(service(repository), m),
        throwsA(isA<StateError>()),
      );

      expect(await officials([slots[0].id]), isEmpty);
      expect(await receipts(), isEmpty);
      expect(await harness.serverMutationCount(), records);

      final retry = await send(service(repository), m);
      expect(retry.outcome, core.MutationOutcome.accepted);
      expect(retry.replayed, isFalse);
      expect(await officials([slots[0].id]), hasLength(1));
      expect(await receipts(), hasLength(1));
    },
  );

  test('a losing request reads the committed refusal and keeps it', () async {
    // B is current before the intent for A arrives: the first decision is a
    // refusal; a second instance sending the same request reads it.
    final current = slots[0];
    await ScoresService(harness.serverRepository).enterOfficialScore(
      contestId,
      current.assignmentId,
      clientMutationId: 'b',
      baseScoreRevision: current.scoreRevision,
      reason: 'director_correction',
      components: const {
        'time_flown': 480,
        'launch_height': 100,
        'landing': 'points_50',
      },
      actorId: harness.account,
      metadata: core.MutationMetadata(
        clientMutationId: 'b',
        authority: core.Authority.director,
        clientTime: DateTime.utc(2026, 11, 16),
        actorId: harness.account,
      ),
    );
    final m = intent(current);

    final results = await Future.wait([
      send(service(harness.serverRepository), m),
      send(service(harness.serverRepository), m),
    ]);

    for (final r in results) {
      expect(r.outcome, core.MutationOutcome.rejected);
      expect(r.reasonCode, 'stale_source');
    }
    expect(await receipts(), isEmpty);
  });
}
