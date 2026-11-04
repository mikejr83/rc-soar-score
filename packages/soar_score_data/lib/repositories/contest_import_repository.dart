import 'package:drift/drift.dart' show Variable;
import 'package:soar_score_core/soar_score_core.dart' as core;

import 'audit_event_repository.dart';
import 'discipline_profile_repository.dart';
import 'drift_repository.dart';
import '../sync/sql_placeholders.dart';
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

  // ---------------------------------------------------------------------
  // Restore (ADR 0006, amendment 2)
  // ---------------------------------------------------------------------

  /// The `source_device` of a restored attempt; anything else is a score
  /// somebody entered in Soar Score after the restore.
  static const _restoreDevice = core.GliderScoreRestoreBuilder.sourceDevice;

  @override
  Future<core.RestoreTarget> restoreTarget(
    core.ImportOwner owner,
    core.RestoreIdentity identity,
  ) async {
    final accountId = owner.accountId;
    if (accountId == null) return const core.RestoreTarget.none();
    final stamps = await _stamps.whereSql(
      "owner_account_id = ? AND stamped_entity_type = 'Contest'",
      [Variable<String>(accountId.value)],
    );
    core.ImportProvenance? same;
    core.ImportProvenance? number;
    for (final stamp in stamps) {
      if (stamp.contestId == null) continue;
      if (stamp.dedupeKey == identity.dedupeKey) {
        same = stamp;
        break;
      }
      // Without a CompID the name and date are what tell competitions with
      // the same number apart: a different one is for the director to judge.
      final key = stamp.dedupeKey ?? '';
      if (!identity.hasCompId &&
          key.startsWith('gliderscore:no:${identity.compNo}|') &&
          (number == null || stamp.importedAt.isAfter(number.importedAt))) {
        number = stamp;
      }
    }
    final stamp = same ?? number;
    if (stamp == null) return const core.RestoreTarget.none();
    return _targetOf(
      stamp,
      same != null
          ? core.RestoreTargetKind.same
          : core.RestoreTargetKind.numberMatch,
    );
  }

  Future<core.RestoreTarget> _targetOf(
    core.ImportProvenance stamp,
    core.RestoreTargetKind kind,
  ) async {
    final contestId = stamp.contestId!;
    final contest = await store<core.Contest>('Contest').find(contestId);
    final scoresStamp = [
      for (final s in await _stamps.whereId('contest_id', contestId))
        if (s.stampedEntityType ==
            core.ImportProvenance.contestScoresEntityType)
          s,
    ].firstOrNull;
    final values = stamp.sourceValues ?? const {};
    final contestVar = [Variable<String>(contestId.value)];
    // A native installation has no publication table: the server owns it, and
    // a published contest has reached the server, which `synced` catches.
    final hasPublications = db.profileTables.any(
      (t) => t.actualTableName == 'publication_identities',
    );
    final published = !hasPublications
        ? 0
        : (await db
                  .customSelect(
                    portableSql(
                      db,
                      'SELECT COUNT(*) AS c FROM publication_identities '
                      'WHERE contest_id = ? AND published_at IS NOT NULL',
                    ),
                    variables: contestVar,
                  )
                  .getSingle())
              .read<int>('c');
    final synced = await db
        .customSelect(
          portableSql(
            db,
            'SELECT COUNT(*) AS c FROM mutation_records '
            "WHERE contest_id = ? AND outcome <> 'Pending'",
          ),
          variables: contestVar,
        )
        .getSingle();
    return core.RestoreTarget(
      kind: kind,
      contestId: contestId,
      contestName: contest?.name,
      sourceName: values['name'] as String?,
      sourceDate: values['date'] as String?,
      importedAt: stamp.importedAt,
      storedHash: scoresStamp?.sourceValues?['content_hash'] as String?,
      storedCompleted: scoresStamp?.sourceValues?['completed'] as bool?,
      published: published > 0,
      synced: (synced.read<int>('c')) > 0,
      changes: await _changesSince(contestId),
    );
  }

  /// What was done in Soar Score after the restore, counted from the rows.
  Future<core.ContestChanges> _changesSince(core.Id contestId) async {
    final v = [Variable<String>(contestId.value)];
    final restored = await store<core.ScoreAttempt>('ScoreAttempt').countWhere(
      'contest_id = ? AND source_device = ?',
      [...v, Variable<String>(_restoreDevice)],
    );
    final entered = await store<core.ScoreAttempt>('ScoreAttempt').countWhere(
      'contest_id = ? AND (source_device IS NULL OR source_device <> ?)',
      [...v, Variable<String>(_restoreDevice)],
    );
    final corrected = await store<core.OfficialScore>('OfficialScore')
        .countWhere('contest_id = ? AND score_revision > 1', v);
    final stamps = await _stamps.whereId('contest_id', contestId);
    int stamped(String type) =>
        stamps.where((s) => s.stampedEntityType == type).length;
    final participations = await store<core.ContestParticipation>(
      'ContestParticipation',
    ).countWhere('contest_id = ?', v);
    final revisions = await store<core.MatrixRevision>('MatrixRevision')
        .countWhere('contest_id = ?', v);
    final drawn = await store<core.MatrixAssignment>('MatrixAssignment')
        .countWhere("contest_id = ? AND assignment_type = 'Original'", v);
    final allAssignments = await store<core.MatrixAssignment>(
      'MatrixAssignment',
    ).countWhere('contest_id = ?', v);
    final reflights = await store<core.ReFlight>('ReFlight')
        .countWhere('contest_id = ?', v);
    final configurations = await store<core.ContestConfigurationRevision>(
      'ContestConfigurationRevision',
    ).countWhere('contest_id = ?', v);
    final restoredReflights = await db
        .customSelect(
          portableSql(
            db,
            'SELECT COUNT(*) AS c FROM matrix_assignments '
            "WHERE contest_id = ? AND assignment_type = 'Reflight'",
          ),
          variables: v,
        )
        .getSingle();
    return core.ContestChanges(
      scoresEntered: entered + corrected,
      restoredScores: restored,
      participantsChanged:
          participations !=
          stamped(core.ImportProvenance.participationEntityType),
      drawChanged:
          revisions !=
              stamped(core.ImportProvenance.matrixRevisionEntityType) ||
          allAssignments != drawn + restoredReflights.read<int>('c') ||
          reflights != 0 && restoredReflights.read<int>('c') == 0,
      configurationChanged: configurations > 1,
    );
  }

  @override
  Future<core.RestoreImportResult> importRestore(
    core.RestoreImportPlan plan, {
    required core.MutationMetadata metadata,
  }) async {
    final restore = plan.plan;
    final compNo = restore.sourceCompNo;
    core.CompetitionRestoreFailed fail(String code, [String? detail]) =>
        core.CompetitionRestoreFailed(compNo, code, detail: detail);

    final owner = plan.owner.accountId;
    if (owner == null) return fail(core.RestoreFailure.noAccount);
    final draft = restore.contest;
    final drawDraft = restore.draw;
    final config = draft.config;
    if (!restore.isImportable ||
        drawDraft == null ||
        config == null ||
        draft.name == null ||
        draft.startDate == null) {
      return fail(core.RestoreFailure.notImportable);
    }
    final profile = await _pinnedProfile(draft.disciplineType);
    if (profile == null) return fail(core.RestoreFailure.profileUnavailable);
    try {
      config.coreOptions;
      core.DisciplineConfigValidator.validate(profile, config.discipline);
    } on Object catch (error) {
      return fail(core.RestoreFailure.configInvalid, '$error');
    }

    final members = <_Member>[];
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
          core.RestoreFailure.profileMissing,
          '${participant.sourcePilotNo}',
        );
      }
      members.add((draft: participant, profileId: profileId));
    }

    try {
      return await unitOfWork.run<core.RestoreImportResult>((context) async {
        final target = await _restoreTargetFor(plan);
        if (target is core.CompetitionRefused) return target;
        final existing = target is core.RestoreTarget ? target : null;
        if (existing != null) {
          final refusal = _replaceRefusal(plan, existing);
          if (refusal != null) return refusal;
          if (existing.isUnchanged(restore.contentHash, plan.completed)) {
            return core.CompetitionUnchanged(
              compNo,
              contestId: existing.contestId!,
              importedAt: existing.importedAt,
            );
          }
          await _wipe(existing.contestId!);
        }
        final contestId = existing?.contestId ?? plan.contestId ?? _newId();
        return _restore(
          context,
          plan,
          profile,
          owner,
          contestId,
          members,
          skipped,
          updated: existing != null,
          metadata: metadata,
        );
      });
    } on _GateFailed catch (failed) {
      return failed.result;
    } on Object catch (error) {
      return fail(core.RestoreFailure.failed, '$error');
    }
  }

  /// The contest the plan replaces: a [core.RestoreTarget], null when it makes
  /// a new one, or a refusal.
  Future<Object?> _restoreTargetFor(core.RestoreImportPlan plan) async {
    final compNo = plan.plan.sourceCompNo;
    final forced = plan.updateContestId;
    if (forced == null) {
      final target = await restoreTarget(plan.owner, plan.plan.identity);
      return target.kind == core.RestoreTargetKind.same ? target : null;
    }
    final stamps = [
      for (final s in await _stamps.whereId('contest_id', forced))
        if (s.stampedEntityType == core.ImportProvenance.contestEntityType &&
            s.ownerAccountId == plan.owner.accountId &&
            (s.dedupeKey ?? '').startsWith('gliderscore:'))
          s,
    ];
    if (stamps.isEmpty) {
      return core.CompetitionRefused(
        compNo,
        core.RestoreRefusal.notRestorable,
        contestId: forced,
      );
    }
    return _targetOf(stamps.first, core.RestoreTargetKind.same);
  }

  core.CompetitionRefused? _replaceRefusal(
    core.RestoreImportPlan plan,
    core.RestoreTarget target,
  ) {
    final compNo = plan.plan.sourceCompNo;
    core.CompetitionRefused refuse(String code) =>
        core.CompetitionRefused(compNo, code, contestId: target.contestId);
    if (target.published) {
      return refuse(core.RestoreRefusal.resultsPublished);
    }
    if (target.synced) return refuse(core.RestoreRefusal.contestSynced);
    if (target.changes.any &&
        !target.isUnchanged(plan.plan.contentHash, plan.completed) &&
        !plan.confirmedReplace) {
      return refuse(core.RestoreRefusal.needsConfirmation);
    }
    return null;
  }

  /// Removes the earlier restore of [contestId], mutation records included.
  ///
  /// Only a contest that never reached the server is replaced this way, so
  /// the rows it described exist nowhere else and the outbox entries that
  /// would send them go with them. The contest is then written again, under
  /// the same id.
  Future<void> _wipe(core.Id contestId) async {
    await store<core.ImportProvenance>('ImportProvenance')
        .removeWhereId('contest_id', contestId);
    await db.customStatement(
      portableSql(db, 'DELETE FROM mutation_records WHERE contest_id = ?'),
      [contestId.value],
    );
    await db.customStatement(
      portableSql(db, 'DELETE FROM tombstones WHERE contest_id = ?'),
      [contestId.value],
    );
    // Children go with the contest (foreign keys cascade).
    await store<core.Contest>('Contest').remove(contestId);
  }

  Future<core.RestoreImportResult> _restore(
    core.WriteContext context,
    core.RestoreImportPlan plan,
    core.DisciplineProfileWithRules profile,
    core.Id owner,
    core.Id contestId,
    List<_Member> members,
    List<int> skipped, {
    required bool updated,
    required core.MutationMetadata metadata,
  }) async {
    final restore = plan.plan;
    final compNo = restore.sourceCompNo;
    final identity = restore.identity;
    final draft = restore.contest;
    final now = _clock();
    final writes = _Writes(metadata);

    final landingTableId = await _pinLandingTable(
      context,
      restore.landing,
      owner,
      now,
      writes,
    );
    final importPlan = core.CompetitionImportPlan(
      draft: draft,
      profileIds: plan.profileIds,
      owner: plan.owner,
      timezone: plan.timezone,
      importOperationId: plan.importOperationId,
      fileFingerprint: plan.fileFingerprint,
      toolVersion: plan.toolVersion,
      contestId: contestId,
    );
    final participationIds = await _write(
      context,
      importPlan,
      profile,
      owner,
      contestId,
      identity.dedupeKey,
      members,
      writes,
      metadata,
      landingTableId: landingTableId,
      extraContestValues: {
        if (identity.compId != null) 'comp_id': identity.compId,
        'name': identity.name,
        'date': identity.date,
      },
    );

    // The draw, through the builder a drawn matrix uses.
    final contest = (await store<core.Contest>('Contest').find(contestId))!;
    final configuration = (await store<core.ContestConfigurationRevision>(
      'ContestConfigurationRevision',
    ).whereId('contest_id', contestId, orderBy: 'revision_number')).last;
    final options = configuration.config.coreOptions;
    final participations = await store<core.ContestParticipation>(
      'ContestParticipation',
    ).whereId('contest_id', contestId);
    final teamOf = options.teamsEnabled
        ? {
            for (final m in await store<core.TeamMembership>(
              'TeamMembership',
            ).whereId('contest_id', contestId))
              m.contestParticipationId: m.teamId,
          }
        : const <core.Id, core.Id>{};
    final imported = core.GliderScoreDrawBuilder(newId: _newId).build(
      draft: restore.draw!,
      contest: contest,
      options: options,
      participations: participations,
      participationIds: participationIds,
      teamOf: teamOf,
      owner: plan.owner,
      operationId: plan.importOperationId,
      fileFingerprint: plan.fileFingerprint,
      toolVersion: plan.toolVersion,
      metadata: metadata,
      now: now,
    );
    final rows = core.GliderScoreRestoreBuilder(newId: _newId).build(
      plan: restore,
      draw: imported,
      participations: participations,
      participationIds: participationIds,
      contestId: contestId,
      configRevisionId: configuration.id,
      actorId: owner,
      operationId: plan.importOperationId,
      fileFingerprint: plan.fileFingerprint,
      toolVersion: plan.toolVersion,
      metadata: metadata,
      completed: plan.completed,
      now: now,
    );
    await _writeRestored(context, imported, rows, metadata);

    // The final state.
    var state = imported.contest;
    final finalState = restore.finalState(completed: plan.completed);
    if (finalState != core.RestoreFinalState.ready) {
      state = state.copyWithState(
        lifecycleState: core.LifecycleState.running,
        updatedAt: now,
      );
    }
    if (finalState == core.RestoreFinalState.completed) {
      state = core.ContestLifecycle.apply(
        state,
        core.ContestAction.complete,
        now,
      );
      state = core.ContestLifecycle.apply(state, core.ContestAction.lock, now);
    }
    await context.save(state, metadata: writes.next());
    for (final audit in [...imported.audits, rows.audit]) {
      await _audits.append(audit);
    }
    for (final stamp in [...imported.stamps, rows.stamp]) {
      await context.save(stamp, metadata: writes.next());
    }

    // The gate: recalculate every restored flight and compare.
    final results = configuration.landingTableId == null
        ? const <core.LandingResult>[]
        : await store<core.LandingResult>('LandingResult')
              .whereId('landing_table_id', configuration.landingTableId!);
    final comparison = const core.GliderScoreRestoreComparison().check(
      restore.flights,
      overrides: configuration.config.discipline,
      landingPoints: {
        for (final r in results) r.entryKey: r.pointValue.toDouble(),
      },
    );
    if (!comparison.passed) {
      throw _GateFailed(
        core.CompetitionRestoreFailed(
          compNo,
          core.RestoreFailure.comparisonFailed,
          mismatches: comparison.mismatches,
          mismatchCount: comparison.mismatchCount,
        ),
      );
    }
    return core.CompetitionRestored(
      compNo,
      contestId: contestId,
      updated: updated,
      participationCount: members.length,
      flightCount: rows.flightCount,
      finalState: finalState,
      skippedParticipants: skipped,
    );
  }

  /// The landing table the restored flights landed on: a shipped table, one
  /// the same director already rebuilt from the same competition table, or a
  /// new one. Null leaves the profile's default.
  Future<core.Id?> _pinLandingTable(
    core.WriteContext context,
    core.LandingSelection? landing,
    core.Id owner,
    DateTime now,
    _Writes writes,
  ) async {
    if (landing == null || landing.match == core.LandingMatch.none) {
      return null;
    }
    if (landing.systemTable == 'f5jDistance') {
      return core.SystemLandingTables.f5jDistanceId;
    }
    if (landing.systemTable != null) {
      return core.SystemLandingTables.f5jStandardId;
    }
    final name = landing.reconstructedName ?? 'GliderScore landing table';
    final wanted = {for (final e in landing.entries) e.entryKey: e.points};
    for (final table in await store<core.LandingTable>(
      'LandingTable',
    ).whereId('owner_account_id', owner)) {
      if (table.name != name || table.inputUnit != landing.inputUnit) continue;
      final results = await store<core.LandingResult>('LandingResult')
          .whereId('landing_table_id', table.id);
      if (results.length == wanted.length &&
          results.every((r) => wanted[r.entryKey] == r.pointValue)) {
        return table.id;
      }
    }
    final table = core.LandingTable(
      id: _newId(),
      ownerAccountId: owner,
      name: name,
      inputUnit: landing.inputUnit,
      createdAt: now,
    );
    await context.appendLandingTable(
      core.LandingTableWithResults(
        table: table,
        results: [
          for (final (i, e) in landing.entries.indexed)
            core.LandingResult(
              id: _newId(),
              landingTableId: table.id,
              entryKey: e.entryKey,
              displayValue: e.label,
              pointValue: e.points,
              ordinalPosition: i,
            ),
        ],
      ),
      metadata: writes.next(),
    );
    return table.id;
  }

  Future<void> _writeRestored(
    core.WriteContext context,
    core.ImportedDraw imported,
    core.RestoredRows rows,
    core.MutationMetadata metadata,
  ) async {
    core.MutationMetadata part(core.Id id) => metadata.forPart(id.value);
    final rounds = {for (final r in rows.rounds) r.id: r};
    final groups = {for (final g in rows.groups) g.id: g};
    for (final built in imported.revisions) {
      final draw = built.draw;
      await context.append(draw.revision, metadata: part(draw.revision.id));
      for (final round in draw.rounds) {
        await context.save(rounds[round.id]!, metadata: part(round.id));
      }
      for (final group in draw.groups) {
        await context.save(groups[group.id]!, metadata: part(group.id));
      }
      for (final assignment in draw.assignments) {
        await context.append(assignment, metadata: part(assignment.id));
      }
      for (final placeholder in built.placeholders) {
        await context.save(placeholder, metadata: part(placeholder.id));
      }
    }
    for (final reflight in rows.reflights) {
      await context.save(
        reflight.reFlight,
        metadata: part(reflight.reFlight.id),
      );
      await context.save(reflight.group, metadata: part(reflight.group.id));
      for (final assignment in reflight.assignments) {
        await context.append(assignment, metadata: part(assignment.id));
      }
      for (final placeholder in reflight.placeholders) {
        await context.save(placeholder, metadata: part(placeholder.id));
      }
      for (final participant in reflight.participants) {
        await context.save(participant, metadata: part(participant.id));
      }
    }
    for (final participation in rows.participations) {
      await context.save(participation, metadata: part(participation.id));
    }
    final scored = [
      ...rows.scores,
      for (final reflight in rows.reflights) ...reflight.scores,
    ];
    for (final score in scored) {
      await context.append(score.attempt, metadata: part(score.attempt.id));
      await context.append(score.official, metadata: part(score.official.id));
      await context.save(
        score.placeholder,
        metadata: metadata.forPart('${score.placeholder.id.value}/scored'),
      );
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

  /// Writes the contest, its first configuration revision, roles, teams,
  /// participations, model links and stamps. Returns the participation of
  /// each written GliderScore pilot.
  ///
  /// A restore passes [landingTableId] (the table its flights landed on) and
  /// [extraContestValues] (what identifies the competition on re-import).
  Future<Map<int, core.Id>> _write(
    core.WriteContext context,
    core.CompetitionImportPlan plan,
    core.DisciplineProfileWithRules profile,
    core.Id owner,
    core.Id contestId,
    String dedupeKey,
    List<_Member> members,
    _Writes writes,
    core.MutationMetadata metadata, {
    core.Id? landingTableId,
    Map<String, Object?> extraContestValues = const {},
  }) async {
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
      ...extraContestValues,
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
          ? landingTableId ?? profile.profile.defaultLandingTableId
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

    final participationIds = <int, core.Id>{};
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
      participationIds[p.sourcePilotNo] = participation.id;
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
    return participationIds;
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

/// Thrown inside the restore's transaction to roll it back with a result.
class _GateFailed implements Exception {
  _GateFailed(this.result);

  final core.RestoreImportResult result;
}
