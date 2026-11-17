import 'dart:async';

import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';
import '../../support/fixtures.dart' show Installation;

void main() {
  forEachBackend(_tests);
  forPostgresOnly(_twoConnections);
}

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

  Future<core.InstallationActivation> replaceWithB() async {
    await harness.register(harness.installationB, 'Tablet');
    return harness.installations.activate(
      accountId: harness.account,
      contestId: contestId,
      installationId: harness.installationB,
      kind: core.ActivationKind.replacement,
    );
  }

  test(
    'an activation that commits first refuses the old installation',
    () async {
      await replaceWithB();
      final operationId = core.Id.create();

      final result = await send(
        service(harness.serverRepository),
        intent(slots[0], operationId: operationId),
      );

      expect(result.outcome, core.MutationOutcome.rejected);
      expect(result.reasonCode, 'inactive_installation');
      expect(await officials(slots.map((s) => s.id)), isEmpty);
      expect(await receipts(), isEmpty);
      // The refusal is final for that request.
      final again = await send(
        service(harness.serverRepository),
        intent(slots[0], operationId: operationId, clientMutationId: 'race-x'),
      );
      expect(again.outcome, core.MutationOutcome.rejected);
    },
  );

  test('an activation started mid-decision waits for the commit', () async {
    final hooked = _HookedPlaceholders(harness.server.db);
    final repository = _HookedRepository(harness.server.db, hooked);
    Future<core.InstallationActivation>? activation;
    hooked.after = () async {
      // The authority check is behind us; the replacement starts now, outside
      // the running transaction, and must queue behind it.
      activation = Zone.root.run(replaceWithB);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    };

    final result = await send(service(repository), intent(slots[0]));
    final replaced = await activation!;

    expect(result.outcome, core.MutationOutcome.accepted);
    expect(await officials([slots[0].id]), hasLength(1));
    final receipt = (await receipts()).single;
    expect(receipt.sequence, isNotNull);
    expect(replaced.installationId, harness.installationB);
    // The old installation holds no authority any more: a further intent from
    // it is refused.
    final next = await send(
      service(harness.serverRepository),
      intent(slots[1]),
    );
    expect(next.reasonCode, 'inactive_installation');
    expect(await officials([slots[1].id]), isEmpty);
  });

  test('a promotion and an activation raced: one consistent outcome', () async {
    final a = service(harness.serverRepository);
    final m = intent(slots[0]);

    final outcome = await Future.wait<Object>([send(a, m), replaceWithB()]);

    final result = outcome[0] as MutationResult;
    final promoted = await officials([slots[0].id]);
    if (result.outcome == core.MutationOutcome.accepted) {
      expect(promoted, hasLength(1));
      expect(await receipts(), hasLength(1));
    } else {
      expect(result.reasonCode, 'inactive_installation');
      expect(promoted, isEmpty);
      expect(await receipts(), isEmpty);
    }
  });

  test(
    'a revocation started mid-decision waits; later intents are refused',
    () async {
      final hooked = _HookedPlaceholders(harness.server.db);
      final repository = _HookedRepository(harness.server.db, hooked);
      Future<core.Installation>? revoked;
      hooked.after = () async {
        revoked = Zone.root.run(
          () => harness.installations.revoke(
            accountId: harness.account,
            id: harness.installationA,
          ),
        );
        for (var i = 0; i < 20; i++) {
          await Future<void>.delayed(Duration.zero);
        }
      };

      final result = await send(service(repository), intent(slots[0]));
      final installation = await revoked!;

      expect(result.outcome, core.MutationOutcome.accepted);
      expect(installation.revokedAt, isNotNull);
      expect(await officials([slots[0].id]), hasLength(1));
      await expectLater(
        send(service(harness.serverRepository), intent(slots[1])),
        throwsA(isA<core.SyncRefusal>()),
      );
      expect(await officials([slots[1].id]), isEmpty);
    },
  );
}

