import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

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

void main() => forEachBackend(_tests);

/// The `promote_score` operation: an installation asks the service to adopt a
/// stored participant submission, guarded by its source and score revision.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;
  late core.ContestScopeKey scope;
  late core.ScorePlaceholder slot;
  late core.ScoreAttempt source;
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
    slot = (await harness.server.stores.of('ScorePlaceholder').all())
        .cast<core.ScorePlaceholder>()
        .firstWhere(
          (p) =>
              p.contestId == contestId &&
              p.state == core.ScorePlaceholderState.submitted,
        );
    source = (await harness.server.stores.of('ScoreAttempt').all())
        .cast<core.ScoreAttempt>()
        .firstWhere((a) => a.id == slot.currentAttemptId);
  });
  tearDown(() => harness.close());

  SyncMutation intent({
    core.ScorePlaceholder? placeholder,
    core.Id? sourceId,
    int? expected,
    String? clientMutationId,
    core.Id? operationId,
    int operationVersion = 1,
    String operation = core.SyncCapabilities.promoteScore,
    core.Authority authority = core.Authority.director,
  }) {
    final p = placeholder ?? slot;
    return SyncMutation(
      id: core.Id.create(),
      clientMutationId: clientMutationId ?? 'promote-${seq++}',
      entityType: core.promotionReceiptEntityType,
      entityId: operationId ?? core.Id.create(),
      authority: authority,
      clientTime: DateTime.utc(2026, 11, 16),
      payload: {
        'version': 1,
        'data': {
          'operation': operation,
          'operation_version': operationVersion,
          'assignment_id': p.assignmentId.value,
          'source_attempt_id': (sourceId ?? p.currentAttemptId!).value,
          'expected_score_revision': expected ?? p.scoreRevision,
        },
      },
    );
  }

  Future<List<core.ScorePlaceholder>> storedSlots() async =>
      (await harness.server.stores.of('ScorePlaceholder').all())
          .cast<core.ScorePlaceholder>()
          .where(
            (p) =>
                p.contestId == contestId &&
                p.state == core.ScorePlaceholderState.submitted,
          )
          .toList();

  Future<SyncExchangeOutput> send(SyncMutation m, {int after = 0}) =>
      harness.exchange(scope, mutations: [m], after: after);

  Future<List<core.OfficialScore>> officials() async =>
      (await harness.server.stores.of('OfficialScore').all())
          .cast<core.OfficialScore>()
          .where((o) => o.scorePlaceholderId == slot.id)
          .toList();

  Future<core.ScorePlaceholder> storedSlot() async =>
      (await harness.server.stores.of('ScorePlaceholder').find(slot.id))!
          as core.ScorePlaceholder;

  test('the service lists the capability', () {
    expect(harness.service.capabilities, [core.SyncCapabilities.promoteScore]);
  });

  test(
    'adopts exactly the source once, as one aggregate with its receipt',
    () async {
      final m = intent();
      final out = await send(m);

      expect(out.results.single.outcome, core.MutationOutcome.accepted);
      expect(out.results.single.replayed, isFalse);
      final official = await officials();
      expect(official, hasLength(1));
      expect(official.single.scoreAttemptId, source.id);
      expect(official.single.selectionOrigin, core.SelectionOrigin.manual);
      expect(official.single.setBy, harness.account);
      expect((await storedSlot()).state, core.ScorePlaceholderState.official);

      final group = out.changes.where((c) => c.aggregateId != null).toList();
      expect(
        group.map((c) => c.entityType),
        containsAll([
          'OfficialScore',
          'ScorePlaceholder',
          core.promotionReceiptEntityType,
        ]),
      );
      expect({for (final c in group) c.aggregateId}, hasLength(1));
      expect(group.last.entityType, core.promotionReceiptEntityType);
      expect(group.last.entityId, m.entityId);
      expect(group.last.sequence, out.results.single.sequence);
      expect(group.last.payload['official_score_id'], official.single.id.value);
    },
  );

  test(
    'confirming an automatic score closes review with its receipt',
    () async {
      // The contest accepted the submission on its own.
      final accepted = core.OfficialScore(
        id: core.Id.create(),
        contestId: contestId,
        scorePlaceholderId: slot.id,
        scoreAttemptId: source.id,
        scoreRevision: slot.scoreRevision + 1,
        components: source.rawComponents,
        setAt: DateTime.utc(2026, 11, 16, 12),
        reason: core.automaticRoundCompleteReason,
        selectionOrigin: core.SelectionOrigin.automatic,
      );
      await harness.serverRepository.officialScoreRepository.recordPromotion(
        core.PromotedScore(
          officialScore: accepted,
          placeholder: core.ScorePlaceholder(
            id: slot.id,
            contestId: contestId,
            contestParticipationId: slot.contestParticipationId,
            assignmentId: slot.assignmentId,
            state: core.ScorePlaceholderState.official,
            scoreRevision: accepted.scoreRevision,
            currentAttemptId: source.id,
            revision: (await storedSlot()).revision,
          ),
        ),
        metadata: core.MutationMetadata(
          clientMutationId: 'auto-1',
          authority: core.Authority.system,
          clientTime: DateTime.utc(2026, 11, 16, 12),
        ),
      );

      final m = intent(expected: slot.scoreRevision);
      final out = await send(m);

      expect(out.results.single.outcome, core.MutationOutcome.accepted);
      expect(out.results.single.replayed, isFalse);
      final stored = await storedSlot();
      expect(stored.reviewClosedScoreRevision, accepted.scoreRevision);
      expect(stored.isReviewClosed(accepted), isTrue);
      // No second official version.
      expect(await officials(), hasLength(1));

      final again = (await send(m)).results.single;
      expect(again.outcome, core.MutationOutcome.accepted);
      expect(again.replayed, isTrue);
      expect(await officials(), hasLength(1));
    },
  );

  test('a retried intent writes nothing and answers replayed', () async {
    final m = intent();
    await send(m);
    final records = await harness.serverMutationCount();

    final again = (await send(m)).results.single;

    expect(again.reasonCode, isNull);
    expect(again.outcome, core.MutationOutcome.accepted);
    expect(again.replayed, isTrue);
    expect(await officials(), hasLength(1));
    expect(await harness.serverMutationCount(), records);
  });

  test(
    'another score first: the whole intent is stale_source and final',
    () async {
      // The director enters B on the slot before the intent arrives.
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
          clientTime: DateTime.utc(2026, 11, 16),
          actorId: harness.account,
        ),
      );
      final before = await storedSlot();
      final officialBefore = await officials();
      final m = intent();

      final result = (await send(m)).results.single;

      expect(result.outcome, core.MutationOutcome.rejected);
      expect(result.reasonCode, 'stale_source');
      final after = await storedSlot();
      expect(after.scoreRevision, before.scoreRevision);
      expect(after.currentAttemptId, before.currentAttemptId);
      expect(await officials(), hasLength(officialBefore.length));

      final retry = (await send(m)).results.single;
      expect(retry.outcome, core.MutationOutcome.rejected);
      expect(retry.reasonCode, 'stale_source');
      expect(retry.replayed, isTrue);
      expect(await officials(), hasLength(officialBefore.length));
    },
  );

  test(
    'an accepted intent answers stale once something newer is current',
    () async {
      final m = intent();
      await send(m);
      final current = await storedSlot();
      await ScoresService(harness.serverRepository).enterOfficialScore(
        contestId,
        slot.assignmentId,
        clientMutationId: 'director-after',
        baseScoreRevision: current.scoreRevision,
        reason: 'director_correction',
        components: const {
          'time_flown': 300,
          'launch_height': 100,
          'landing': 'points_50',
        },
        actorId: harness.account,
        metadata: core.MutationMetadata(
          clientMutationId: 'director-after',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 11, 16),
          actorId: harness.account,
        ),
      );
      final count = (await officials()).length;

      final result = (await send(m)).results.single;

      expect(result.outcome, core.MutationOutcome.rejected);
      expect(result.reasonCode, 'stale_source');
      expect(await officials(), hasLength(count));
    },
  );

  test('the same client mutation id with another payload is refused', () async {
    final m = intent(clientMutationId: 'same-id');
    await send(m);
    final other = intent(clientMutationId: 'same-id', expected: 99);

    final result = (await send(other)).results.single;

    expect(result.outcome, core.MutationOutcome.rejected);
    expect(result.reasonCode, 'operation_mismatch');
    expect(await officials(), hasLength(1));
  });

  test(
    'an unknown operation or version is refused and writes nothing',
    () async {
      final newer = (await send(intent(operationVersion: 2))).results.single;
      final other = (await send(intent(operation: 'demote_score')))
          .results
          .single;

      expect(newer.reasonCode, 'unsupported_operation');
      expect(other.reasonCode, 'unsupported_operation');
      expect(await officials(), isEmpty);
    },
  );

  test('a mismatched source or a malformed intent is refused', () async {
    final wrong = (await send(intent(sourceId: core.Id.create())))
        .results
        .single;
    expect(wrong.outcome, core.MutationOutcome.rejected);
    expect(wrong.reasonCode, anyOf('stale_source', 'invalid_payload'));

    final bad = intent();
    final broken = SyncMutation(
      id: bad.id,
      clientMutationId: 'broken',
      entityType: bad.entityType,
      entityId: bad.entityId,
      authority: bad.authority,
      clientTime: bad.clientTime,
      payload: {
        'version': 1,
        'data': {
          'operation': core.SyncCapabilities.promoteScore,
          'operation_version': 1,
        },
      },
    );
    expect((await send(broken)).results.single.reasonCode, 'invalid_payload');
    expect(await officials(), isEmpty);
  });

  test(
    'an installation that does not administer the contest is refused',
    () async {
      await harness.register(harness.installationB, 'Tablet');
      final out = await harness.exchange(
        scope,
        mutations: [intent()],
        installation: harness.installationB,
      );

      expect(out.results.single.reasonCode, 'inactive_installation');
      expect(await officials(), isEmpty);
    },
  );

  test('a locked score is refused with locked', () async {
    final locked = core.ScorePlaceholder(
      id: slot.id,
      contestId: slot.contestId,
      contestParticipationId: slot.contestParticipationId,
      assignmentId: slot.assignmentId,
      state: slot.state,
      scoreRevision: slot.scoreRevision,
      currentAttemptId: slot.currentAttemptId,
      lockedBy: harness.account,
      lockedAt: DateTime.utc(2026, 11, 16),
      revision: slot.revision,
    );
    await harness.server.stores
        .of('ScorePlaceholder')
        .upsertJson(
          harness.server.stores.of('ScorePlaceholder').encode(locked),
        );

    final result = (await send(intent())).results.single;

    expect(result.outcome, core.MutationOutcome.rejected);
    expect(result.reasonCode, 'locked');
    expect(await officials(), isEmpty);
  });

  Future<SyncExchangeOutput> sendVia(
    SyncAcceptorService service,
    SyncMutation m,
  ) => service.exchange(
    accountId: harness.account,
    input: SyncExchangeInput(
      protocolVersion: 1,
      schemaVersion: 1,
      installationId: harness.installationA,
      scope: scope,
      lastAcknowledgedSequence: 0,
      mutations: [m],
    ),
  );

  test(
    'an operation id is bound to its first payload, whatever the request',
    () async {
      final operationId = core.Id.create();
      await send(intent(operationId: operationId));
      final other = (await storedSlots()).firstWhere((p) => p.id != slot.id);

      final result = (await send(
        intent(operationId: operationId, placeholder: other),
      )).results.single;

      expect(result.outcome, core.MutationOutcome.rejected);
      expect(result.reasonCode, 'operation_mismatch');
      expect(await officials(), hasLength(1));
      expect(
        (await harness.server.stores.of('OfficialScore').all())
            .cast<core.OfficialScore>()
            .where((o) => o.scorePlaceholderId == other.id),
        isEmpty,
      );
    },
  );

  test('the same operation sent under a new request id replays', () async {
    final operationId = core.Id.create();
    await send(intent(operationId: operationId));
    final records = await harness.serverMutationCount();

    final again = (await send(intent(operationId: operationId))).results.single;

    expect(again.outcome, core.MutationOutcome.accepted);
    expect(again.replayed, isTrue);
    expect(await harness.serverMutationCount(), records);
    expect(await officials(), hasLength(1));
  });

  test('a replay does not recalculate the results', () async {
    final counting = _CountingRecalculation(
      ResultsService(harness.serverRepository),
    );
    final service = SyncAcceptorService(
      harness.serverRepository,
      versions: const SyncVersions.exactly(1),
      recalculation: counting,
    );
    final m = intent();

    await sendVia(service, m);
    expect(counting.runs, 1);
    await sendVia(service, m);
    expect(counting.runs, 1);
  });

  test(
    'a retry that races the first answers from the recorded receipt',
    () async {
      final second = SyncAcceptorService(
        harness.serverRepository,
        versions: const SyncVersions.exactly(1),
      );
      final m = intent();

      final results = await Future.wait([
        sendVia(harness.service, m),
        sendVia(second, m),
      ]);

      for (final out in results) {
        expect(out.results.single.outcome, core.MutationOutcome.accepted);
      }
      expect(await officials(), hasLength(1));
      expect(
        (await harness.server.stores.of('OfficialScore').all()).length,
        greaterThan(0),
      );
    },
  );

  test(
    'a slot another route already adopted gets its own receipt once',
    () async {
      await ScoresService(harness.serverRepository).promoteSubmission(
        contestId,
        slot.assignmentId,
        sourceAttemptId: source.id,
        expectedScoreRevision: slot.scoreRevision,
        actorId: harness.account,
        metadata: core.MutationMetadata(
          clientMutationId: 'route-promote',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 11, 16),
          actorId: harness.account,
        ),
      );
      final m = intent();

      final first = (await send(m)).results.single;
      final again = (await send(m)).results.single;

      expect(first.outcome, core.MutationOutcome.accepted);
      expect(again.outcome, core.MutationOutcome.accepted);
      expect(again.sequence, first.sequence);
      expect(await officials(), hasLength(1));
    },
  );

  test('an aggregate is never split across pages', () async {
    await harness.close();
    harness = await AcceptorHarness.open(backend, pageSize: 1);
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
    final first = await send(intent());
    final cursor = first.serverSequence;
    // Pull everything again from before the adoption, one record per page.
    var after = cursor - 4;
    final pages = <List<AcceptedChange>>[];
    String? token;
    do {
      final page = await harness.exchange(
        scope,
        after: after,
        pageToken: token,
      );
      pages.add(page.changes);
      token = page.nextPageToken;
    } while (token != null);

    final carrying = pages.where((p) => p.any((c) => c.aggregateId != null));
    expect(carrying, hasLength(1));
    expect(
      carrying.single.map((c) => c.entityType),
      containsAll(['OfficialScore', 'ScorePlaceholder']),
    );
  });
}
