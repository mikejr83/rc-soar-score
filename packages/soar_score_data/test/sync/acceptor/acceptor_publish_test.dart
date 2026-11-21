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

  Future<core.PublicationProjection> currentProjection() async {
    final identity = (await harness
        .serverRepository
        .publicationIdentityRepository
        .findForContest(contestId))!;
    return (await harness.serverRepository.publicationProjectionRepository
        .findById(identity.currentProjectionId!))!;
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

  test('a reused mutation id after a configuration change does not hide '
      'the change', () async {
    await setUp0(publishes: true);
    addTearDown(harness.close);
    final before = await projectionRevision();
    final configBefore = await publishedConfigRevision();
    await _saveConfig(
      harness,
      contestId,
      base: configBefore,
      options: {
        'drop_after_rounds': [1],
      },
    );
    final sent = await harness.outbox(scope);
    final config = sent.firstWhere(
      (m) => m.entityType == 'ContestConfigurationRevision',
    );
    // A later mutation of a type the public site does not show, under the
    // configuration change's own id: the service accepts it too, and the
    // configuration change must still be classified by its own input.
    final reused = harness.save('ReviewRequest', {
      'id': core.Id.create().value,
    }, clientMutationId: config.clientMutationId);

    final out = await harness.exchange(scope, mutations: [...sent, reused]);

    expect(
      out.results.every((r) => r.outcome == core.MutationOutcome.accepted),
      isTrue,
    );
    expect(await projectionRevision(), before + 1);
    expect(await publishedConfigRevision(), configBefore + 1);
  });

  test('a replay of an earlier configuration beside a fresh one does not '
      'hide the fresh one', () async {
    await setUp0(publishes: true);
    addTearDown(harness.close);
    final base = await publishedConfigRevision();
    await _saveConfig(
      harness,
      contestId,
      base: base,
      options: {
        'drop_after_rounds': [1],
      },
    );
    final first = await harness.outbox(scope);
    final firstOut = await harness.exchange(scope, mutations: first);
    await harness.acknowledge(first, firstOut.results);
    final afterFirst = await projectionRevision();
    expect(await publishedConfigRevision(), base + 1);

    await _saveConfig(
      harness,
      contestId,
      base: base + 1,
      options: {
        'drop_after_rounds': [2],
      },
    );
    final fresh = await harness.outbox(scope);

    // The fresh configuration, then the earlier exchange sent again.
    final out = await harness.exchange(scope, mutations: [...fresh, ...first]);

    expect(out.results.take(fresh.length).every((r) => !r.replayed), isTrue);
    expect(out.results.skip(fresh.length).every((r) => r.replayed), isTrue);
    expect(await projectionRevision(), afterFirst + 1);
    expect(await publishedConfigRevision(), base + 2);
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

    test('a name edit in the same exchange as a partial-round score '
        'publishes the name', () async {
      final before = await projectionRevision();
      final contest = (await harness.clientRepository.contestRepository
          .findById(contestId))!;
      await ContestsService(harness.clientRepository).updateContest(
        contestId,
        ContestDetails(
          name: 'Renamed Open',
          host: contest.host,
          city: contest.city,
          startDateTime: contest.startDateTime,
          endDateTime: contest.endDateTime,
        ),
        baseRevision: contest.revision,
        metadata: core.MutationMetadata(
          clientMutationId: 'rename-${_mutations++}',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 10, 15),
          actorId: harness.account,
        ),
      );

      await syncScores(rounds[0].take(1));

      expect(await projectionRevision(), before + 1);
      expect(
        await currentProjection().then((p) => p.contestIdentity['name']),
        'Renamed Open',
      );
    });

    test('an unpublished hosted title edit does not ride on a later partial '
        'round score', () async {
      final before = await projectionRevision();
      // A direct write on the server (the REST route does not republish).
      final hosted = (await harness.serverRepository.contestRepository.findById(
        contestId,
      ))!;
      await ContestsService(harness.serverRepository).updateContest(
        contestId,
        ContestDetails(
          name: 'Hosted Rename',
          host: hosted.host,
          city: hosted.city,
          startDateTime: hosted.startDateTime,
          endDateTime: hosted.endDateTime,
        ),
        baseRevision: hosted.revision,
        metadata: core.MutationMetadata(
          clientMutationId: 'hosted-rename',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 10, 15),
          actorId: harness.account,
        ),
      );

      await syncScores(rounds[0].take(1));

      expect(await projectionRevision(), before);
    });

    test(
      'a private control after a partial-round score publishes nothing',
      () async {
        final before = await projectionRevision();

        await syncScores(rounds[0].take(1));
        expect(await projectionRevision(), before);

        for (final action in [
          core.ContestAction.openScoring,
          core.ContestAction.lock,
        ]) {
          final contest = (await harness.clientRepository.contestRepository
              .findById(contestId))!;
          await ContestsService(harness.clientRepository).applyAction(
            contestId,
            action,
            baseRevision: contest.revision,
            metadata: core.MutationMetadata(
              clientMutationId: 'control-${_mutations++}',
              authority: core.Authority.director,
              clientTime: DateTime.utc(2026, 10, 15),
              actorId: harness.account,
            ),
          );
          final sent = await harness.outbox(scope);
          final out = await harness.exchange(scope, mutations: sent);
          await harness.acknowledge(sent, out.results);
          expect(
            out.results.every(
              (r) => r.outcome == core.MutationOutcome.accepted,
            ),
            isTrue,
          );
          expect(await projectionRevision(), before);
        }
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
