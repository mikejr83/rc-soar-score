import '../enums/draw_mode.dart';
import '../enums/lifecycle_state.dart';
import '../models/contest/contest.dart';
import '../models/contest/core_options.dart';
import '../models/id.dart';
import '../models/imports/contest_import_plan.dart';
import '../models/imports/draw_import_draft.dart';
import '../models/imports/import_provenance.dart';
import '../models/participants/contest_participation.dart';
import '../repositories/mutation_metadata.dart';
import '../models/sync/audit_event.dart';
import '../enums/audit_action.dart';
import '../enums/audit_outcome.dart';
import 'glider_score_draw_mapper.dart';
import 'matrix/basic_draw.dart';
import 'matrix/draw_fairness.dart';
import 'matrix/matrix_draw_builder.dart';

/// The rows one imported draw writes, ready to store in one transaction.
class ImportedDraw {
  ImportedDraw({
    required Iterable<BuiltDraw> revisions,
    required Iterable<ContestParticipation> numberedParticipations,
    required this.contest,
    required Iterable<ImportProvenance> stamps,
    required Iterable<AuditEvent> audits,
  }) : revisions = List.unmodifiable(revisions),
       numberedParticipations = List.unmodifiable(numberedParticipations),
       stamps = List.unmodifiable(stamps),
       audits = List.unmodifiable(audits);

  /// The finalized revisions, oldest first; each extends the one before.
  final List<BuiltDraw> revisions;

  /// Participations that received a participant number.
  final List<ContestParticipation> numberedParticipations;

  /// The contest, `Ready`.
  final Contest contest;

  /// One stamp per revision.
  final List<ImportProvenance> stamps;

  /// A `Restoration` event for the contest and one per revision.
  final List<AuditEvent> audits;
}

/// Builds the stored form of a [DrawImportDraft] through the same
/// [MatrixDrawBuilder] a drawn matrix uses, so revisions, rounds, groups,
/// assignments and score placeholders look like any other finalized draw.
///
/// Pure: ids come from [newId], time from the caller. Phase D reuses it for
/// the draw it restores together with the scores.
class GliderScoreDrawBuilder {
  GliderScoreDrawBuilder({required this.newId});

  final Id Function() newId;

