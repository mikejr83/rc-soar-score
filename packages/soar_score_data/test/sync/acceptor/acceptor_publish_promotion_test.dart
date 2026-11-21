import 'dart:async';

import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';
import '../../support/overlap_support.dart';

void main() => forEachBackend(_tests);

/// A native Mark official reaches the server as a `ScorePromotion` intent
/// whose official score the server writes itself, so the incoming entity
/// types alone do not show the score change.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;
  late core.ContestScopeKey scope;
  late core.ScorePlaceholder slot;

  Future<void> open(
    core.PublicUpdateMode mode, {
    RecalculationService Function(Repository server)? recalculation,
  }) async {
    harness = await AcceptorHarness.open(
      backend,
      recalculates: true,
      publishes: true,
      recalculation: recalculation,
    );
    await DemoDataSeeder(
      harness.clientRepository,
      localAccountId: harness.account,
    ).seed();
    final contest = (await harness.clientRepository.contestRepository.getAll())
        .firstWhere((c) => c.name == 'Mountain States Team F5J');
    contestId = contest.id;
    scope = core.ContestScopeKey(contestId);
    await harness.uploadAll(contestId);
    final stored = (await harness.serverRepository.contestRepository.findById(
      contestId,
    ))!;
    await PublicationService(harness.serverRepository).publish(
      contestId,
      actorId: harness.account,
      authority: core.Authority.director,
      clientMutationId: 'first',
      sourceContestRevision: stored.revision,
    );
    // Automatic mode, so the round the slot belongs to does not matter.
    final latest = (await harness
        .clientRepository
        .contestConfigurationRevisionRepository
        .latestForContest(contestId))!;
    await ContestConfigurationService(harness.clientRepository).save(
      contestId,
      ConfigurationInput(
        baseRevisionNumber: latest.revisionNumber,
        disciplineProfileId: latest.disciplineProfileId,
        config: core.ContestConfig(
          core: {...latest.config.core, 'public_update_mode': mode.json},
          discipline: latest.config.discipline,
        ),
      ),
      createdBy: harness.account,
      metadata: core.MutationMetadata(
        clientMutationId: 'mode-automatic',
        authority: core.Authority.director,
        clientTime: DateTime.utc(2026, 11, 16),
        actorId: harness.account,
      ),
    );
    final sent = await harness.outbox(scope);
    final out = await harness.exchange(scope, mutations: sent);
    await harness.acknowledge(sent, out.results);
    slot = (await harness.server.stores.of('ScorePlaceholder').all())
        .cast<core.ScorePlaceholder>()
        .firstWhere(
          (p) =>
              p.contestId == contestId &&
              p.state == core.ScorePlaceholderState.submitted,
        );
  }

  tearDown(() async {
    try {
      await harness.close();
    } on Object {
      // the test never opened a harness
    }
  });

  Future<List<core.PublicationProjection>> projections() async {
    final identity = (await harness
        .serverRepository
        .publicationIdentityRepository
        .findForContest(contestId))!;
    return harness.serverRepository.publicationProjectionRepository
        .listForPublication(identity.id);
  }

  SyncMutation intent() => SyncMutation(
    id: core.Id.create(),
    clientMutationId: 'promote-1',
    entityType: core.promotionReceiptEntityType,
    entityId: core.Id.parse('01900000-0000-7000-8000-000000000001'),
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

  test(
    'a promotion-only exchange republishes once; its replay does not',
    () async {
      await open(core.PublicUpdateMode.automatic);
      final before = (await projections()).length;
      final m = intent();

      final first = await harness.exchange(scope, mutations: [m]);
      expect(first.results.single.outcome, core.MutationOutcome.accepted);
      final afterFirst = await projections();
      expect(afterFirst, hasLength(before + 1));
      final latest = afterFirst.reduce(
        (a, b) => a.projectionRevision > b.projectionRevision ? a : b,
      );
      final earlier = afterFirst.firstWhere(
        (p) => p.projectionRevision == latest.projectionRevision - 1,
      );
      // The official score the server wrote is in the new projection only.
      expect(latest.standings, isNot(equals(earlier.standings)));

      final replay = await harness.exchange(scope, mutations: [m]);
      expect(replay.results.single.replayed, isTrue);
      expect(await projections(), hasLength(before + 1));
    },
  );

  test('a refused promotion publishes nothing', () async {
    await open(core.PublicUpdateMode.automatic);
    final before = (await projections()).length;
    final stale = SyncMutation(
      id: core.Id.create(),
      clientMutationId: 'promote-stale',
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
          'expected_score_revision': slot.scoreRevision + 5,
        },
      },
    );

    final out = await harness.exchange(scope, mutations: [stale]);

    expect(out.results.single.outcome, isNot(core.MutationOutcome.accepted));
    expect(await projections(), hasLength(before));
  });

  test(
    'an unpublished hosted title edit does not ride on a later promotion',
    () async {
      await open(core.PublicUpdateMode.roundCompletion);
      final before = (await projections()).length;
      final hosted = (await harness.serverRepository.contestRepository.findById(
        contestId,
      ))!;
      await ContestsService(harness.serverRepository).updateContest(
        contestId,
        ContestDetails(
          name: 'Hosted Rename',
          host: hosted.host,
          city: hosted.city,
          state: hosted.state,
          country: hosted.country,
          startDateTime: hosted.startDateTime,
          endDateTime: hosted.endDateTime,
        ),
        baseRevision: hosted.revision,
        metadata: core.MutationMetadata(
          clientMutationId: 'hosted-rename',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 11, 16),
          actorId: harness.account,
        ),
      );

      await harness.exchange(scope, mutations: [intent()]);

      expect(await projections(), hasLength(before));
    },
  );

  test('a hosted title edit made while the promotion exchange runs is not '
      'its change', () async {
    late _GatedRecalculation gated;
    await open(
      core.PublicUpdateMode.roundCompletion,
      recalculation: (server) =>
          gated = _GatedRecalculation(ResultsService(server)),
    );
    final before = (await projections()).length;
    gated.armed = true;

    Future<SyncExchangeOutput>? exchange;
    late final SyncExchangeOutput out;
    try {
      final started = exchange = harness.exchange(scope, mutations: [intent()])
        ..ignore();
      await readyOrDone(gated.reached.future, started);
      final hosted = (await harness.serverRepository.contestRepository.findById(
        contestId,
      ))!;
      await ContestsService(harness.serverRepository).updateContest(
        contestId,
        ContestDetails(
          name: 'Hosted Rename Mid Exchange',
          host: hosted.host,
          city: hosted.city,
          state: hosted.state,
          country: hosted.country,
          startDateTime: hosted.startDateTime,
          endDateTime: hosted.endDateTime,
        ),
        baseRevision: hosted.revision,
        metadata: core.MutationMetadata(
          clientMutationId: 'hosted-rename-mid',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 11, 16),
          actorId: harness.account,
        ),
      );
      gated.release.complete();
      out = await started;
    } finally {
      // Whatever failed above, let the exchange end before teardown; the
      // original failure is the one reported.
      await settleStarted([gated.release], [exchange]);
    }

    expect(out.results.single.outcome, core.MutationOutcome.accepted);
    expect(await projections(), hasLength(before));
  });
}

/// Pauses the recalculation that follows the exchange's accepted changes.
class _GatedRecalculation extends RecalculationService {
  _GatedRecalculation(super.results);

  var armed = false;
  final reached = Completer<void>();
  final release = Completer<void>();

  @override
  Future<String?> recalculateAfterEntry(
    core.Id contestId, {
    String cause = 'a score entry',
  }) async {
    if (armed) {
      armed = false;
      reached.complete();
      await release.future;
    }
    return super.recalculateAfterEntry(contestId, cause: cause);
  }
}
