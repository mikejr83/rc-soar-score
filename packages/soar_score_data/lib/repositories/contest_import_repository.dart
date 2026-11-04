import 'package:soar_score_core/soar_score_core.dart' as core;

import 'audit_event_repository.dart';
import 'discipline_profile_repository.dart';
import 'drift_repository.dart';
import 'unique_violation.dart';

/// Writes imported competitions as contests (ADR 0006).
///
/// Every competition is one unit of work: a failure part-way keeps nothing of
/// it, and other competitions are unaffected. Writes go through the unit of
/// work, so revisions, mutation records and sync behave as for a contest made
/// by hand.
class ContestImportRepository extends DriftRepository
    implements core.ContestImportRepository {
  ContestImportRepository(
    super.db, {
    super.stores,
    DateTime Function()? clock,
    core.Id Function()? newId,
  }) : _clock = clock ?? (() => DateTime.now().toUtc()),
       _newId = newId ?? core.Id.create;

  final DateTime Function() _clock;
  final core.Id Function() _newId;

  late final _audits = AuditEventRepository(db, stores: stores);
  late final _stamps = store<core.ImportProvenance>('ImportProvenance');

  @override
  Future<void> stampProfiles(
    core.ProfileStampPlan plan, {
    required core.MutationMetadata metadata,
  }) async {
    if (plan.owner.accountId == null || plan.entries.isEmpty) return;
    // Two callers with the same plan can both see no stamp and race to insert;
    // the unique index lets one win. The loser's transaction is rolled back,
    // so it reads again, finds the winner's stamps and writes nothing.
    for (var attempt = 1; ; attempt++) {
      try {
        await _stampProfiles(plan, metadata);
        return;
      } on Object catch (error) {
        if (attempt >= 3 || !isUniqueViolation(error)) rethrow;
      }
    }
  }

  Future<void> _stampProfiles(
    core.ProfileStampPlan plan,
    core.MutationMetadata metadata,
  ) async {
    final owner = plan.owner.accountId!;
    final now = _clock();
    final writes = _Writes(metadata);
    await unitOfWork.run((context) async {
      for (final entry in plan.entries) {
        final known = await _stamps.whereId(
          'stamped_entity_id',
          entry.profileId,
        );
        if (known.any((s) => s.importOperationId == plan.importOperationId)) {
          continue;
        }
        await context.save(
          core.ImportProvenance(
            id: _newId(),
            ownerAccountId: owner,
            stampedEntityType: core.ImportProvenance.profileEntityType,
            stampedEntityId: entry.profileId,
            sourceSystem: plan.sourceSystem,
            sourceKeys: {'pilot_no': entry.sourcePilotNo},
            fileFingerprint: plan.fileFingerprint,
            importOperationId: plan.importOperationId,
            toolVersion: plan.toolVersion,
            importedAt: now,
          ),
          metadata: writes.next(),
        );
        await _audits.append(
          _audit(
            entityType: 'ParticipantProfile',
            entityId: entry.profileId,
            owner: owner,
            operation: plan.importOperationId,
            metadata: metadata,
            now: now,
            note: entry.created ? 'created' : 'updated',
          ),
        );
      }
    });
  }

  @override
  Future<core.CompetitionImportResult> importCompetition(
    core.CompetitionImportPlan plan, {
    required core.MutationMetadata metadata,
  }) async {
    final draft = plan.draft;
    final compNo = draft.sourceCompNo;
    core.CompetitionImportFailed fail(String code, [String? detail]) =>
        core.CompetitionImportFailed(compNo, code, detail);

    final owner = plan.owner.accountId;
    if (owner == null) return fail(core.CompetitionImportFailure.noAccount);
    final config = draft.config;
    final name = draft.name;
    final startDate = draft.startDate;
    if (!draft.isImportable ||
        config == null ||
        name == null ||
        startDate == null) {
      return fail(core.CompetitionImportFailure.notImportable);
    }

    final dedupeKey = core.ProvenanceKeys.contestDedupeKey(
      sourceSystem: core.ImportProvenance.gliderScore,
      fileFingerprint: plan.fileFingerprint,
      compNo: compNo,
    );
    final earlier = await _earlier(owner, dedupeKey, compNo);
    if (earlier != null) return earlier;

    final profile = await _pinnedProfile(draft.disciplineType);
    if (profile == null) {
      return fail(core.CompetitionImportFailure.profileUnavailable);
    }
    try {
      config.coreOptions;
      core.DisciplineConfigValidator.validate(profile, config.discipline);
    } on Object catch (error) {
      return fail(core.CompetitionImportFailure.configInvalid, '$error');
    }

    final written = <_Member>[];
    final skipped = <int>[];
    for (final participant in draft.participants) {
      final profileId = plan.profileIds[participant.sourcePilotNo];
      if (profileId == null) {
        skipped.add(participant.sourcePilotNo);
        continue;
      }
      final stored = await store<core.ParticipantProfile>('ParticipantProfile')
          .find(profileId);
      if (stored == null || stored.ownerAccountId != owner) {
        return fail(
          core.CompetitionImportFailure.profileMissing,
          '${participant.sourcePilotNo}',
        );
      }
      written.add((draft: participant, profileId: profileId));
    }

    try {
      final contestId = plan.contestId ?? _newId();
      await unitOfWork.run(
        (context) => _write(
          context,
          plan,
          profile,
          owner,
          contestId,
          dedupeKey,
          written,
          _Writes(metadata),
          metadata,
        ),
      );
      return core.CompetitionImported(
        compNo,
        contestId: contestId,
        participationCount: written.length,
        skippedParticipants: skipped,
      );
    } on Object catch (error) {
      if (isUniqueViolation(error)) {
        final raced = await _earlier(owner, dedupeKey, compNo);
        if (raced != null) return raced;
      }
      return fail(core.CompetitionImportFailure.failed, '$error');
    }
  }

  Future<core.CompetitionAlreadyImported?> _earlier(
    core.Id owner,
    String dedupeKey,
    int compNo,
  ) async {
    final found = await _stamps.whereIdAndText(
      'owner_account_id',
      owner,
      textColumn: 'dedupe_key',
      text: dedupeKey,
      limit: 1,
    );
    if (found.isEmpty) return null;
    final stamp = found.first;
    return core.CompetitionAlreadyImported(
      compNo,
      contestId: stamp.contestId,
      importedAt: stamp.importedAt,
      importOperationId: stamp.importOperationId,
    );
  }

  /// The newest published system profile of the discipline (ADR 0006).
  Future<core.DisciplineProfileWithRules?> _pinnedProfile(
    String? disciplineType,
  ) async {
    if (disciplineType == null) return null;
    final published = await DisciplineProfileRepository(
      db,
      stores: stores,
    ).listPublished();
    core.DisciplineProfileWithRules? best;
    for (final candidate in published) {
      final p = candidate.profile;
      if (p.status != core.ProfileStatus.published) continue;
      if (p.type.name.toUpperCase() != disciplineType.toUpperCase()) continue;
      if (best == null || p.version > best.profile.version) best = candidate;
    }
    return best;
  }

  Future<void> _write(
    core.WriteContext context,
    core.CompetitionImportPlan plan,
    core.DisciplineProfileWithRules profile,
    core.Id owner,
    core.Id contestId,
    String dedupeKey,
    List<_Member> members,
    _Writes writes,
    core.MutationMetadata metadata,
  ) async {
    final draft = plan.draft;
    final compNo = draft.sourceCompNo;
    final now = _clock();
    final day = draft.startDate!;
    final noon = DateTime.utc(day.year, day.month, day.day, 12);

    // The contest and its stamp first, so a repeated import fails early.
    var contest = await context.save(
      core.Contest(
        id: contestId,
        name: draft.name!,
        startDateTime: noon,
        endDateTime: noon,
        timezone: plan.timezone,
        host: draft.host,
        ownerAccountId: owner,
        createdAt: now,
        updatedAt: now,
      ),
      metadata: writes.next(),
    );
    core.ImportProvenance stamp({
      required String type,
      required core.Id entity,
      required Map<String, Object?> keys,
      Map<String, Object?>? values,
      String? key,
    }) => core.ImportProvenance(
      id: _newId(),
      ownerAccountId: owner,
      contestId: contestId,
      stampedEntityType: type,
      stampedEntityId: entity,
      sourceSystem: core.ImportProvenance.gliderScore,
      sourceKeys: keys,
      sourceValues: values,
      fileFingerprint: plan.fileFingerprint,
      dedupeKey: key,
      importOperationId: plan.importOperationId,
      toolVersion: plan.toolVersion,
      importedAt: now,
    );
    final sourceValues = {
      if (draft.sourceLaneCount != null) 'lane_count': draft.sourceLaneCount,
      if (draft.sourceLandingTableNo != null)
        'landing_table_no': draft.sourceLandingTableNo,
    };
    await context.save(
      stamp(
        type: core.ImportProvenance.contestEntityType,
        entity: contestId,
        keys: {'comp_no': compNo},
        values: sourceValues.isEmpty ? null : sourceValues,
        key: dedupeKey,
      ),
      metadata: writes.next(),
    );

    // The first configuration revision, which moves the contest on.
    final scoresLandings = profile.configFields.any(
      (f) => f.fieldType == core.ConfigFieldType.landing,
    );
    final revision = core.ContestConfigurationRevision(
      id: _newId(),
      contestId: contestId,
      revisionNumber: 1,
      disciplineProfileId: profile.profile.id,
      config: draft.config!,
      landingTableId: scoresLandings
          ? profile.profile.defaultLandingTableId
          : null,
      createdBy: owner,
      createdAt: now,
    );
    await context.append(revision, metadata: writes.next());
    contest = await context.save(
      core.ContestConfigurationRules.apply(contest, null, revision, now),
      metadata: writes.next(),
    );

    // Roles: the system ones, and the director's own Competition Director.
    final roleIds = <core.ImportedRole, core.Id>{
      core.ImportedRole.pilot: core.SystemRoles.pilotId,
      core.ImportedRole.helper: core.SystemRoles.helperId,
      core.ImportedRole.teamManager: core.SystemRoles.teamManagerId,
    };
    final roleNames = <core.ImportedRole, String>{
      core.ImportedRole.pilot: core.SystemRoles.pilot.displayName,
      core.ImportedRole.helper: core.SystemRoles.helper.displayName,
      core.ImportedRole.teamManager: core.SystemRoles.teamManager.displayName,
    };
    if (members.any(
      (m) => m.draft.role == core.ImportedRole.competitionDirector,
    )) {
      final role = await _competitionDirectorRole(context, owner, writes);
      roleIds[core.ImportedRole.competitionDirector] = role.id;
      roleNames[core.ImportedRole.competitionDirector] = role.displayName;
    }

    // Teams the participants belong to.
    final teamIds = <int, core.Id>{};
    for (final team in draft.teams) {
      if (!members.any((m) => m.draft.sourceTeamNo == team.sourceTeamNo)) {
        continue;
      }
      final saved = await context.save(
        core.Team(id: _newId(), contestId: contestId, name: team.name),
        metadata: writes.next(),
      );
      teamIds[team.sourceTeamNo] = saved.id;
    }

    for (final member in members) {
      final p = member.draft;
      final flies = p.role.flies;
      final participation = await context.save(
        core.ContestParticipation(
          id: _newId(),
          contestId: contestId,
          participantProfileId: member.profileId,
          classification: flies ? p.classification : null,
          roleId: roleIds[p.role]!,
          roleName: roleNames[p.role]!,
          roleType: flies ? core.RoleType.pilot : core.RoleType.nonFlier,
          participantNumber: flies ? p.participantNumber : null,
          scoringUuid: core.ScoringUuid.create(),
        ),
        metadata: writes.next(),
      );
      await context.save(
        stamp(
          type: core.ImportProvenance.participationEntityType,
          entity: participation.id,
          keys: {'comp_no': compNo, 'pilot_no': p.sourcePilotNo},
        ),
        metadata: writes.next(),
      );
      final teamId = p.sourceTeamNo == null ? null : teamIds[p.sourceTeamNo];
      if (teamId != null) {
        await context.save(
          core.TeamMembership(
            id: _newId(),
            teamId: teamId,
            contestParticipationId: participation.id,
            contestId: contestId,
          ),
          metadata: writes.next(),
        );
      }
      final model = p.modelName?.trim();
      if (flies && model != null && model.isNotEmpty) {
        await context.save(
          core.ContestModelLink(
            id: _newId(),
            contestId: contestId,
            contestParticipationId: participation.id,
            modelName: model,
            modelId: p.modelId,
          ),
          metadata: writes.next(),
        );
      }
    }

    await _audits.append(
      _audit(
        entityType: contest.entityType,
        entityId: contestId,
        contestId: contestId,
        operation: plan.importOperationId,
        metadata: metadata,
        now: now,
        baseRevision: 0,
        resultingRevision: contest.revision,
      ),
    );
  }

  /// The director's own non-flier "Competition Director" role, created once.
  Future<core.Role> _competitionDirectorRole(
    core.WriteContext context,
    core.Id owner,
    _Writes writes,
  ) async {
    const name = 'Competition Director';
    final roles = store<core.Role>('Role');
    for (final role in await roles.whereId('owner_account_id', owner)) {
      if (role.displayName.toLowerCase() == name.toLowerCase() &&
          role.type == core.RoleType.nonFlier) {
        return role;
      }
    }
    return context.save(
      core.Role(
        id: _newId(),
        ownerAccountId: owner,
        displayName: name,
        type: core.RoleType.nonFlier,
      ),
      metadata: writes.next(),
    );
  }

  core.AuditEvent _audit({
    required String entityType,
    required core.Id entityId,
    required core.Id operation,
    required core.MutationMetadata metadata,
    required DateTime now,
    core.Id? contestId,
    core.Id? owner,
    String? note,
    int? baseRevision,
    int? resultingRevision,
  }) => core.AuditEvent(
    id: _newId(),
    entityType: entityType,
    entityId: entityId,
    contestId: contestId,
    ownerAccountId: contestId == null ? owner : null,
    action: core.AuditAction.stateTransition,
    actorId: metadata.actorId,
    authority: metadata.authority,
    installationId: metadata.sourceInstallationId,
    device: metadata.sourceDevice,
    baseRevision: baseRevision,
    resultingRevision: resultingRevision,
    serverTimestamp: now,
    clientTimestamp: metadata.clientTime,
    reason:
        'import:gliderscore:${operation.value}${note == null ? '' : ':$note'}',
    outcome: core.AuditOutcome.success,
  );
}

/// A participant to write with the profile the director chose for them.
typedef _Member = ({core.ParticipationDraft draft, core.Id profileId});

/// Hands out a distinct request id per write: the mutation log is unique on
/// (scope, request id).
class _Writes {
  _Writes(this._base);

  final core.MutationMetadata _base;
  var _count = 0;

  core.MutationMetadata next() => core.MutationMetadata(
    clientMutationId: '${_base.clientMutationId}:${_count++}',
    authority: _base.authority,
    clientTime: _base.clientTime,
    actorId: _base.actorId,
    sourceInstallationId: _base.sourceInstallationId,
    sourceDevice: _base.sourceDevice,
    dependsOnMutationId: _base.dependsOnMutationId,
  );
}
