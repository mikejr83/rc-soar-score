import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// Scores entered offline, and what the service holds against them.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;
  late core.ContestScopeKey scope;
  late core.Id slot;

  setUp(() async {
    harness = await AcceptorHarness.open(backend);
    contestId = await harness.drawContestOnClient();
    scope = core.ContestScopeKey(contestId);
    await harness.uploadAll(contestId);
    final matrix = await MatrixService(harness.clientRepository)
        .current(contestId);
    final first = matrix.rounds.firstWhere((round) => round.ordinal == 1);
    slot = matrix.assignments
        .firstWhere((assignment) => assignment.scheduledRoundId == first.id)
        .id;
  });
  tearDown(() => harness.close());

  /// Enters the first score on the client, as the director.
  Future<void> enterScore() =>
      ScoresService(harness.clientRepository).enterOfficialScore(
        contestId,
        slot,
        clientMutationId: 'entry-1',
        baseScoreRevision: 0,
        components: const {
          'time_flown': 540,
          'launch_height': 200,
          'landing': 'points_50',
        },
        actorId: harness.account,
        metadata: core.MutationMetadata(
          clientMutationId: 'entry-1',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 10, 14),
          actorId: harness.account,
        ),
      );

  test('a score entered offline reaches the server with its history', () async {
    await enterScore();
    final sent = await harness.outbox(scope);

    final out = await harness.exchange(scope, mutations: sent);

    expect(
      out.results.map((r) => r.outcome),
      everyElement(core.MutationOutcome.accepted),
    );
    expect(await harness.server.count('score_attempts'), 1);
    expect(await harness.server.count('official_scores'), 1);
    final placeholder =
        (await harness.server.stores.of('ScorePlaceholder').all())
            .cast<core.ScorePlaceholder>()
            .firstWhere((p) => p.assignmentId == slot);
    expect(placeholder.state, core.ScorePlaceholderState.official);
    expect(placeholder.scoreRevision, 1);
    final contest = await harness.stored('Contest', contestId);
    expect(contest!['lifecycle_state'], 'Running');
  });

  test(
    'the outbox sends the attempt before the official score taken from it',
    () async {
      await enterScore();

      final sent = await harness.outbox(scope);

      final types = sent.map((m) => m.entityType).toList();
      expect(
        types.indexOf('ScoreAttempt'),
        lessThan(types.indexOf('OfficialScore')),
      );
    },
  );

  test('an official score for an attempt the service lacks is rejected with the reason', () async {
    await enterScore();
    final sent = await harness.outbox(scope);
    await harness.exchange(scope, mutations: sent);
    final official =
        (await harness.server.stores.of('OfficialScore').all()).single
            as core.OfficialScore;

    final out = await harness.exchange(
      scope,
      mutations: [
        harness.save('OfficialScore', {
          ...official.toJson(),
          'id': core.Id.create().value,
          'score_attempt_id': core.Id.create().value,
        }),
      ],
    );

    expect(out.results.single.reasonCode, 'invalid_payload');
  });

  test('a score for a group or matrix the service lacks is rejected with the reason', () async {
    await enterScore();
    final sent = await harness.outbox(scope);
    await harness.exchange(scope, mutations: sent);
    final attempt =
        (await harness.server.stores.of('ScoreAttempt').all()).single
            as core.ScoreAttempt;

    final out = await harness.exchange(
      scope,
      mutations: [
        harness.save('ScoreAttempt', {
          ...attempt.toJson(),
          'id': core.Id.create().value,
          'score_placeholder_id': core.Id.create().value,
        }),
        harness.save('ScoreAttempt', {
          ...attempt.toJson(),
          'id': core.Id.create().value,
          'matrix_revision_id': core.Id.create().value,
        }),
      ],
    );

    expect(out.results.map((r) => r.reasonCode), [
      'unknown_flight_group',
      'unknown_matrix_revision',
    ]);
  });

  test('a locked score rejects further attempts', () async {
    await enterScore();
    await harness.exchange(scope, mutations: await harness.outbox(scope));
    final attempt =
        (await harness.server.stores.of('ScoreAttempt').all()).single
            as core.ScoreAttempt;
    final placeholder = (await harness.stored(
      'ScorePlaceholder',
      attempt.scorePlaceholderId,
    ))!;
    await harness.server.stores.of('ScorePlaceholder').upsertJson({
      ...placeholder,
      'locked_by': harness.account.value,
      'locked_at': '2026-10-14T00:00:00Z',
    });
    // The contest must be unlocked for the placeholder rule to be the reason.
    final out = await harness.exchange(
      scope,
      mutations: [
        harness.save('ScoreAttempt', {
          ...attempt.toJson(),
          'id': core.Id.create().value,
        }),
      ],
    );

    expect(out.results.single.outcome, core.MutationOutcome.rejected);
    expect(out.results.single.reasonCode, 'locked');
  });

  test("the director's later decision beats a participant's change and keeps it as a silent record", () async {
    await enterScore();
    await harness.exchange(scope, mutations: await harness.outbox(scope));
    final placeholder =
        (await harness.server.stores.of('ScorePlaceholder').all())
            .cast<core.ScorePlaceholder>()
            .firstWhere((p) => p.assignmentId == slot);
    final json = placeholder.toJson();
    // A participant's submission lands on the server after the director's
    // base revision.
    await harness.serverRepository.syncAcceptorStore.transaction((tx) async {
      final next = {
        ...json,
        'revision': placeholder.revision + 1,
        'state': 'Submitted',
      };
      await tx.writeEntity('ScorePlaceholder', next);
      final sequence = await tx.highestSequence(scope) + 1;
      await tx.recordMutation(
        core.MutationRecord(
          id: core.Id.create(),
          contestId: contestId,
          sequence: sequence,
          entityType: 'ScorePlaceholder',
          entityId: placeholder.id,
          clientMutationId: 'participant-1',
          authority: core.Authority.participant,
          clientTime: DateTime.utc(2026, 10, 14),
          payload: MutationPayload.save(next).toJson(),
          outcome: core.MutationOutcome.accepted,
        ),
      );
    });

    final out = await harness.exchange(
      scope,
      mutations: [
        harness.save('ScorePlaceholder', {
          ...json,
          'state': 'Official',
          'score_revision': 2,
        }, base: placeholder.revision),
      ],
    );

    expect(out.results.single.outcome, core.MutationOutcome.accepted);
    expect(out.results.single.revision, placeholder.revision + 2);
    final stored = await harness.stored('ScorePlaceholder', placeholder.id);
    expect(stored!['state'], 'Official');
    final silent = out.changes.lastWhere(
      (c) => c.entityType == 'ConflictRecord',
    );
    expect(silent.payload['requires_action'], isFalse);
    expect(silent.payload['reason_code'], 'director_over_participant');
    expect(silent.payload['resolution'], 'Automatic');
    expect(out.conflicts.single.requiresAction, isFalse);
    expect(
      await harness.serverRepository.syncAcceptorStore.transaction(
        (tx) async => (await tx.conflictsNeedingAction(scope)),
      ),
      isEmpty,
    );
  });
}