/// Two PostgreSQL connections to one database stand in for two service
/// instances: the lock, not a shared connection, orders the writers.
void _twoConnections(Backend backend) {
  late AcceptorHarness harness;
  late Installation second;
  late core.Id contestId;
  late core.ContestScopeKey scope;
  late core.ScorePlaceholder slot;

  setUp(() async {
    harness = await AcceptorHarness.open(backend);
    second = await harness.server.reopen();
    await DemoDataSeeder(
      harness.clientRepository,
      localAccountId: harness.account,
    ).seed();
    final running = (await harness.clientRepository.contestRepository.getAll())
        .firstWhere((c) => c.name == 'Mountain States Team F5J');
    contestId = running.id;
    scope = core.ContestScopeKey(contestId);
    await harness.uploadAll(contestId);
    slot = (await harness.server.stores.of('ScorePlaceholder').all())
        .cast<core.ScorePlaceholder>()
        .firstWhere(
          (p) =>
              p.contestId == contestId &&
              p.state == core.ScorePlaceholderState.submitted,
        );
    await harness.register(harness.installationB, 'Tablet');
  });
  tearDown(() async {
    await second.close();
    await harness.close();
  });

  SyncMutation intent() => SyncMutation(
    id: core.Id.create(),
    clientMutationId: 'two-connections',
    entityType: core.promotionReceiptEntityType,
    entityId: core.Id.create(),
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

  Future<MutationResult> send(SyncAcceptorService s) async => (await s.exchange(
    accountId: harness.account,
    input: SyncExchangeInput(
      protocolVersion: 1,
      schemaVersion: 1,
      installationId: harness.installationA,
      scope: scope,
      lastAcknowledgedSequence: 0,
      mutations: [intent()],
    ),
  )).results.single;

  Future<core.InstallationActivation> activate(Repository repository) =>
      InstallationSyncService(repository).activate(
        accountId: harness.account,
        contestId: contestId,
        installationId: harness.installationB,
        kind: core.ActivationKind.replacement,
      );

  Future<int> officials() async =>
      (await harness.server.stores.of('OfficialScore').all())
          .cast<core.OfficialScore>()
          .where((o) => o.scorePlaceholderId == slot.id)
          .length;

  test('an activation waits for a decision that holds the gate', () async {
    final hooked = _HookedPlaceholders(harness.server.db);
    final repository = _HookedRepository(harness.server.db, hooked);
    final reached = Completer<void>();
    final release = Completer<void>();
    hooked.after = () async {
      reached.complete();
      await release.future;
    };
    final promotion = send(
      SyncAcceptorService(repository, versions: const SyncVersions.exactly(1)),
    );
    await reached.future;

    var activated = false;
    final activation = activate(Repository(second.db)).then((a) {
      activated = true;
      return a;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(activated, isFalse, reason: 'the gate is held by the decision');

    release.complete();
    final result = await promotion;
    await activation;

    expect(result.outcome, core.MutationOutcome.accepted);
    expect(await officials(), 1);
  });

  test('a decision waits for an activation that holds the gate', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    final holding = Repository(second.db).officialScoreRepository
        .withContestGate(contestId, () async {
          await activate(Repository(second.db));
          entered.complete();
          await release.future;
        });
    await entered.future;

    var decided = false;
    final promotion =
        send(
          SyncAcceptorService(
            harness.serverRepository,
            versions: const SyncVersions.exactly(1),
          ),
        ).then((r) {
          decided = true;
          return r;
        });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(decided, isFalse, reason: 'the decision waits at the gate');

    release.complete();
    await holding;
    final result = await promotion;

    expect(result.outcome, core.MutationOutcome.rejected);
    expect(result.reasonCode, 'inactive_installation');
    expect(await officials(), 0);
  });

  test(
    'a revocation waits for a decision that holds the installation',
    () async {
      final hooked = _HookedPlaceholders(harness.server.db);
      final repository = _HookedRepository(harness.server.db, hooked);
      final reached = Completer<void>();
      final release = Completer<void>();
      hooked.after = () async {
        reached.complete();
        await release.future;
      };
      final promotion = send(
        SyncAcceptorService(
          repository,
          versions: const SyncVersions.exactly(1),
        ),
      );
      await reached.future;

      var revoked = false;
      final revocation = InstallationSyncService(Repository(second.db))
          .revoke(accountId: harness.account, id: harness.installationA)
          .then((i) {
            revoked = true;
            return i;
          });
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(revoked, isFalse, reason: 'the row is held by the decision');

      release.complete();
      final result = await promotion;
      await revocation;

      expect(result.outcome, core.MutationOutcome.accepted);
      expect(await officials(), 1);
    },
  );
}
