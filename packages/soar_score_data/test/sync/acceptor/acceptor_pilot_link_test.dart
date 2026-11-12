import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:test/test.dart';

import '../../support/acceptor_harness.dart';
import '../../support/backends.dart';

void main() => forEachBackend(_tests);

/// Two installations of one director link the same GliderScore pilot while
/// offline: the service keeps the first link and asks the director about the
/// other, and a deleted participant stays deleted.
void _tests(Backend backend) {
  late AcceptorHarness harness;
  late core.DirectorScopeKey scope;
  late core.Id p1, p2, p3;
  late core.Id linkA, linkB;
  const pilot = 12;

  tearDown(() => harness.close());

  Future<core.Id> addProfile(String name) async {
    final now = DateTime.utc(2026, 10);
    final profile = core.ParticipantProfile(
      id: core.Id.create(),
      ownerAccountId: harness.account,
      firstName: name,
      lastName: 'Pilot',
      createdAt: now,
      updatedAt: now,
    );
    final out = await harness.exchange(
      scope,
      mutations: [harness.save('ParticipantProfile', profile.toJson())],
    );
    expect(out.results.single.outcome, core.MutationOutcome.accepted);
    return profile.id;
  }

  setUp(() async {
    harness = await AcceptorHarness.open(backend);
    await harness.register(harness.installationB, 'Tablet');
    scope = core.DirectorScopeKey(harness.account);
    p1 = await addProfile('Ada');
    p2 = await addProfile('Grace');
    p3 = await addProfile('Edith');
    linkA = core.Id.create();
    linkB = core.Id.create();
  });
  Map<String, Object?> link(
    core.Id id,
    core.Id profile, {
    int revision = 0,
    int number = pilot,
    Map<String, Object?> values = const {},
  }) => core.PilotImportLink(
    id: id,
    ownerAccountId: harness.account,
    sourcePilotNo: number,
    participantProfileId: profile,
    sourceValues: values,
    createdAt: DateTime.utc(2026, 10),
    updatedAt: DateTime.utc(2026, 10, 1, revision),
    revision: revision,
  ).toJson();

  Future<List<core.MutationResult>> send(
    core.Id installation,
    List<core.SyncMutation> mutations,
  ) async => (await harness.exchange(
    scope,
    installation: installation,
    mutations: mutations,
  )).results;

  Future<List<core.ConflictRecord>> pending() => harness
      .serverRepository
      .syncAcceptorStore
      .transaction((tx) => tx.conflictsNeedingAction(scope));

  Future<core.MutationResult> resolve(
    core.Id conflictId,
    core.ConflictResolutionChoice choice, [
    String id = 'decide',
  ]) => harness.service.resolveConflict(
    accountId: harness.account,
    conflictId: conflictId,
    clientMutationId: id,
    choice: choice,
  );

  Future<void> offlineLinks({Map<String, Object?> values = const {}}) async {
    final a = await send(harness.installationA, [
      harness.save('PilotImportLink', link(linkA, p1)),
    ]);
    expect(a.single.outcome, core.MutationOutcome.accepted);
  }

  group('devices that link the pilot to different participants', () {
    setUp(offlineLinks);

    test('the second link waits for the director, naming both', () async {
      final result = await send(harness.installationB, [
        harness.save('PilotImportLink', link(linkB, p2)),
      ]);

      expect(result.single.outcome, core.MutationOutcome.conflict);
      expect(result.single.reasonCode, 'unique_violation');
      final conflict = (await pending()).single;
      expect(conflict.entityId, linkA);
      expect(conflict.acceptedPayload!['participant_profile_id'], p1.value);
      expect(conflict.competingPayload!['participant_profile_id'], p2.value);
      expect(conflict.acceptedPayload!['source_pilot_no'], pilot);
      expect(conflict.entityRevision, 0);
      final stored = await harness.stored('PilotImportLink', linkA);
      expect(stored!['participant_profile_id'], p1.value);
      expect(await harness.stored('PilotImportLink', linkB), isNull);
    });

    test('several queued edits leave one review of the latest', () async {
      final queue = [
        harness.save(
          'PilotImportLink',
          link(linkB, p2),
          clientMutationId: 'b1',
        ),
        harness.save(
          'PilotImportLink',
          link(linkB, p2, revision: 1, values: {'club': 'north'}),
          base: 0,
          clientMutationId: 'b2',
        ),
        harness.save(
          'PilotImportLink',
          link(linkB, p3, revision: 2, values: {'club': 'north'}),
          base: 1,
          clientMutationId: 'b3',
        ),
      ];

      final results = await send(harness.installationB, queue);

      expect(
        results.map((r) => r.outcome),
        everyElement(core.MutationOutcome.conflict),
      );
      final open = await pending();
      expect(open, hasLength(1));
      expect(open.single.competingPayload!['participant_profile_id'], p3.value);
      expect(open.single.competingPayload!['revision'], 2);
      expect(open.single.competingPayload!['source_values'], {'club': 'north'});
      expect(open.single.acceptedPayload!['participant_profile_id'], p1.value);
    });

    test('sending the queue again changes nothing', () async {
      final queue = [
        harness.save(
          'PilotImportLink',
          link(linkB, p2),
          clientMutationId: 'b1',
        ),
        harness.save(
          'PilotImportLink',
          link(linkB, p3, revision: 1),
          base: 0,
          clientMutationId: 'b2',
        ),
      ];
      final first = await send(harness.installationB, queue);
      final mutations = await harness.serverMutationCount();
      final conflicts = await harness.server.count('conflict_records');
      final review = (await pending()).single;

      final retry = await send(harness.installationB, queue);

      expect(retry.map((r) => r.outcome), first.map((r) => r.outcome));
      expect(await harness.serverMutationCount(), mutations);
      expect(await harness.server.count('conflict_records'), conflicts);
      expect((await pending()).single.id, review.id);
    });

    test(
      'an interrupted exchange keeps every edit once it is resumed',
      () async {
        final first = harness.save(
          'PilotImportLink',
          link(linkB, p2),
          clientMutationId: 'b1',
        );
        final second = harness.save(
          'PilotImportLink',
          link(linkB, p3, revision: 1),
          base: 0,
          clientMutationId: 'b2',
        );
        await send(harness.installationB, [first]);
        expect(
          (await pending()).single.competingPayload!['participant_profile_id'],
          p2.value,
        );

        final resumed = await send(harness.installationB, [first, second]);

        expect(
          resumed.map((r) => r.outcome),
          everyElement(core.MutationOutcome.conflict),
        );
        final open = await pending();
        expect(open, hasLength(1));
        expect(
          open.single.competingPayload!['participant_profile_id'],
          p3.value,
        );
      },
    );

    test('a link deleted before the decision no longer competes', () async {
      await send(harness.installationB, [
        harness.save(
          'PilotImportLink',
          link(linkB, p2),
          clientMutationId: 'b1',
        ),
      ]);

      final result = await send(harness.installationB, [
        harness.delete(
          'PilotImportLink',
          linkB,
          base: 0,
          clientMutationId: 'b2',
        ),
      ]);

      expect(result.single.outcome, core.MutationOutcome.accepted);
      expect(await pending(), isEmpty);
    });

    test('a change to the stored link replaces the review', () async {
      await send(harness.installationB, [
        harness.save('PilotImportLink', link(linkB, p2)),
      ]);
      final shown = (await pending()).single;

      final edit = await send(harness.installationA, [
        harness.save(
          'PilotImportLink',
          link(linkA, p1, revision: 1, values: {'club': 'south'}),
          base: 0,
        ),
      ]);
      expect(edit.single.outcome, core.MutationOutcome.accepted);

      final open = (await pending()).single;
      expect(open.id, isNot(shown.id));
      expect(open.entityRevision, 1);
      expect(open.acceptedPayload!['source_values'], {'club': 'south'});
      expect(open.competingPayload!['participant_profile_id'], p2.value);
      final stale = await resolve(
        shown.id,
        core.ConflictResolutionChoice.tookCompeting,
      );
      expect(stale.outcome, core.MutationOutcome.rejected);
      expect(stale.reasonCode, 'stale_base');
      expect(
        (await harness.stored(
          'PilotImportLink',
          linkA,
        ))!['participant_profile_id'],
        p1.value,
      );
      final fresh = await resolve(
        open.id,
        core.ConflictResolutionChoice.tookCompeting,
        'decide-2',
      );
      expect(fresh.outcome, core.MutationOutcome.accepted);
    });

    test('devices that come to agree need no decision', () async {
      await send(harness.installationB, [
        harness.save('PilotImportLink', link(linkB, p2)),
      ]);

      await send(harness.installationA, [
        harness.save('PilotImportLink', link(linkA, p2, revision: 1), base: 0),
      ]);

      expect(await pending(), isEmpty);
    });

    test('a newer edit of the other device replaces the review too', () async {
      await send(harness.installationB, [
        harness.save(
          'PilotImportLink',
          link(linkB, p2),
          clientMutationId: 'b1',
        ),
      ]);
      final shown = (await pending()).single;

      await send(harness.installationB, [
        harness.save(
          'PilotImportLink',
          link(linkB, p3, revision: 1),
          base: 0,
          clientMutationId: 'b2',
        ),
      ]);

      final open = (await pending()).single;
      expect(open.id, isNot(shown.id));
      expect(open.competingPayload!['participant_profile_id'], p3.value);
      final stale = await resolve(
        shown.id,
        core.ConflictResolutionChoice.tookCompeting,
      );
      expect(stale.outcome, core.MutationOutcome.rejected);
    });

    group('the director decides', () {
      late core.Id reviewId;
      setUp(() async {
        await send(harness.installationB, [
          harness.save(
            'PilotImportLink',
            link(linkB, p2, values: {'club': 'b'}),
          ),
        ]);
        reviewId = (await pending()).single.id;
      });

      test('for the competing link: it becomes the stored one', () async {
        final result = await resolve(
          reviewId,
          core.ConflictResolutionChoice.tookCompeting,
        );

        expect(result.outcome, core.MutationOutcome.accepted);
        final stored = await harness.stored('PilotImportLink', linkA);
        expect(stored!['participant_profile_id'], p2.value);
        expect(stored['source_values'], {'club': 'b'});
        expect(stored['revision'], 1);
        expect(await pending(), isEmpty);
        // Both installations pull the same decision.
        final pulled = await harness.exchange(scope, after: 0);
        final change = pulled.changes.lastWhere(
          (c) => c.entityType == 'PilotImportLink',
        );
        expect(change.entityId, linkA);
        expect(change.payload['participant_profile_id'], p2.value);
      });

      test('for the stored link: nothing changes', () async {
        final result = await resolve(
          reviewId,
          core.ConflictResolutionChoice.keptAccepted,
        );

        expect(result.outcome, core.MutationOutcome.accepted);
        final stored = await harness.stored('PilotImportLink', linkA);
        expect(stored!['participant_profile_id'], p1.value);
        expect(stored['revision'], 0);
        expect(await pending(), isEmpty);
      });

      test('a late edit of the other device is reviewed again', () async {
        await resolve(reviewId, core.ConflictResolutionChoice.keptAccepted);

        final late = await send(harness.installationB, [
          harness.save(
            'PilotImportLink',
            link(linkB, p3, revision: 1),
            base: 0,
          ),
        ]);

        expect(late.single.outcome, core.MutationOutcome.conflict);
        final open = (await pending()).single;
        expect(open.id, isNot(reviewId));
        expect(open.competingPayload!['participant_profile_id'], p3.value);
      });

      test(
        'a late edit that agrees with the decision is not reviewed',
        () async {
          await resolve(reviewId, core.ConflictResolutionChoice.tookCompeting);

          final late = await send(harness.installationB, [
            harness.save(
              'PilotImportLink',
              link(linkB, p2, revision: 1, values: {'club': 'later'}),
              base: 0,
            ),
          ]);

          expect(late.single.outcome, core.MutationOutcome.conflict);
          expect(late.single.reasonCode, 'same_participant_link');
          expect(await pending(), isEmpty);
        },
      );

      test('the same decision sent twice is applied once', () async {
        await resolve(reviewId, core.ConflictResolutionChoice.tookCompeting);
        final again = await resolve(
          reviewId,
          core.ConflictResolutionChoice.tookCompeting,
        );

        expect(again.outcome, core.MutationOutcome.accepted);
        expect(
          (await harness.stored('PilotImportLink', linkA))!['revision'],
          1,
        );
      });
    });
  });

  group('devices that link the pilot to the same participant', () {
    setUp(offlineLinks);

    test('keeps the stored link; the next import compares details', () async {
      final result = await send(harness.installationB, [
        harness.save('PilotImportLink', link(linkB, p1, values: {'club': 'b'})),
      ]);

      expect(result.single.reasonCode, 'same_participant_link');
      expect(await pending(), isEmpty);
      final stored = await harness.stored('PilotImportLink', linkA);
      expect(stored!['source_values'], isEmpty);
      expect(await harness.stored('PilotImportLink', linkB), isNull);
      final record = await harness.serverRepository.syncAcceptorStore
          .transaction((tx) => tx.conflictsNeedingAction(scope));
      expect(record, isEmpty);
    });
  });

  group('a deleted participant', () {
    Future<void> deleteProfile(core.Id id) async {
      final out = await harness.exchange(
        scope,
        mutations: [
          harness.delete(
            'ParticipantProfile',
            id,
            base:
                (await harness.stored('ParticipantProfile', id))!['revision']
                    as int,
          ),
        ],
      );
      expect(out.results.single.outcome, core.MutationOutcome.accepted);
    }

    test('stays deleted when an offline device links it', () async {
      await deleteProfile(p2);

      final result = await send(harness.installationB, [
        harness.save('PilotImportLink', link(linkB, p2)),
      ]);

      expect(result.single.outcome, core.MutationOutcome.rejected);
      expect(result.single.reasonCode, 'entity_deleted');
      expect(await harness.stored('PilotImportLink', linkB), isNull);
      expect(await harness.stored('ParticipantProfile', p2), isNull);
    });

    test(
      'takes its link with it, and a repeated delete is not refused',
      () async {
        await offlineLinks();

        await deleteProfile(p1);

        expect(await harness.stored('PilotImportLink', linkA), isNull);
        final pulled = await harness.exchange(scope, after: 0);
        expect(
          pulled.changes.any(
            (c) =>
                c.entityType == 'PilotImportLink' &&
                c.payload['deleted'] == true,
          ),
          isTrue,
        );
        final again = await send(harness.installationA, [
          harness.delete('PilotImportLink', linkA, base: 0),
        ]);
        expect(again.single.outcome, core.MutationOutcome.accepted);
      },
    );

    test('refuses an offline edit of a link that went with it', () async {
      await offlineLinks();
      await deleteProfile(p1);

      final result = await send(harness.installationB, [
        harness.save(
          'PilotImportLink',
          link(linkA, p1, revision: 1, values: {'club': 'x'}),
          base: 0,
        ),
      ]);

      expect(result.single.outcome, core.MutationOutcome.rejected);
      expect(await harness.stored('PilotImportLink', linkA), isNull);
    });

    test('closes the review that named the competing participant', () async {
      await offlineLinks();
      await send(harness.installationB, [
        harness.save('PilotImportLink', link(linkB, p2)),
      ]);

      await deleteProfile(p2);

      expect(await pending(), isEmpty);
      expect(
        (await harness.stored(
          'PilotImportLink',
          linkA,
        ))!['participant_profile_id'],
        p1.value,
      );
    });

    test('lets the other link stand when the stored link goes', () async {
      await offlineLinks();
      await send(harness.installationB, [
        harness.save('PilotImportLink', link(linkB, p2)),
      ]);

      await deleteProfile(p1);

      expect(await pending(), isEmpty);
      expect(await harness.stored('PilotImportLink', linkA), isNull);
      expect(
        (await harness.stored(
          'PilotImportLink',
          linkB,
        ))!['participant_profile_id'],
        p2.value,
      );
    });
  });
}
