import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend((backend) {
  late Installation inst;
  late Repository repo;
  final owner = core.Id.create();
  final now = DateTime.utc(2026);
  setUp(() async {
    inst = await Installation.open(backend);
    repo = Repository(inst.db);
  });
  tearDown(() => inst.close());
  core.ParticipantProfile profile(core.Id id) => core.ParticipantProfile(
    id: id,
    ownerAccountId: owner,
    firstName: 'A',
    lastName: 'Pilot',
    createdAt: now,
    updatedAt: now,
  );
  core.PilotImportLink link(core.Id target, {int no = 1}) =>
      core.PilotImportLink(
        id: core.Id.create(),
        ownerAccountId: owner,
        sourcePilotNo: no,
        participantProfileId: target,
        sourceValues: {'first_name': 'A'},
        createdAt: now,
        updatedAt: now,
      );
  test(
    'saves profiles and links atomically and deletes active links',
    () async {
      final id = core.Id.create();
      await repo.pilotImportLinkRepository.saveImport(
        [profile(id)],
        [link(id)],
        metadata: metadata(),
      );
      expect(
        await repo.pilotImportLinkRepository.listForOwner(owner),
        hasLength(1),
      );
      expect(
        await repo.participantProfileRepository.delete(
          id,
          metadata: metadata(),
        ),
        isTrue,
      );
      expect(await repo.pilotImportLinkRepository.listForOwner(owner), isEmpty);
    },
  );
  test('invalid target rolls back participant creation', () async {
    final id = core.Id.create();
    await expectLater(
      repo.pilotImportLinkRepository.saveImport(
        [profile(id)],
        [link(core.Id.create())],
        metadata: metadata(),
      ),
      throwsArgumentError,
    );
    expect(await repo.participantProfileRepository.findById(id), isNull);
  });
  test(
    'a repeated unchanged import does not rewrite the link or create mutations',
    () async {
      final id = core.Id.create();
      final participant = profile(id);
      const draft = core.PilotDraft(
        sourcePilotNo: 1,
        firstName: 'A',
        lastName: 'Pilot',
      );
      final initial = core.PilotImportLink(
        id: core.Id.create(),
        ownerAccountId: owner,
        sourcePilotNo: 1,
        participantProfileId: id,
        sourceValues: core.PilotImportMatcher.sourceValues(draft),
        createdAt: now,
        updatedAt: now,
      );
      await repo.pilotImportLinkRepository.saveImport(
        [participant],
        [initial],
        metadata: metadata(),
      );
      final current = (await repo.participantProfileRepository.findById(id))!;
      final savedLink = (await repo.pilotImportLinkRepository.listForOwner(
        owner,
      )).single;
      final match = const core.PilotImportMatcher()
          .match([draft], [current], links: [savedLink])
          .single;
      final countBefore = await inst.count('mutation_records');
      final service = core.PilotImportService(
        repo.participantProfileRepository,
        links: repo.pilotImportLinkRepository,
        reviewedLinks: {savedLink.id: savedLink.revision},
        clock: () => now.add(const Duration(days: 1)),
      );
      await service.apply(
        owner,
        [core.PilotImportSelection.defaultFor(match)],
        metadata: metadata(),
        reviewedRevisions: {id: current.revision},
      );
      final after = (await repo.pilotImportLinkRepository.listForOwner(owner))
          .single;
      expect(after.revision, savedLink.revision);
      expect(after.updatedAt, savedLink.updatedAt);
      expect(await inst.count('mutation_records'), countBefore);
    },
  );
  test('an approved source change updates the saved link snapshot', () async {
    final id = core.Id.create();
    const before = core.PilotDraft(
      sourcePilotNo: 1,
      firstName: 'A',
      lastName: 'Pilot',
    );
    const after = core.PilotDraft(
      sourcePilotNo: 1,
      firstName: 'A',
      lastName: 'Pilot',
      club: 'New Club',
    );
    final initial = core.PilotImportLink(
      id: core.Id.create(),
      ownerAccountId: owner,
      sourcePilotNo: 1,
      participantProfileId: id,
      sourceValues: core.PilotImportMatcher.sourceValues(before),
      createdAt: now,
      updatedAt: now,
    );
    await repo.pilotImportLinkRepository.saveImport(
      [profile(id)],
      [initial],
      metadata: metadata(),
    );
    final participant = (await repo.participantProfileRepository.findById(id))!;
    final savedLink = (await repo.pilotImportLinkRepository.listForOwner(owner))
        .single;
    final match = const core.PilotImportMatcher()
        .match([after], [participant], links: [savedLink])
        .single;
    final service = core.PilotImportService(
      repo.participantProfileRepository,
      links: repo.pilotImportLinkRepository,
      reviewedLinks: {savedLink.id: savedLink.revision},
      clock: () => now.add(const Duration(days: 1)),
    );
    await service.apply(
      owner,
      [
        core.PilotImportSelection(
          match: match,
          choice: core.PilotImportChoice.update,
          targetProfileId: id,
        ),
      ],
      metadata: metadata(),
      reviewedRevisions: {id: participant.revision},
    );
    final updated = (await repo.pilotImportLinkRepository.listForOwner(owner))
        .single;
    expect(updated.sourceValues['club'], 'new club');
    expect(updated.revision, savedLink.revision + 1);
  });
  test('a link added after review prevents the entire import', () async {
    final existingId = core.Id.create();
    await repo.pilotImportLinkRepository.saveImport(
      [profile(existingId)],
      [link(existingId)],
      metadata: metadata(),
    );
    final newId = core.Id.create();
    await expectLater(
      repo.pilotImportLinkRepository.saveImport(
        [profile(newId)],
        [link(newId, no: 2)],
        metadata: metadata(),
        reviewedOwner: owner,
        reviewedLinks: {},
      ),
      throwsA(isA<core.PilotImportReviewChangedError>()),
    );
    expect(await repo.participantProfileRepository.findById(newId), isNull);
  });
  test('replicated links and their deletions are applied', () async {
    final id = core.Id.create();
    final value = link(id);
    await inst.applier.apply(
      core.ReplicatedChange(
        scope: core.DirectorScopeKey(owner),
        sequence: 1,
        entityType: 'PilotImportLink',
        entityId: value.id,
        revision: 1,
        isDelete: false,
        payload: value.toJson(),
      ),
    );
    expect(
      await repo.pilotImportLinkRepository.listForOwner(owner),
      hasLength(1),
    );
    await inst.applier.apply(
      core.ReplicatedChange(
        scope: core.DirectorScopeKey(owner),
        sequence: 2,
        entityType: 'PilotImportLink',
        entityId: value.id,
        revision: 2,
        isDelete: true,
        payload: const {},
      ),
    );
    expect(await repo.pilotImportLinkRepository.listForOwner(owner), isEmpty);
  });
  test(
    'claim moves the link owner',
    () async {
      final local = LocalAccountRepository(inst.db);
      final localId = await local.ensure();
      final account = core.Id.create();
      final id = core.Id.create();
      final p = core.ParticipantProfile(
        id: id,
        ownerAccountId: localId,
        firstName: 'A',
        lastName: 'Pilot',
        createdAt: now,
        updatedAt: now,
      );
      final l = core.PilotImportLink(
        id: core.Id.create(),
        ownerAccountId: localId,
        sourcePilotNo: 1,
        participantProfileId: id,
        sourceValues: const {},
        createdAt: now,
        updatedAt: now,
      );
      await repo.pilotImportLinkRepository.saveImport(
        [p],
        [l],
        metadata: metadata(),
      );
      await local.reassignTo(account);
      expect(
        await repo.pilotImportLinkRepository.listForOwner(localId),
        isEmpty,
      );
      expect(
        await repo.pilotImportLinkRepository.listForOwner(account),
        hasLength(1),
      );
    },
    skip: backend == Backend.postgres
        ? 'local account exists on installations only'
        : false,
  );
  test('one source number cannot target two profiles', () async {
    final first = core.Id.create(), second = core.Id.create();
    await repo.pilotImportLinkRepository.saveImport(
      [profile(first), profile(second)],
      [link(first)],
      metadata: metadata(),
    );
    await expectLater(
      repo.pilotImportLinkRepository.save(link(second), metadata: metadata()),
      throwsA(anything),
    );
    expect(
      await repo.pilotImportLinkRepository.listForOwner(owner),
      hasLength(1),
    );
  });
});
