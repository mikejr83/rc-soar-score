import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/acceptor_harness.dart';
import '../support/backends.dart';

class _Always implements core.PromotionIntentPolicy {
  const _Always();

  @override
  Future<bool> queuesPromotions(core.Id contestId) async => true;
}

void main() => forEachBackend(_tests);

/// An installation marks a stored submission official while its contest
/// syncs: the request is queued as a `promote_score` intent that changes no
/// score, and only the service's receipt settles it.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;
  late core.ContestScopeKey scope;
  late core.ScorePlaceholder slot;
  late ScoresService native;
  var seq = 0;

  core.MutationMetadata meta([String? id]) => core.MutationMetadata(
    clientMutationId: id ?? 'native-${seq++}',
    authority: core.Authority.director,
    clientTime: DateTime.utc(2026, 11, 17),
    actorId: harness.account,
    sourceInstallationId: harness.installationA,
  );

  Future<core.PendingPromotion> queue({
    core.ScorePlaceholder? placeholder,
    int? expected,
    core.Id? sourceId,
  }) async {
    final p = placeholder ?? slot;
    final decision = await native.promoteOrQueue(
      contestId,
      p.assignmentId,
      sourceAttemptId: sourceId ?? p.currentAttemptId!,
      expectedScoreRevision: expected ?? p.scoreRevision,
      actorId: harness.account,
      metadata: meta(),
    );
    return decision.queued!;
  }

  Future<core.ScorePlaceholder> clientSlot([core.ScorePlaceholder? p]) async =>
      (await harness.clientRepository.scorePlaceholderRepository
          .findForAssignment((p ?? slot).assignmentId))!;

  Future<List<core.OfficialScore>> clientOfficials() async =>
      (await harness.client.stores.of('OfficialScore').all())
          .cast<core.OfficialScore>()
          .where((o) => o.scorePlaceholderId == slot.id)
          .toList();

  Future<List<core.MutationRecord>> intents() async =>
      (await harness.client.syncStore.pendingMutations(scope))
          .where((m) => m.entityType == core.promotionReceiptEntityType)
          .toList();

  Future<SyncExchangeOutput> sendIntents() async {
    final sent = [
      for (final m in await intents()) AcceptorHarness.toMutation(m),
    ];
    return harness.exchange(scope, mutations: sent);
  }

  List<core.ReplicatedChange> asChanges(Iterable<AcceptedChange> changes) => [
    for (final c in changes)
      core.ReplicatedChange(
        scope: scope,
        sequence: c.sequence,
        entityType: c.entityType,
        entityId: c.entityId,
        revision: c.revision,
        payload: c.payload,
        isDelete: c.payload['deleted'] == true,
        aggregateId: c.aggregateId,
      ),
  ];

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
    slot = (await harness.client.stores.of('ScorePlaceholder').all())
        .cast<core.ScorePlaceholder>()
        .firstWhere(
          (p) =>
              p.contestId == contestId &&
              p.state == core.ScorePlaceholderState.submitted,
        );
    native = ScoresService(
      harness.clientRepository,
      promotionIntents: const _Always(),
    );
  });
  tearDown(() => harness.close());

  test(
    'queuing writes only the intent and leaves the slot as it was',
    () async {
      final before = await clientSlot();
      final officialBefore = await clientOfficials();

      final intent = await queue();

      expect(await clientOfficials(), hasLength(officialBefore.length));
      final after = await clientSlot();
      expect(after.state, before.state);
      expect(after.scoreRevision, before.scoreRevision);
      expect(after.currentAttemptId, before.currentAttemptId);
      final pending = await intents();
      expect(pending, hasLength(1));
      expect(pending.single.entityId, intent.operationId);
      expect(pending.single.baseRevision, isNull);
      expect(pending.single.authority, core.Authority.director);
      expect(
        (pending.single.payload['data']! as Map)['source_attempt_id'],
        slot.currentAttemptId!.value,
      );
      expect(
        await harness.clientRepository.promotionIntentRepository
            .pendingForAssignment(contestId, slot.assignmentId),
        intent,
      );
    },
  );

  test(
    'the same request again is the same intent, a new one is refused',
    () async {
      final first = await queue();

      expect(await queue(), first);
      expect(await intents(), hasLength(1));
      await expectLater(
        queue(expected: slot.scoreRevision + 1),
        throwsA(
          isA<core.ContestStateError>().having(
            (e) => e.code,
            'code',
            'promotion_pending',
          ),
        ),
      );
    },
  );

  test('a slot with a pending intent accepts no other save', () async {
    await queue();

    await expectLater(
      native.enterOfficialScore(
        contestId,
        slot.assignmentId,
        clientMutationId: 'typed',
        baseScoreRevision: slot.scoreRevision,
        reason: 'director_correction',
        components: const {
          'time_flown': 480,
          'launch_height': 100,
          'landing': 'points_50',
        },
        actorId: harness.account,
        metadata: meta(),
      ),
      throwsA(
        isA<core.ContestStateError>().having(
          (e) => e.code,
          'code',
          'promotion_pending',
        ),
      ),
    );
    await expectLater(
      ScoresService(harness.clientRepository).promoteSubmission(
        contestId,
        slot.assignmentId,
        sourceAttemptId: slot.currentAttemptId!,
        expectedScoreRevision: slot.scoreRevision,
        actorId: harness.account,
        metadata: meta(),
      ),
      throwsA(isA<core.ContestStateError>()),
    );
    expect(await clientOfficials(), isEmpty);
  });

  test('other slots still work while one waits', () async {
    await queue();
    final others = (await harness.client.stores.of('ScorePlaceholder').all())
        .cast<core.ScorePlaceholder>()
        .where(
          (p) =>
              p.contestId == contestId &&
              p.state == core.ScorePlaceholderState.submitted &&
              p.id != slot.id,
        );
    if (others.isEmpty) return;

    final other = await queue(placeholder: others.first);

    expect(other.assignmentId, others.first.assignmentId);
    expect(await intents(), hasLength(2));
  });

  test('a policy that does not queue adopts directly, as before', () async {
    final direct = ScoresService(harness.clientRepository);

    final decision = await direct.promoteOrQueue(
      contestId,
      slot.assignmentId,
      sourceAttemptId: slot.currentAttemptId!,
      expectedScoreRevision: slot.scoreRevision,
      actorId: harness.account,
      metadata: meta(),
    );

    expect(decision.queued, isNull);
    expect(decision.adopted!.entry.officialScore.scoreAttemptId, isNotNull);
    expect(await intents(), isEmpty);
  });

  test('a stale or locked slot is refused before anything is queued', () async {
    await expectLater(
      queue(expected: slot.scoreRevision + 3),
      throwsA(isA<core.StaleRevisionError>()),
    );
    expect(await intents(), isEmpty);
  });

  test(
    'the receipt installs the adoption and settles the intent together',
    () async {
      final intent = await queue();
      final out = await sendIntents();
      expect(out.results.single.outcome, core.MutationOutcome.accepted);

      final changed = await harness.client.applier.applyAggregate(
        asChanges(out.changes.where((c) => c.aggregateId != null)),
      );

      expect(changed, isTrue);
      expect(await intents(), isEmpty);
      final official = await clientOfficials();
      expect(official, hasLength(1));
      expect(official.single.scoreAttemptId, slot.currentAttemptId);
      expect((await clientSlot()).state, core.ScorePlaceholderState.official);
      final settled =
          (await harness.client.stores.of('OfficialScore').all()).isNotEmpty;
      expect(settled, isTrue);
      expect(
        await harness.clientRepository.promotionIntentRepository
            .pendingForAssignment(contestId, intent.assignmentId),
        isNull,
      );
    },
  );

  test('a failure while applying the aggregate keeps nothing of it', () async {
    await queue();
    final out = await sendIntents();
    final changes = asChanges(out.changes.where((c) => c.aggregateId != null));
    final broken = [
      ...changes,
      core.ReplicatedChange(
        scope: scope,
        sequence: changes.last.sequence + 1,
        entityType: 'FlightResult',
        entityId: core.Id.create(),
        revision: 1,
        payload: const {},
        aggregateId: changes.first.aggregateId,
      ),
    ];

    await expectLater(
      harness.client.applier.applyAggregate(broken),
      throwsA(isA<core.UnsupportedEntityTypeError>()),
    );

    expect(await clientOfficials(), isEmpty);
    expect((await clientSlot()).state, core.ScorePlaceholderState.submitted);
    expect(await intents(), hasLength(1));
  });

  test('applying the same aggregate again changes nothing', () async {
    await queue();
    final out = await sendIntents();
    final changes = asChanges(out.changes.where((c) => c.aggregateId != null));
    await harness.client.applier.applyAggregate(changes);

    expect(await harness.client.applier.applyAggregate(changes), isFalse);
    expect(await clientOfficials(), hasLength(1));
  });

  test(
    'a receipt for an intent this installation does not hold changes nothing',
    () async {
      final receipt = core.ReplicatedChange(
        scope: scope,
        sequence: 99999,
        entityType: core.promotionReceiptEntityType,
        entityId: core.Id.create(),
        revision: 0,
        payload: const {'version': 1, 'data': {}},
        aggregateId: core.Id.create(),
      );

      expect(await harness.client.applier.applyAggregate([receipt]), isFalse);
    },
  );

  test('a refusal keeps the intent as rejected and frees the slot', () async {
    final intent = await queue();
    // Another score reached the service first.
    await ScoresService(harness.serverRepository).enterOfficialScore(
      contestId,
      slot.assignmentId,
      clientMutationId: 'director-b',
      baseScoreRevision: slot.scoreRevision,
      reason: 'director_correction',
      components: const {
        'time_flown': 480,
        'launch_height': 100,
        'landing': 'points_50',
      },
      actorId: harness.account,
      metadata: core.MutationMetadata(
        clientMutationId: 'director-b',
        authority: core.Authority.director,
        clientTime: DateTime.utc(2026, 11, 17),
        actorId: harness.account,
      ),
    );
    final out = await sendIntents();
    expect(out.results.single.reasonCode, 'stale_source');

    await harness.client.syncStore.recordOutcome(
      mutationId: (await intents()).single.id,
      outcome: out.results.single.outcome,
      serverRejectionTime: DateTime.utc(2026, 11, 17),
      reasonCode: out.results.single.reasonCode,
    );

    expect(await intents(), isEmpty);
    final rejected = await harness.client.syncStore.rejectedMutations(scope);
    expect(
      rejected.where((m) => m.entityId == intent.operationId).single.reasonCode,
      'stale_source',
    );
    expect(
      await harness.clientRepository.promotionIntentRepository
          .pendingForAssignment(contestId, slot.assignmentId),
      isNull,
    );
    // The adoption was never written locally.
    expect(await clientOfficials(), isEmpty);
  });
}
