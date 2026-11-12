import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

/// What an installation does with the service's decisions about pilot links:
/// its own link makes room for the service's, it knows when another
/// installation manages the links, the pilots under review are known, and an
/// import of those pilots (and only those) is stopped.
void _tests(Backend backend) {
  late Installation inst;
  late Repository repo;
  final owner = core.Id.create();
  final scope = core.DirectorScopeKey(owner);
  final now = DateTime.utc(2026);
  var sequence = 0;

  setUp(() async {
    inst = await Installation.open(backend);
    repo = Repository(inst.db);
    sequence = 0;
  });
  tearDown(() => inst.close());

  core.ParticipantProfile profile(String name) => core.ParticipantProfile(
    id: core.Id.create(),
    ownerAccountId: owner,
    firstName: name,
    lastName: 'Pilot',
    createdAt: now,
    updatedAt: now,
  );

  core.PilotImportLink link(
    core.ParticipantProfile target, {
    int number = 12,
    core.Id? id,
    int revision = 0,
  }) => core.PilotImportLink(
    id: id ?? core.Id.create(),
    ownerAccountId: owner,
    sourcePilotNo: number,
    participantProfileId: target.id,
    sourceValues: const {},
    createdAt: now,
    updatedAt: now,
    revision: revision,
  );

  Future<core.PilotImportLink> saveLocal(
    core.ParticipantProfile target, {
    int number = 12,
  }) async {
    await repo.participantProfileRepository.save(target, metadata: metadata());
    return repo.pilotImportLinkRepository.save(
      link(target, number: number),
      metadata: metadata(),
    );
  }

  core.ReplicatedChange remote(
    String type,
    core.Id id,
    Map<String, Object?> payload, {
    bool isDelete = false,
    int revision = 0,
  }) => core.ReplicatedChange(
    scope: scope,
    sequence: ++sequence,
    entityType: type,
    entityId: id,
    revision: revision,
    payload: payload,
    isDelete: isDelete,
  );

  core.ConflictRecord review(
    core.PilotImportLink held,
    core.PilotImportLink offered, {
    core.ConflictResolution resolution = core.ConflictResolution.pending,
  }) => core.ConflictRecord(
    id: core.Id.create(),
    ownerAccountId: owner,
    entityType: 'PilotImportLink',
    entityId: held.id,
    competingMutationId: core.Id.create(),
    reasonCode: 'unique_violation',
    resolution: resolution,
    resolvedAt: resolution == core.ConflictResolution.pending ? null : now,
    createdAt: now,
    acceptedPayload: held.toJson(),
    competingPayload: offered.toJson(),
    entityRevision: held.revision,
  );

  Future<List<core.PilotImportLink>> links() =>
      repo.pilotImportLinkRepository.listForOwner(owner);

  test('a plain link is not under review', () async {
    await saveLocal(profile('Ada'));

    expect(
      await repo.pilotImportLinkRepository.pilotsUnderReview(owner),
      isEmpty,
    );
  });

  test(
    'the service link takes the place of one sent before the pull',
    () async {
      final mine = await saveLocal(profile('Ada'));
      final theirs = link(profile('Grace'));

      final changed = await inst.applier.apply(
        remote('PilotImportLink', theirs.id, theirs.toJson()),
      );

      expect(changed, isTrue);
      expect((await links()).single.id, theirs.id);
      // The local link is gone but its choice is still queued for the service.
      expect(
        (await inst.syncStore.pendingMutations(scope))
            .any((m) => m.entityId == mine.id),
        isTrue,
      );
      // The service refuses the queued choice of a non-managing installation;
      // no review waits, and this installation knows it does not manage links.
      expect(
        await repo.pilotImportLinkRepository.pilotsUnderReview(owner),
        isEmpty,
      );
      expect(
        await repo.pilotImportLinkRepository.managedElsewhere(owner),
        isTrue,
      );
    },
  );

  group('managing the links', () {
    test('a refusal on another account does not count for this one', () async {
      final other = core.Id.create();
      final stranger = core.ParticipantProfile(
        id: core.Id.create(),
        ownerAccountId: other,
        firstName: 'Old',
        lastName: 'Account',
        createdAt: now,
        updatedAt: now,
      );
      await repo.participantProfileRepository.save(
        stranger,
        metadata: metadata(),
      );
      final theirs = await repo.pilotImportLinkRepository.save(
        core.PilotImportLink(
          id: core.Id.create(),
          ownerAccountId: other,
          sourcePilotNo: 5,
          participantProfileId: stranger.id,
          sourceValues: const {},
          createdAt: now,
          updatedAt: now,
        ),
        metadata: metadata(),
      );
      await saveLocal(profile('Ada'));
      for (final m in await inst.syncStore.pendingMutations(
        core.DirectorScopeKey(other),
      )) {
        if (m.entityId != theirs.id) continue;
        await inst.syncStore.recordOutcome(
          mutationId: m.id,
          outcome: core.MutationOutcome.rejected,
          reasonCode: 'not_link_manager',
        );
      }

      expect(
        await repo.pilotImportLinkRepository.managedElsewhere(other),
        isTrue,
      );
      expect(
        await repo.pilotImportLinkRepository.managedElsewhere(owner),
        isFalse,
      );
    });

    test('an installation that wrote its links manages them', () async {
      await saveLocal(profile('Ada'));

      expect(
        await repo.pilotImportLinkRepository.managedElsewhere(owner),
        isFalse,
      );
    });

    test('with no links at all, this installation may start', () async {
      expect(
        await repo.pilotImportLinkRepository.managedElsewhere(owner),
        isFalse,
      );
    });

    test('a link that came down from the service means another does', () async {
      final theirs = link(profile('Grace'));
      await repo.participantProfileRepository.save(
        profile('Grace'),
        metadata: metadata(),
      );
      await inst.applier.apply(
        remote('PilotImportLink', theirs.id, theirs.toJson()),
      );

      expect(
        await repo.pilotImportLinkRepository.managedElsewhere(owner),
        isTrue,
      );
    });

    test('a link the service refused for this reason means it too', () async {
      final mine = await saveLocal(profile('Ada'));
      for (final m in await inst.syncStore.pendingMutations(scope)) {
        if (m.entityId != mine.id) continue;
        await inst.syncStore.recordOutcome(
          mutationId: m.id,
          outcome: core.MutationOutcome.rejected,
          reasonCode: 'not_link_manager',
        );
      }

      expect(
        await repo.pilotImportLinkRepository.managedElsewhere(owner),
        isTrue,
      );
    });
  });

  test('a review that waits names its pilot until it is decided', () async {
    final held = link(profile('Ada'));
    final offered = link(profile('Grace'));
    final open = review(held, offered);
    await inst.applier.apply(remote('PilotImportLink', held.id, held.toJson()));
    await inst.applier.apply(remote('ConflictRecord', open.id, open.toJson()));

    expect(await repo.pilotImportLinkRepository.pilotsUnderReview(owner), {12});

    final closed = review(
      held,
      offered,
      resolution: core.ConflictResolution.automatic,
    );
    await inst.applier.apply(
      remote('ConflictRecord', open.id, {
        ...closed.toJson(),
        'id': open.id.value,
      }),
    );
    expect(
      await repo.pilotImportLinkRepository.pilotsUnderReview(owner),
      isEmpty,
    );
  });

  group('an import', () {
    late core.ParticipantProfile ada, grace, edith;

    setUp(() async {
      ada = profile('Ada');
      grace = profile('Grace');
      edith = profile('Edith');
      final mine = await saveLocal(ada);
      await repo.participantProfileRepository.save(grace, metadata: metadata());
      final open = review(mine, link(grace));
      await inst.applier.apply(
        remote('ConflictRecord', open.id, open.toJson()),
      );
    });

    test('is stopped for a pilot under review', () async {
      await expectLater(
        repo.pilotImportLinkRepository.saveImport(
          [],
          [link(edith)],
          metadata: metadata(),
          reviewedOwner: owner,
          reviewedPilotNumbers: {12},
        ),
        throwsA(
          isA<core.PilotImportLinkReviewError>().having(
            (e) => e.pilotNumbers,
            'pilotNumbers',
            {12},
          ),
        ),
      );
    });

    test('goes ahead for other pilots', () async {
      await repo.participantProfileRepository.save(edith, metadata: metadata());

      await repo.pilotImportLinkRepository.saveImport(
        [],
        [link(edith, number: 13)],
        metadata: metadata(),
        reviewedOwner: owner,
        reviewedPilotNumbers: {13},
      );

      expect(
        (await links()).map((l) => l.sourcePilotNo),
        unorderedEquals([12, 13]),
      );
    });
  });

  test('a deleted participant takes this installation link with it', () async {
    final mine = await saveLocal(profile('Ada'));

    await inst.applier.apply(
      remote(
        'ParticipantProfile',
        mine.participantProfileId,
        const {},
        isDelete: true,
      ),
    );

    expect(await links(), isEmpty);
    expect(
      await repo.pilotImportLinkRepository.pilotsUnderReview(owner),
      isEmpty,
    );
  });
}
