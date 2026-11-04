import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:test/test.dart';

import '../support/backends.dart';
import '../support/fixtures.dart';

void main() => forEachBackend(_tests);

const _fingerprint = 'sha256:abc';

void _tests(Backend backend) {
  late Installation inst;
  late ContestImportRepository importer;
  late Repository repository;
  final owner = core.Id.create();
  final signedIn = core.ImportOwner(signedInAccountId: owner);

  setUp(() async {
    inst = await Installation.open(backend);
    await SystemDataSeeder(inst.db).seed();
    importer = ContestImportRepository(inst.db);
    repository = Repository(inst.db);
  });
  tearDown(() => inst.close());

  /// Profiles for the pilots 1..[count], owned by [owner].
  Future<Map<int, core.Id>> profiles(int count, {core.Id? ownerId}) async {
    final ids = <int, core.Id>{};
    for (var n = 1; n <= count; n++) {
      final saved = await repository.participantProfileRepository.save(
        core.ParticipantProfile(
          id: core.Id.create(),
          ownerAccountId: ownerId ?? owner,
          firstName: 'Pilot',
          lastName: 'Number$n',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        metadata: metadata(),
      );
      ids[n] = saved.id;
    }
    return ids;
  }

  core.ContestImportDraft draft({
    int compNo = 22,
    List<core.ParticipationDraft>? participants,
    String? disciplineType = 'F5J',
  }) => core.ContestImportDraft(
    sourceCompNo: compNo,
    sourceClass: 'F5J',
    status: core.ContestImportStatus.importable,
    name: 'Imported Open $compNo',
    host: 'Field A',
    startDate: DateTime.utc(2026, 5, 9),
    disciplineType: disciplineType,
    config: core.ContestConfig(core: const {}, discipline: const {}),
    sourceLaneCount: 6,
    teams: const [core.TeamDraft(sourceTeamNo: 1, name: 'Team 1')],
    participants:
        participants ??
        const [
          core.ParticipationDraft(
            sourcePilotNo: 1,
            role: core.ImportedRole.pilot,
            sourceRole: 'Plt',
            participantNumber: 7,
            sourceTeamNo: 1,
            modelName: 'Supra',
          ),
          core.ParticipationDraft(
            sourcePilotNo: 2,
            role: core.ImportedRole.pilot,
            sourceRole: 'Plt',
            participantNumber: 8,
            sourceTeamNo: 1,
          ),
          core.ParticipationDraft(
            sourcePilotNo: 3,
            role: core.ImportedRole.helper,
            sourceRole: 'Hlp',
          ),
          core.ParticipationDraft(
            sourcePilotNo: 4,
            role: core.ImportedRole.competitionDirector,
            sourceRole: 'CD',
          ),
        ],
  );

  core.CompetitionImportPlan plan(
    core.ContestImportDraft d,
    Map<int, core.Id> ids, {
    core.ImportOwner? who,
    String fingerprint = _fingerprint,
    core.Id? operation,
  }) => core.CompetitionImportPlan(
    draft: d,
    profileIds: ids,
    owner: who ?? signedIn,
    timezone: 'America/Denver',
    importOperationId: operation ?? core.Id.create(),
    fileFingerprint: fingerprint,
    toolVersion: '1.0.0',
  );

  group('importCompetition', () {
    test('writes the contest, configuration, people and stamps', () async {
      final ids = await profiles(4);
      final result = await importer.importCompetition(
        plan(draft(), ids),
        metadata: metadata(),
      );
      final imported = result as core.CompetitionImported;
      expect(imported.participationCount, 4);

      final contest = (await repository.contestRepository.findById(
        imported.contestId,
      ))!;
      expect(contest.lifecycleState, core.LifecycleState.configuring);
      expect(contest.ownerAccountId, owner);
      expect(contest.name, 'Imported Open 22');
      expect(contest.timezone, 'America/Denver');
      expect(contest.startDateTime, DateTime.utc(2026, 5, 9, 12));

      final revisions = await repository.contestConfigurationRevisionRepository
          .listForContest(contest.id);
      expect(revisions, hasLength(1));
      expect(revisions.single.revisionNumber, 1);

      final participations = await repository.contestParticipationRepository
          .listForContest(contest.id);
      expect(participations, hasLength(4));
      final byProfile = {
        for (final p in participations) p.participantProfileId: p,
      };
      expect(byProfile[ids[1]]!.participantNumber, 7);
      expect(byProfile[ids[1]]!.roleType, core.RoleType.pilot);
      expect(byProfile[ids[3]]!.roleId, core.SystemRoles.helperId);
      final director = byProfile[ids[4]]!;
      expect(director.roleType, core.RoleType.nonFlier);
      final role = (await repository.roleRepository.findById(director.roleId))!;
      expect(role.ownerAccountId, owner);
      expect(role.displayName, 'Competition Director');

      expect(
        await repository.teamRepository.listForContest(contest.id),
        hasLength(1),
      );
      expect(
        await repository.teamMembershipRepository.listForContest(contest.id),
        hasLength(2),
      );
      final links = await repository.contestModelLinkRepository.listForContest(
        contest.id,
      );
      expect(links.map((l) => l.modelName), ['Supra']);

      final stamps = await repository.importProvenanceRepository.listForContest(
        contest.id,
      );
      expect(stamps, hasLength(5));
      final contestStamp = stamps.singleWhere(
        (s) => s.stampedEntityType == 'Contest',
      );
      expect(contestStamp.sourceKeys, {'comp_no': 22});
      expect(contestStamp.sourceValues, {'lane_count': 6});
      expect(contestStamp.dedupeKey, 'gliderscore:$_fingerprint:22');
      expect(contestStamp.ownerAccountId, owner);

      final events = await repository.auditEventRepository.listForContest(
        contest.id,
        action: core.AuditAction.stateTransition,
      );
      expect(events.map((e) => e.reason), [startsWith('import:gliderscore:')]);
      expect(await inst.count('mutation_records'), greaterThan(10));
    });

    test('a participant without a chosen profile is left out', () async {
      final ids = await profiles(4)
        ..remove(2);
      final result = await importer.importCompetition(
        plan(draft(), ids),
        metadata: metadata(),
      );
      final imported = result as core.CompetitionImported;
      expect(imported.participationCount, 3);
      expect(imported.skippedParticipants, [2]);
    });

    test('a repeat of the same competition and file writes nothing', () async {
      final ids = await profiles(4);
      final first = await importer.importCompetition(
        plan(draft(), ids),
        metadata: metadata(),
      ) as core.CompetitionImported;
      final contests = await inst.count('contests');
      final stamps = await inst.count('import_provenance');

      final again = await importer.importCompetition(
        plan(draft(), ids),
        metadata: metadata(),
      );
      expect(again, isA<core.CompetitionAlreadyImported>());
      expect(
        (again as core.CompetitionAlreadyImported).contestId,
        first.contestId,
      );
      expect(await inst.count('contests'), contests);
      expect(await inst.count('import_provenance'), stamps);
    });

    test('a changed file or another competition is a new contest', () async {
      final ids = await profiles(4);
      final a = await importer.importCompetition(
        plan(draft(), ids),
        metadata: metadata(),
      );
      final b = await importer.importCompetition(
        plan(draft(), ids, fingerprint: 'sha256:other'),
        metadata: metadata(),
      );
      final c = await importer.importCompetition(
        plan(draft(compNo: 23), ids),
        metadata: metadata(),
      );
      expect([a, b, c], everyElement(isA<core.CompetitionImported>()));
      expect(await inst.count('contests'), 3);
    });

    test('two runs at once leave exactly one contest', () async {
      final ids = await profiles(4);
      final results = await Future.wait([
        importer.importCompetition(plan(draft(), ids), metadata: metadata()),
        importer.importCompetition(plan(draft(), ids), metadata: metadata()),
      ]);
      expect(results.whereType<core.CompetitionImported>(), hasLength(1));
      expect(
        results.whereType<core.CompetitionAlreadyImported>(),
        hasLength(1),
      );
      expect(await inst.count('contests'), 1);
    });

    test('deleting the contest allows importing it again', () async {
      final ids = await profiles(4);
      final first = await importer.importCompetition(
        plan(draft(), ids),
        metadata: metadata(),
      ) as core.CompetitionImported;
      await repository.contestRepository.delete(
        first.contestId,
        metadata: metadata(),
      );
      expect(await inst.count('import_provenance'), 0);
      final again = await importer.importCompetition(
        plan(draft(), ids),
        metadata: metadata(),
      );
      expect(again, isA<core.CompetitionImported>());
    });

    test('a failure part-way keeps nothing of that competition', () async {
      final ids = await profiles(4);
      final failing = ContestImportRepository(
        inst.db,
        newId: _repeatingIds(core.Id.create(), after: 5),
      );
      final result = await failing.importCompetition(
        plan(draft(), ids),
        metadata: metadata(),
      );
      expect(result, isA<core.CompetitionImportFailed>());
      for (final table in [
        'contests',
        'contest_configuration_revisions',
        'contest_participations',
        'teams',
        'import_provenance',
        'audit_events',
        'mutation_records',
      ]) {
        expect(
          await inst.count(table),
          table == 'mutation_records' ? greaterThan(-1) : 0,
          reason: table,
        );
      }
      final others = await importer.importCompetition(
        plan(draft(compNo: 23), ids),
        metadata: metadata(),
      );
      expect(others, isA<core.CompetitionImported>());
    });

    test('with no account nothing is written', () async {
      final ids = await profiles(4);
      final result = await importer.importCompetition(
        plan(draft(), ids, who: const core.ImportOwner()),
        metadata: metadata(),
      );
      expect(
        (result as core.CompetitionImportFailed).code,
        core.CompetitionImportFailure.noAccount,
      );
      expect(await inst.count('contests'), 0);
    });

    test('the Local account owns an unsigned import', () async {
      final local = core.Id.create();
      final ids = await profiles(4, ownerId: local);
      final result = await importer.importCompetition(
        plan(draft(), ids, who: core.ImportOwner(localAccountId: local)),
        metadata: metadata(),
      ) as core.CompetitionImported;
      final contest = (await repository.contestRepository.findById(
        result.contestId,
      ))!;
      expect(contest.ownerAccountId, local);
    });

    test('the signed-in account wins over the Local one', () async {
      final ids = await profiles(4);
      final result = await importer.importCompetition(
        plan(
          draft(),
          ids,
          who: core.ImportOwner(
            signedInAccountId: owner,
            localAccountId: core.Id.create(),
          ),
        ),
        metadata: metadata(),
      ) as core.CompetitionImported;
      expect(
        (await repository.contestRepository.findById(result.contestId))!
            .ownerAccountId,
        owner,
      );
    });

    test('no published profile for the class is reported', () async {
      final ids = await profiles(4);
      final result = await importer.importCompetition(
        plan(draft(disciplineType: 'F3K9'), ids),
        metadata: metadata(),
      );
      expect(
        (result as core.CompetitionImportFailed).code,
        core.CompetitionImportFailure.profileUnavailable,
      );
      expect(await inst.count('contests'), 0);
    });

    test('a profile of another owner is refused', () async {
      final ids = await profiles(4, ownerId: core.Id.create());
      final result = await importer.importCompetition(
        plan(draft(), ids),
        metadata: metadata(),
      );
      expect(
        (result as core.CompetitionImportFailed).code,
        core.CompetitionImportFailure.profileMissing,
      );
      expect(await inst.count('contests'), 0);
    });

    test('a blocked draft is not written', () async {
      final result = await importer.importCompetition(
        plan(
          const core.ContestImportDraft(
            sourceCompNo: 5,
            sourceClass: 'F3J',
            status: core.ContestImportStatus.skipped,
            reason: core.ContestImportReason.classNotSupportedYet,
          ),
          const {},
        ),
        metadata: metadata(),
      );
      expect(
        (result as core.CompetitionImportFailed).code,
        core.CompetitionImportFailure.notImportable,
      );
    });
  });

  group('stampProfiles', () {
    test('stamps once per operation, with an audit event', () async {
      final ids = await profiles(2);
      final operation = core.Id.create();
      core.ProfileStampPlan stamps(core.Id op) => core.ProfileStampPlan(
        owner: signedIn,
        importOperationId: op,
        fileFingerprint: _fingerprint,
        toolVersion: '1.0.0',
        entries: [
          core.ProfileStampEntry(
            sourcePilotNo: 1,
            profileId: ids[1]!,
            created: true,
          ),
          core.ProfileStampEntry(
            sourcePilotNo: 2,
            profileId: ids[2]!,
            created: false,
          ),
        ],
      );
      await importer.stampProfiles(stamps(operation), metadata: metadata());
      await importer.stampProfiles(stamps(operation), metadata: metadata());
      expect(await inst.count('import_provenance'), 2);
      expect(await inst.count('audit_events'), 2);

      await importer.stampProfiles(
        stamps(core.Id.create()),
        metadata: metadata(),
      );
      expect(
        await repository.importProvenanceRepository.listForEntity(ids[1]!),
        hasLength(2),
      );
    });

    test('two callers with one plan write it once', () async {
      final ids = await profiles(3);
      final operation = core.Id.create();
      core.ProfileStampPlan stamps() => core.ProfileStampPlan(
        owner: signedIn,
        importOperationId: operation,
        fileFingerprint: _fingerprint,
        toolVersion: '1.0.0',
        entries: [
          for (final n in ids.keys)
            core.ProfileStampEntry(
              sourcePilotNo: n,
              profileId: ids[n]!,
              created: true,
            ),
        ],
      );
      await Future.wait([
        importer.stampProfiles(stamps(), metadata: metadata()),
        importer.stampProfiles(stamps(), metadata: metadata()),
        importer.stampProfiles(stamps(), metadata: metadata()),
      ]);
      expect(await inst.count('import_provenance'), 3);
      expect(await inst.count('audit_events'), 3);
    });

    test('a shared profile survives deleting one contest', () async {
      final ids = await profiles(4);
      await importer.stampProfiles(
        core.ProfileStampPlan(
          owner: signedIn,
          importOperationId: core.Id.create(),
          fileFingerprint: _fingerprint,
          toolVersion: '1.0.0',
          entries: [
            core.ProfileStampEntry(
              sourcePilotNo: 1,
              profileId: ids[1]!,
              created: true,
            ),
          ],
        ),
        metadata: metadata(),
      );
      final a = await importer.importCompetition(
        plan(draft(), ids),
        metadata: metadata(),
      ) as core.CompetitionImported;
      await importer.importCompetition(
        plan(draft(compNo: 23), ids),
        metadata: metadata(),
      );
      await repository.contestRepository.delete(
        a.contestId,
        metadata: metadata(),
      );
      expect(
        await repository.importProvenanceRepository.listForEntity(ids[1]!),
        hasLength(1),
      );
      expect(await inst.count('contests'), 1);
    });

    test('with no account nothing is written', () async {
      final ids = await profiles(1);
      await importer.stampProfiles(
        core.ProfileStampPlan(
          owner: const core.ImportOwner(),
          importOperationId: core.Id.create(),
          fileFingerprint: _fingerprint,
          toolVersion: '1.0.0',
          entries: [
            core.ProfileStampEntry(
              sourcePilotNo: 1,
              profileId: ids[1]!,
              created: true,
            ),
          ],
        ),
        metadata: metadata(),
      );
      expect(await inst.count('import_provenance'), 0);
    });
  });
}

/// Ids that repeat [same] from the [after]-th call on, which breaks the
/// primary key of the next row written.
core.Id Function() _repeatingIds(core.Id same, {required int after}) {
  var calls = 0;
  return () => calls++ < after ? core.Id.create() : same;
}
