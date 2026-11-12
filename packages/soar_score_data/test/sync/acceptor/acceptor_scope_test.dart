import 'package:soar_score_core/services/services.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';
import '../../support/drawn_contest.dart';

void main() => forEachBackend(_tests);

/// Nothing a mutation or a conflict decision writes, or refers to, may belong
/// to another scope.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;
  late core.ContestScopeKey scope;
  late core.Id otherId;
  late core.ContestScopeKey otherScope;

  setUp(() async {
    harness = await AcceptorHarness.open(backend);
    contestId = await harness.drawContestOnClient();
    scope = core.ContestScopeKey(contestId);
    await harness.uploadAll(contestId);
    otherId = await drawnContest(
      harness.clientRepository,
      harness.account,
      mutationPrefix: 'other',
      name: 'Other Open',
    );
    otherScope = core.ContestScopeKey(otherId);
    for (final s in [core.DirectorScopeKey(harness.account), otherScope]) {
      final sent = await harness.outbox(s);
      final out = await harness.exchange(s, mutations: sent);
      await harness.acknowledge(sent, out.results);
    }
  });
  tearDown(() => harness.close());

  Future<Map<String, Object?>> first(String type, core.Id contest) async {
    final rows = await harness.server.stores
        .of(type)
        .whereIdJson('contest_id', contest);
    return rows.first;
  }

  /// What a refused write must not change.
  Future<List<Object?>> footprint() async => [
    await harness.server.count('mutation_records'),
    await harness.server.count('conflict_records'),
    await harness.server.count('audit_events'),
    await harness.serverRepository.syncAcceptorStore.transaction(
      (tx) async => [
        await tx.highestSequence(scope),
        await tx.highestSequence(otherScope),
      ],
    ),
  ];

  group('deciding a conflict', () {
    late Map<String, Object?> round;
    late core.Id conflictId;

    Map<String, Object?> grouped(int count, {Map<String, Object?>? extra}) => {
      ...round,
      'group_count': count,
      ...?extra,
    };

    setUp(() async {
      round = await first('Round', contestId);
      final base = round['revision']! as int;
      await harness.exchange(
        scope,
        mutations: [harness.save('Round', grouped(3), base: base)],
      );
      final out = await harness.exchange(
        scope,
        mutations: [harness.save('Round', grouped(4), base: base)],
      );
      conflictId = out.conflicts.single.id;
    });

    Future<core.MutationResult> resolve(
      Map<String, Object?> payload, {
      core.ConflictResolutionChoice choice =
          core.ConflictResolutionChoice.merged,
    }) => harness.service.resolveConflict(
      accountId: harness.account,
      conflictId: conflictId,
      clientMutationId: 'decide-${payload.hashCode}',
      choice: choice,
      payload: payload,
    );

    Future<void> expectRefused(
      Map<String, Object?> payload,
      String reason,
    ) async {
      final before = await footprint();
      final result = await resolve(payload);

      expect(result.outcome, core.MutationOutcome.rejected);
      expect(result.reasonCode, reason);
      expect(await footprint(), before);
      final conflict = await harness.serverRepository.syncAcceptorStore
          .transaction((tx) => tx.findConflict(conflictId));
      expect(conflict!.resolution, core.ConflictResolution.pending);
      expect(
        (await harness.stored(
          'Round',
          core.Id.parse(round['id']! as String),
        ))!['group_count'],
        3,
      );
    }

    test('a merged value inside the scope is stored', () async {
      final result = await resolve(grouped(5));

      expect(result.outcome, core.MutationOutcome.accepted);
      final stored = await harness.stored(
        'Round',
        core.Id.parse(round['id']! as String),
      );
      expect(stored!['group_count'], 5);
    });

    test('taking the competing value still succeeds', () async {
      final result = await resolve(
        const {},
        choice: core.ConflictResolutionChoice.tookCompeting,
      );

      expect(result.outcome, core.MutationOutcome.accepted);
    });

    test('a merged value with another id is refused', () async {
      await expectRefused(
        grouped(5, extra: {'id': core.Id.create().value}),
        'invalid_payload',
      );
    });

    test('a merged value with another id of the same type in another contest '
        'is refused', () async {
      final foreign = await first('Round', otherId);
      await expectRefused({...foreign, 'group_count': 5}, 'invalid_payload');
    });

    test('a merged value moved to another contest is refused', () async {
      await expectRefused(
        grouped(5, extra: {'contest_id': otherId.value}),
        'unauthorized',
      );
    });

    test('a merged value that refers to another contest is refused', () async {
      final foreign = await first('MatrixRevision', otherId);
      await expectRefused(
        grouped(5, extra: {'matrix_revision_id': foreign['id']}),
        'unauthorized',
      );
    });
  });

  group('referenced rows', () {
    test(
      'a score of this contest cannot name another contest\'s slot',
      () async {
        final slot = await first('ScorePlaceholder', otherId);
        // A score attempt of this contest that points at the other slot.
        final revision = await first('MatrixRevision', contestId);
        final entity = {
          'id': core.Id.create().value,
          'contest_id': contestId.value,
          'score_placeholder_id': slot['id'],
          'matrix_revision_id': revision['id'],
        };
        final before = await footprint();
        final otherBefore = await harness.stored(
          'ScorePlaceholder',
          core.Id.parse(slot['id']! as String),
        );

        final out = await harness.exchange(
          scope,
          mutations: [harness.save('ScoreAttempt', entity)],
        );

        expect(out.results.single.outcome, core.MutationOutcome.rejected);
        expect(out.results.single.reasonCode, 'unauthorized');
        expect(out.conflicts, isEmpty);
        expect(
          await harness.stored(
            'ScorePlaceholder',
            core.Id.parse(slot['id']! as String),
          ),
          otherBefore,
        );
        expect((await footprint())[3], before[3]);
      },
    );

    test('a move cannot supersede another contest\'s assignment', () async {
      final source = await first('MatrixAssignment', otherId);
      final mine = await first('MatrixAssignment', contestId);
      final moved = {
        ...mine,
        'id': core.Id.create().value,
        'assignment_type': 'Moved',
        'source_assignment_id': source['id'],
        'reason': 'Moved',
        'created_at': '2026-10-14T16:00:00Z',
      };

      final out = await harness.exchange(
        scope,
        mutations: [
          harness.save(
            'MatrixAssignment',
            moved,
            supersedes: source['id']! as String,
          ),
        ],
      );

      expect(out.results.single.outcome, core.MutationOutcome.rejected);
      expect(out.results.single.reasonCode, 'unauthorized');
      expect(out.conflicts, isEmpty);
      final untouched = await harness.stored(
        'MatrixAssignment',
        core.Id.parse(source['id']! as String),
      );
      expect(untouched!['superseded_by_assignment_id'], isNull);
    });
  });

  group('supersession markers', () {
    late Map<String, Object?> round;
    late Map<String, Object?> assignment;
    late Map<String, Object?> foreignRound;
    late Map<String, Object?> foreignAssignment;

    setUp(() async {
      final rounds = await harness.server.stores
          .of('Round')
          .whereIdJson('contest_id', contestId);
      rounds.sort(
        (a, b) => (a['ordinal']! as int).compareTo(b['ordinal']! as int),
      );
      round = rounds.first;
      assignment = await first('MatrixAssignment', contestId);
      foreignRound = await first('Round', otherId);
      foreignAssignment = await first('MatrixAssignment', otherId);
    });

    Map<String, Object?> marked(Map<String, Object?> target) => {
      ...round,
      'superseded_by_round_id': target['id'],
    };

    Map<String, Object?> newAssignment(Map<String, Object?> target) => {
      ...assignment,
      'id': core.Id.create().value,
      'superseded_by_assignment_id': target['id'],
    };

    Future<void> expectUntouched(String type, Map<String, Object?> row) async {
      expect(
        await harness.stored(type, core.Id.parse(row['id']! as String)),
        row,
      );
    }

    test('a round marker naming another contest\'s round is refused', () async {
      // The refusal is itself recorded; nothing else changes.
      final before = (await footprint()).sublist(1);

      final out = await harness.exchange(
        scope,
        mutations: [
          harness.save(
            'Round',
            marked(foreignRound),
            base: round['revision']! as int,
          ),
        ],
      );

      expect(out.results.single.outcome, core.MutationOutcome.rejected);
      expect(out.results.single.reasonCode, 'unauthorized');
      expect(out.conflicts, isEmpty);
      expect((await footprint()).sublist(1), before);
      await expectUntouched('Round', round);
    });

    test('an assignment marker naming another contest\'s assignment is '
        'refused', () async {
      // The refusal is itself recorded; nothing else changes.
      final before = (await footprint()).sublist(1);

      final out = await harness.exchange(
        scope,
        mutations: [
          harness.save('MatrixAssignment', newAssignment(foreignAssignment)),
        ],
      );

      expect(out.results.single.outcome, core.MutationOutcome.rejected);
      expect(out.results.single.reasonCode, 'unauthorized');
      expect((await footprint()).sublist(1), before);
      await expectUntouched('MatrixAssignment', foreignAssignment);
    });

    test('a round marker naming a round of this contest is accepted', () async {
      final rounds = await harness.server.stores
          .of('Round')
          .whereIdJson('contest_id', contestId);
      final other = rounds.firstWhere((r) => r['id'] != round['id']);

      final out = await harness.exchange(
        scope,
        mutations: [
          harness.save('Round', marked(other), base: round['revision']! as int),
        ],
      );

      expect(out.results.single.outcome, core.MutationOutcome.accepted);
    });

    test('a decision that takes a foreign marker is refused', () async {
      final record =
          (await harness.serverRepository.syncAcceptorStore.transaction(
            (tx) => tx.acceptedAfter(scope, 0, limit: 1),
          )).first;
      for (final (type, entity) in [
        ('Round', marked(foreignRound)),
        ('MatrixAssignment', newAssignment(foreignAssignment)),
      ]) {
        final conflictId = core.Id.create();
        await harness.serverRepository.syncAcceptorStore.transaction(
          (tx) => tx.saveConflict(
            core.ConflictRecord(
              id: conflictId,
              contestId: contestId,
              entityType: type,
              entityId: core.Id.parse(entity['id']! as String),
              competingMutationId: record.id,
              reasonCode: 'stale_base',
              createdAt: DateTime.utc(2026, 10, 14),
              competingPayload: entity,
            ),
          ),
        );
        final before = await footprint();

        final result = await harness.service.resolveConflict(
          accountId: harness.account,
          conflictId: conflictId,
          clientMutationId: 'decide-$type',
          choice: core.ConflictResolutionChoice.tookCompeting,
        );

        expect(result.outcome, core.MutationOutcome.rejected, reason: type);
        expect(result.reasonCode, 'unauthorized', reason: type);
        expect(await footprint(), before, reason: type);
      }
      await expectUntouched('Round', round);
    });
  });

  group('score attempts', () {
    late Map<String, Object?> attempt;
    late Map<String, Object?> foreignConfig;

    setUp(() async {
      final matrix = await MatrixService(harness.clientRepository)
          .current(contestId);
      final firstRound = matrix.rounds.firstWhere(
        (round) => round.ordinal == 1,
      );
      final slot = matrix.assignments.firstWhere(
        (assignment) => assignment.scheduledRoundId == firstRound.id,
      );
      final metadata = core.MutationMetadata(
        clientMutationId: 'entry-1',
        authority: core.Authority.director,
        clientTime: DateTime.utc(2026, 10, 14),
        actorId: harness.account,
      );
      await ScoresService(harness.clientRepository).enterOfficialScore(
        contestId,
        slot.id,
        clientMutationId: 'entry-1',
        baseScoreRevision: 0,
        components: const {
          'time_flown': 540,
          'launch_height': 200,
          'landing': 'points_50',
        },
        actorId: harness.account,
        metadata: metadata,
      );
      final sent = await harness.outbox(scope);
      final mutation = sent.firstWhere((m) => m.entityType == 'ScoreAttempt');
      attempt = (MutationPayload.parse(mutation.payload).entity);
      foreignConfig = await first('ContestConfigurationRevision', otherId);
    });

    SyncMutation foreignAttempt() => harness.save('ScoreAttempt', {
      ...attempt,
      'config_revision_id': foreignConfig['id'],
    });

    test('an attempt with this contest\'s configuration is accepted', () async {
      final sent = await harness.outbox(scope);

      final out = await harness.exchange(scope, mutations: sent);

      expect(
        out.results.map((r) => r.outcome),
        everyElement(core.MutationOutcome.accepted),
      );
    });

    test(
      'an attempt with another contest\'s configuration is refused',
      () async {
        final before = await footprint();

        final out = await harness.exchange(
          scope,
          mutations: [foreignAttempt()],
        );

        expect(out.results.single.outcome, core.MutationOutcome.rejected);
        expect(out.results.single.reasonCode, 'unauthorized');
        expect(out.conflicts, isEmpty);
        expect(await harness.server.count('score_attempts'), 0);
        // Only the refusal itself is recorded; no sequence is assigned.
        expect((await footprint())[3], before[3]);
      },
    );

    test('an installation that does not administer the contest learns '
        'nothing about the reference', () async {
      await harness.register(harness.installationB, 'Tablet');

      final out = await harness.exchange(
        scope,
        installation: harness.installationB,
        mutations: [foreignAttempt()],
      );

      expect(out.results.single.outcome, core.MutationOutcome.rejected);
      expect(out.results.single.reasonCode, 'inactive_installation');
    });

    test('a decision that takes an attempt with another contest\'s '
        'configuration is refused', () async {
      final mutation = foreignAttempt();
      final conflictId = core.Id.create();
      late core.MutationRecord anyRecord;
      await harness.serverRepository.syncAcceptorStore.transaction((tx) async {
        anyRecord = (await tx.acceptedAfter(scope, 0, limit: 1)).first;
        await tx.saveConflict(
          core.ConflictRecord(
            id: conflictId,
            contestId: contestId,
            entityType: 'ScoreAttempt',
            entityId: mutation.entityId,
            competingMutationId: anyRecord.id,
            reasonCode: 'stale_base',
            createdAt: DateTime.utc(2026, 10, 14),
            competingPayload: {
              ...attempt,
              'config_revision_id': foreignConfig['id'],
            },
          ),
        );
      });
      final before = await footprint();

      final result = await harness.service.resolveConflict(
        accountId: harness.account,
        conflictId: conflictId,
        clientMutationId: 'decide-attempt',
        choice: core.ConflictResolutionChoice.tookCompeting,
      );

      expect(result.outcome, core.MutationOutcome.rejected);
      expect(result.reasonCode, 'unauthorized');
      expect(await footprint(), before);
      expect(await harness.server.count('score_attempts'), 0);
    });
  });
}
