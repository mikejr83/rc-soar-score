import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// Edits to a contest the server already holds: fast-forward, merge, conflict
/// and the director's decision.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.Id contestId;
  late core.ContestScopeKey scope;
  late Map<String, Object?> contest;

  Map<String, Object?> renamed(String name, {String? city}) => {
    ...contest,
    'name': name,
    'city': ?city,
  };

  setUp(() async {
    harness = await AcceptorHarness.open(backend);
    contestId = await harness.drawContestOnClient();
    scope = core.ContestScopeKey(contestId);
    await harness.uploadAll(contestId);
    contest = (await harness.stored('Contest', contestId))!;
  });
  tearDown(() => harness.close());

  int revision() => contest['revision']! as int;

  test(
    'a change on the current revision is accepted as the next one',
    () async {
      final out = await harness.exchange(
        scope,
        mutations: [
          harness.save('Contest', renamed('Autumn Open'), base: revision()),
        ],
      );

      final result = out.results.single;
      expect(result.outcome, core.MutationOutcome.accepted);
      expect(result.revision, revision() + 1);
      final stored = await harness.stored('Contest', contestId);
      expect(stored!['name'], 'Autumn Open');
      expect(stored['revision'], revision() + 1);
    },
  );

  test('changes to different fields on a stale revision are merged', () async {
    await harness.exchange(
      scope,
      mutations: [
        harness.save('Contest', renamed('Autumn Open'), base: revision()),
      ],
    );

    final out = await harness.exchange(
      scope,
      mutations: [
        harness.save(
          'Contest',
          renamed('Spring Open', city: 'Boulder')..['name'] = contest['name'],
          base: revision(),
        ),
      ],
    );

    expect(out.results.single.outcome, core.MutationOutcome.accepted);
    expect(out.results.single.revision, revision() + 2);
    final stored = await harness.stored('Contest', contestId);
    expect(stored!['name'], 'Autumn Open');
    expect(stored['city'], 'Boulder');
  });

  test(
    'the same field changed two ways is a conflict for the director',
    () async {
      await harness.exchange(
        scope,
        mutations: [
          harness.save('Contest', renamed('Autumn Open'), base: revision()),
        ],
      );
      final before = await harness.serverMutationCount();

      final out = await harness.exchange(
        scope,
        mutations: [
          harness.save(
            'Contest',
            renamed('Winter Open'),
            base: revision(),
            clientMutationId: 'rename-2',
          ),
        ],
      );

      final result = out.results.single;
      expect(result.outcome, core.MutationOutcome.conflict);
      expect(result.reasonCode, 'stale_base');
      expect(result.currentRevision, revision() + 1);
      expect(
        (await harness.stored('Contest', contestId))!['name'],
        'Autumn Open',
      );
      expect(out.conflicts, hasLength(1));
      expect(out.conflicts.single.requiresAction, isTrue);
      final change = out.changes.lastWhere(
        (c) => c.entityType == 'ConflictRecord',
      );
      expect(change.entityId, out.conflicts.single.id);
      expect(change.payload['requires_action'], isTrue);
      expect(change.payload['accepted_payload'], isNotNull);
      expect(
        (change.payload['competing_payload']! as Map)['name'],
        'Winter Open',
      );
      expect(change.payload['entity_revision'], revision() + 1);

      // A retry returns the same answer and creates no second conflict.
      final retry = await harness.exchange(
        scope,
        mutations: [
          harness.save(
            'Contest',
            renamed('Winter Open'),
            base: revision(),
            clientMutationId: 'rename-2',
          ),
        ],
      );
      expect(retry.results.single.outcome, core.MutationOutcome.conflict);
      expect(await harness.serverMutationCount(), before + 2);
    },
  );

  group('deciding a conflict', () {
    late core.Id conflictId;

    setUp(() async {
      await harness.exchange(
        scope,
        mutations: [
          harness.save('Contest', renamed('Autumn Open'), base: revision()),
        ],
      );
      final out = await harness.exchange(
        scope,
        mutations: [
          harness.save('Contest', renamed('Winter Open'), base: revision()),
        ],
      );
      conflictId = out.conflicts.single.id;
    });

    Future<core.MutationResult> resolve(
      core.ConflictResolutionChoice choice, {
      String id = 'decide-1',
      Map<String, Object?>? payload,
    }) => harness.service.resolveConflict(
      accountId: harness.account,
      conflictId: conflictId,
      clientMutationId: id,
      choice: choice,
      payload: payload,
    );

    test(
      'taking the competing value applies it and tells every installation',
      () async {
        final result = await resolve(
          core.ConflictResolutionChoice.tookCompeting,
        );

        expect(result.outcome, core.MutationOutcome.accepted);
        expect(result.revision, revision() + 2);
        final stored = await harness.stored('Contest', contestId);
        expect(stored!['name'], 'Winter Open');
        final conflict = await harness.serverRepository.syncAcceptorStore
            .transaction((tx) => tx.findConflict(conflictId));
        expect(conflict!.resolution, core.ConflictResolution.manual);
        expect(
          conflict.resolutionChoice,
          core.ConflictResolutionChoice.tookCompeting,
        );
        expect(conflict.resolvedBy, harness.account);
        final pulled = await harness.exchange(
          scope,
          after: result.sequence! - 1,
        );
        expect(pulled.changes.map((c) => c.entityType), [
          'Contest',
          'ConflictRecord',
        ]);
        expect(pulled.conflicts.single.requiresAction, isFalse);
      },
    );

    test('keeping the accepted value changes no entity', () async {
      final result = await resolve(core.ConflictResolutionChoice.keptAccepted);

      expect(result.outcome, core.MutationOutcome.accepted);
      expect(
        (await harness.stored('Contest', contestId))!['name'],
        'Autumn Open',
      );
      final pulled = await harness.exchange(scope, after: result.sequence! - 1);
      expect(pulled.changes.map((c) => c.entityType), ['ConflictRecord']);
    });

    test('a merged value is stored as the next revision', () async {
      final result = await resolve(
        core.ConflictResolutionChoice.merged,
        payload: renamed('Autumn-Winter Open'),
      );

      expect(result.outcome, core.MutationOutcome.accepted);
      expect(
        (await harness.stored('Contest', contestId))!['name'],
        'Autumn-Winter Open',
      );
    });

    test(
      'repeating a decision returns the original answer; a second is refused',
      () async {
        final first = await resolve(
          core.ConflictResolutionChoice.tookCompeting,
        );
        final before = await harness.serverMutationCount();

        final again = await resolve(
          core.ConflictResolutionChoice.tookCompeting,
        );
        final other = await resolve(
          core.ConflictResolutionChoice.keptAccepted,
          id: 'decide-2',
        );

        expect(again.sequence, first.sequence);
        expect(again.revision, first.revision);
        expect(await harness.serverMutationCount(), before);
        expect(other.outcome, core.MutationOutcome.rejected);
        expect(other.reasonCode, 'stale_base');
      },
    );

    test('another account cannot decide it', () async {
      expect(
        () => harness.service.resolveConflict(
          accountId: core.Id.create(),
          conflictId: conflictId,
          clientMutationId: 'x',
          choice: core.ConflictResolutionChoice.keptAccepted,
        ),
        throwsA(isA<core.ForbiddenError>()),
      );
    });
  });

  test('a locked contest rejects changes with an actionable reason', () async {
    await harness.server.stores.of('Contest').upsertJson({
      ...contest,
      'admin_lock': 'Locked',
    });
    final participation =
        (await harness.server.stores.of('ContestParticipation').all()).first
            as core.ContestParticipation;
    final entity = participation.toJson();

    final out = await harness.exchange(
      scope,
      mutations: [
        harness.save('ContestParticipation', {
          ...entity,
          'number': 99,
        }, base: participation.revision),
      ],
    );

    expect(out.results.single.outcome, core.MutationOutcome.rejected);
    expect(out.results.single.reasonCode, 'locked');
  });

  test(
    'a second configuration revision with a taken number is a conflict',
    () async {
      final stored =
          (await harness.server.stores.of('ContestConfigurationRevision').all())
                  .first
              as core.ContestConfigurationRevision;

      final out = await harness.exchange(
        scope,
        mutations: [
          harness.save('ContestConfigurationRevision', {
            ...stored.toJson(),
            'id': core.Id.create().value,
          }),
        ],
      );

      expect(out.results.single.outcome, core.MutationOutcome.conflict);
      expect(out.results.single.reasonCode, 'config_revision_conflict');
      expect(out.results.single.currentRevision, stored.revisionNumber);
    },
  );

  test('a second live assignment for the same pilot and round is a unique violation', () async {
    final stored =
        (await harness.server.stores.of('MatrixAssignment').all()).first
            as core.MatrixAssignment;

    final out = await harness.exchange(
      scope,
      mutations: [
        harness.save('MatrixAssignment', {
          ...stored.toJson(),
          'id': core.Id.create().value,
        }),
      ],
    );

    expect(out.results.single.outcome, core.MutationOutcome.conflict);
    expect(out.results.single.reasonCode, 'unique_violation');
    expect(out.conflicts.single.requiresAction, isTrue);
    expect(await harness.server.count('matrix_assignments'), greaterThan(0));
  });

  test(
    'a stored immutable entity is not changed, only confirmed when identical',
    () async {
      final stored =
          (await harness.server.stores.of('MatrixAssignment').all()).first
              as core.MatrixAssignment;

      final same = await harness.exchange(
        scope,
        mutations: [harness.save('MatrixAssignment', stored.toJson())],
      );
      final changed = await harness.exchange(
        scope,
        mutations: [
          harness.save('MatrixAssignment', {...stored.toJson(), 'lane': 9}),
        ],
      );

      expect(same.results.single.outcome, core.MutationOutcome.accepted);
      expect(changed.results.single.outcome, core.MutationOutcome.rejected);
      expect(changed.results.single.reasonCode, 'locked');
    },
  );
}