  /// Builds [draft] for [contest].
  ///
  /// [participationIds] maps a GliderScore `PilotNo` to its participation;
  /// [teamOf] maps a participation to its team when teams are on.
  /// [participations] are all the contest's participations, for the numbers a
  /// first finalized draw hands out. Throws a [StateError] naming the pilot
  /// when the draft holds a pilot without a participation: the caller checks
  /// first.
  ImportedDraw build({
    required DrawImportDraft draft,
    required Contest contest,
    required CoreOptions options,
    required List<ContestParticipation> participations,
    required Map<int, Id> participationIds,
    Map<Id, Id> teamOf = const {},
    required ImportOwner owner,
    required Id operationId,
    required String fileFingerprint,
    required String toolVersion,
    required MutationMetadata metadata,
    required DateTime now,
  }) {
    final actor = owner.accountId!;
    final builder = MatrixDrawBuilder(newId: newId);
    final slotsByRound = <List<List<DrawSlot>>>[];
    final built = <BuiltDraw>[];
    final stamps = <ImportProvenance>[];
    final audits = <AuditEvent>[];
    Id? previous;

    DrawPilot pilot(int pilotNo) {
      final id = participationIds[pilotNo];
      if (id == null) {
        throw StateError('pilot $pilotNo has no participation');
      }
      return DrawPilot(id, teamId: teamOf[id]);
    }

    for (final revision in draft.revisions) {
      final drawn = <List<List<DrawSlot>>>[
        for (final round in revision.rounds)
          [
            for (final group in round.groups)
              [
                for (final a in group.assignments)
                  DrawSlot(pilot(a.sourcePilotNo), a.lane),
              ],
          ],
      ];
      slotsByRound.addAll(drawn);
      final id = newId();
      final result = builder.build(
        contestId: contest.id,
        id: id,
        revisionNumber: revision.revisionNumber,
        previousRevisionId: previous,
        firstRound: revision.firstRound,
        drawn: drawn,
        seed: 0,
        algorithmVersion: GliderScoreDrawMapper.algorithmVersion,
        groupsPerRound: revision.groupsPerRound,
        drawConfig: {
          'schema_version': 1,
          'team_protection': draft.teamProtection,
          'allow_back_to_back': options.allowBackToBack,
          'lane_mode': options.laneMode.json,
          'configured_draw_mode': options.drawMode.json,
          'imported_from': 'gliderscore',
        },
        pilots: const [],
        fairness: drawFairness(
          slotsByRound,
          teamProtection: draft.teamProtection,
        ),
        reason:
            'imported from GliderScore competition ${draft.sourceCompNo}, '
            'task ${revision.taskNo}',
        actorId: actor,
        now: now,
        drawMode: DrawMode.standardManOnMan,
      );
      built.add(result);
      previous = id;

      stamps.add(
        ImportProvenance(
          id: newId(),
          ownerAccountId: owner.accountId!,
          contestId: contest.id,
          stampedEntityType: ImportProvenance.matrixRevisionEntityType,
          stampedEntityId: id,
          sourceSystem: ImportProvenance.gliderScore,
          sourceKeys: {
            'comp_no': draft.sourceCompNo,
            'task_no': revision.taskNo,
          },
          sourceValues: {
            'first_round': revision.firstRound,
            'last_round': revision.lastRound,
            'groups_per_round': revision.groupsPerRound,
            // Without a lane count the position is the only trace of the
            // order GliderScore drew the group in.
            if (draft.laneCount == 0)
              'positions': [
                for (final round in revision.rounds)
                  for (final group in round.groups)
                    for (final a in group.assignments)
                      [round.ordinal, group.groupNo, a.sourcePilotNo, a.seqNo],
              ],
          },
          fileFingerprint: fileFingerprint,
          importOperationId: operationId,
          toolVersion: toolVersion,
          importedAt: now,
        ),
      );
      audits.add(
        _restoration(
          entityType: 'MatrixRevision',
          entityId: id,
          contestId: contest.id,
          operationId: operationId,
          metadata: metadata,
          now: now,
          base: revision.revisionNumber > 1
              ? revision.revisionNumber - 1
              : null,
          resulting: revision.revisionNumber,
        ),
      );
    }

    final ready = contest.copyWithState(
      lifecycleState: LifecycleState.ready,
      updatedAt: now,
    );
    audits.insert(
      0,
      _restoration(
        entityType: contest.entityType,
        entityId: contest.id,
        contestId: contest.id,
        operationId: operationId,
        metadata: metadata,
        now: now,
        base: contest.revision,
        resulting: contest.revision + 1,
      ),
    );
    return ImportedDraw(
      revisions: built,
      numberedParticipations: MatrixDrawBuilder.numbered(participations),
      contest: ready,
      stamps: stamps,
      audits: audits,
    );
  }

  AuditEvent _restoration({
    required String entityType,
    required Id entityId,
    required Id contestId,
    required Id operationId,
    required MutationMetadata metadata,
    required DateTime now,
    int? base,
    int? resulting,
  }) => AuditEvent(
    id: newId(),
    entityType: entityType,
    entityId: entityId,
    contestId: contestId,
    action: AuditAction.restoration,
    actorId: metadata.actorId,
    authority: metadata.authority,
    installationId: metadata.sourceInstallationId,
    device: metadata.sourceDevice,
    baseRevision: base,
    resultingRevision: resulting,
    serverTimestamp: now,
    clientTimestamp: metadata.clientTime,
    reason: 'import:gliderscore:${operationId.value}',
    outcome: AuditOutcome.success,
  );
}
