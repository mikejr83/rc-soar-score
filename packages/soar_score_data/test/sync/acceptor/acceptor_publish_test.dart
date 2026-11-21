import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// A synced change reaches the public projection by the contest's public
/// update mode, so a configuration change such as dropped rounds shows on the
/// public site without a second manual publish.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;
  late core.ContestScopeKey scope;

  Future<void> setUp0({
    required bool publishes,
    core.PublicUpdateMode? mode,
  }) async {
    harness = await AcceptorHarness.open(
      backend,
      recalculates: true,
      publishes: publishes,
    );
    contestId = await harness.drawContestOnClient();
    scope = core.ContestScopeKey(contestId);
    if (mode != null) {
      await _saveConfig(
        harness,
        contestId,
        base: 1,
        options: {'public_update_mode': mode.json},
      );
    }
    await harness.uploadAll(contestId);
    // The director publishes the uploaded contest once, by hand.
    final contest = (await harness.serverRepository.contestRepository.findById(
      contestId,
    ))!;
    await PublicationService(harness.serverRepository).publish(
      contestId,
      actorId: harness.account,
      authority: core.Authority.director,
      clientMutationId: 'first',
      sourceContestRevision: contest.revision,
    );
  }

  Future<int> projectionRevision() async {
    final identity = (await harness
        .serverRepository
        .publicationIdentityRepository
        .findForContest(contestId))!;
    final current = await harness
        .serverRepository
        .publicationProjectionRepository
        .findById(identity.currentProjectionId!);
    return current!.projectionRevision;
  }

  Future<int> publishedConfigRevision() async {
    final identity = (await harness
        .serverRepository
        .publicationIdentityRepository
        .findForContest(contestId))!;
    final current = await harness
        .serverRepository
        .publicationProjectionRepository
        .findById(identity.currentProjectionId!);
    return current!.configRevision;
  }

  Future<void> syncConfigChange(int base, [core.PublicUpdateMode? mode]) async {
    await _saveConfig(
      harness,
      contestId,
      base: base,
      options: {
        'drop_after_rounds': [1],
        if (mode != null) 'public_update_mode': mode.json,
      },
    );
    final sent = await harness.outbox(scope);
    final out = await harness.exchange(scope, mutations: sent);
    await harness.acknowledge(sent, out.results);
  }

  test(
    'a synced configuration change republishes in RoundCompletion mode',
    () async {
      await setUp0(publishes: true);
      addTearDown(harness.close);
      final before = await projectionRevision();
      final configBefore = await publishedConfigRevision();

      await syncConfigChange(configBefore);

      expect(await projectionRevision(), before + 1);
      expect(await publishedConfigRevision(), configBefore + 1);
    },
  );

  test('a synced configuration change republishes in Automatic mode', () async {
    await setUp0(publishes: true, mode: core.PublicUpdateMode.automatic);
    addTearDown(harness.close);
    final before = await projectionRevision();

    await syncConfigChange(
      await publishedConfigRevision(),
      core.PublicUpdateMode.automatic,
    );

    expect(await projectionRevision(), before + 1);
  });

  test('a synced change does not republish in Manual mode', () async {
    await setUp0(publishes: true, mode: core.PublicUpdateMode.manual);
    addTearDown(harness.close);
    final before = await projectionRevision();

    await syncConfigChange(
      await publishedConfigRevision(),
      core.PublicUpdateMode.manual,
    );

    expect(await projectionRevision(), before);
  });

  group('scores in RoundCompletion mode', () {
    late List<List<core.Id>> rounds;

    setUp(() async {
      await setUp0(publishes: true);
      final matrix = await MatrixService(harness.clientRepository)
          .current(contestId);
      rounds = [
        for (final ordinal in [1, 2])
          [
            for (final a in matrix.assignments)
              if (a.scheduledRoundId ==
                  matrix.rounds.firstWhere((r) => r.ordinal == ordinal).id)
                a.id,
          ],
      ];
    });
    tearDown(() => harness.close());

    /// Enters official scores on the client and syncs them as one exchange.
    Future<void> syncScores(Iterable<core.Id> assignments) async {
      for (final id in assignments) {
        final mutation = 'score-${_mutations++}';
        await ScoresService(harness.clientRepository).enterOfficialScore(
          contestId,
          id,
          clientMutationId: mutation,
          baseScoreRevision: 0,
          components: const {
            'time_flown': 500,
            'launch_height': 200,
            'landing': 'points_50',
          },
          actorId: harness.account,
          metadata: core.MutationMetadata(
            clientMutationId: mutation,
            authority: core.Authority.director,
            clientTime: DateTime.utc(2026, 10, 15),
            actorId: harness.account,
          ),
        );
      }
      final sent = await harness.outbox(scope);
      final out = await harness.exchange(scope, mutations: sent);
      await harness.acknowledge(sent, out.results);
    }

    test(
      'a score batch in an incomplete first round publishes nothing',
      () async {
        final before = await projectionRevision();

        await syncScores(rounds[0].take(2));

        expect(await projectionRevision(), before);
      },
    );

    test('the batch that completes the round publishes', () async {
      await syncScores(rounds[0].take(2));
      final before = await projectionRevision();

      await syncScores(rounds[0].skip(2));

      expect(await projectionRevision(), before + 1);
    });

    test('a batch in an incomplete second round publishes nothing even when '
        'the first round is complete', () async {
      await syncScores(rounds[0]);
      final before = await projectionRevision();

      await syncScores(rounds[1].take(1));
      expect(await projectionRevision(), before);

      await syncScores(rounds[1].skip(1));
      expect(await projectionRevision(), before + 1);
    });
  });

  test(
    'without the update service the projection stays as published',
    () async {
      await setUp0(publishes: false);
      addTearDown(harness.close);
      final before = await projectionRevision();

      await syncConfigChange(await publishedConfigRevision());

      expect(await projectionRevision(), before);
    },
  );
}

var _mutations = 0;

Future<void> _saveConfig(
  AcceptorHarness harness,
  core.Id contestId, {
  required int base,
  required Map<String, Object?> options,
}) => ContestConfigurationService(harness.clientRepository).save(
  contestId,
  ConfigurationInput(
    baseRevisionNumber: base,
    disciplineProfileId: core.SystemDisciplineProfiles.f5jId,
    config: core.ContestConfig(
      core: options,
      discipline: const {'working_time': 600},
    ),
  ),
  createdBy: harness.account,
  metadata: core.MutationMetadata(
    clientMutationId: 'config-${_mutations++}',
    authority: core.Authority.director,
    clientTime: DateTime.utc(2026, 10, 15),
    actorId: harness.account,
  ),
);
