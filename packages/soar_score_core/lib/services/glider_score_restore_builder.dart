import '../enums/audit_action.dart';
import '../enums/audit_outcome.dart';
import '../enums/authority.dart';
import '../enums/group_status.dart';
import '../enums/re_flight_status.dart';
import '../enums/re_flight_type.dart';
import '../enums/round_status.dart';
import '../enums/score_placeholder_state.dart';
import '../enums/assignment_type.dart';
import '../models/id.dart';
import '../models/imports/import_provenance.dart';
import '../models/imports/restore_plan.dart';
import '../models/matrix/matrix_assignment.dart';
import '../models/matrix/re_flight.dart';
import '../models/matrix/re_flight_participant.dart';
import '../models/matrix/round.dart';
import '../models/matrix/round_group.dart';
import '../models/participants/contest_participation.dart';
import '../models/scores/official_score.dart';
import '../models/scores/score_attempt.dart';
import '../models/scores/score_placeholder.dart';
import '../models/sync/audit_event.dart';
import '../repositories/mutation_metadata.dart';
import 'glider_score_draw_builder.dart';

/// One restored score: the attempt and official score for a placeholder, and
/// the placeholder in its final state.
class RestoredScoreRows {
  const RestoredScoreRows({
    required this.attempt,
    required this.official,
    required this.placeholder,
  });

  final ScoreAttempt attempt;
  final OfficialScore official;

  /// The placeholder as it ends: `Official`, score revision 1. It carries
  /// the revision the unscored placeholder is stored with, so it replaces it.
  final ScorePlaceholder placeholder;
}

/// One re-flown group with everything it needs written, in write order.
class RestoredReflightRows {
  const RestoredReflightRows({
    required this.reFlight,
    required this.group,
    required this.assignments,
    required this.placeholders,
    required this.participants,
    required this.scores,
  });

  final ReFlight reFlight;
  final RoundGroup group;
  final List<MatrixAssignment> assignments;

  /// Unscored placeholders of every assignment.
  final List<ScorePlaceholder> placeholders;
  final List<ReFlightParticipant> participants;
  final List<RestoredScoreRows> scores;
}

/// Everything a restore writes beyond the draw: scores, re-flights,
/// retirements, round and group states, stamp and audit.
class RestoredRows {
  RestoredRows({
    required Iterable<Round> rounds,
    required Iterable<RoundGroup> groups,
    required Iterable<RestoredScoreRows> scores,
    required Iterable<RestoredReflightRows> reflights,
    required Iterable<ContestParticipation> participations,
    required this.stamp,
    required this.audit,
  }) : rounds = List.unmodifiable(rounds),
       groups = List.unmodifiable(groups),
       scores = List.unmodifiable(scores),
       reflights = List.unmodifiable(reflights),
       participations = List.unmodifiable(participations);

  /// Every round of the draw in its final state (`Open`, `Locked` or
  /// `Cancelled`), replacing the draw's own.
  final List<Round> rounds;

  /// Every regular group in its final state.
  final List<RoundGroup> groups;

  /// The scores of drawn flights.
  final List<RestoredScoreRows> scores;
  final List<RestoredReflightRows> reflights;

  /// Every participation with its number and retirement round, replacing the
  /// draw's numbered ones.
  final List<ContestParticipation> participations;

  /// The `ContestScores` stamp.
  final ImportProvenance stamp;
  final AuditEvent audit;

  int get flightCount =>
      scores.length + reflights.fold(0, (n, r) => n + r.scores.length);
}

/// Turns a [RestorePlan] and the draw built from it into the rows of the
/// scores, re-flights, retirements and final round states.
///
/// Pure: ids come from [newId], time from the caller.
class GliderScoreRestoreBuilder {
  GliderScoreRestoreBuilder({required this.newId});

  /// The reason stored with a restored official score.
  static const reason = 'Restored from GliderScore';

  /// `ScoreAttempt.source_device` of a restored attempt.
  static const sourceDevice = 'import:gliderscore';

  final Id Function() newId;

  RestoredRows build({
    required RestorePlan plan,
    required ImportedDraw draw,
    required List<ContestParticipation> participations,
    required Map<int, Id> participationIds,
    required Id contestId,
    required Id configRevisionId,
    required Id actorId,
    required Id operationId,
    required String fileFingerprint,
    required String toolVersion,
    required MutationMetadata metadata,
    required bool completed,
    required DateTime now,
  }) {
    final rounds = <int, Round>{};
    final groupsByRound = <Id, List<RoundGroup>>{};
    // (round id, participation) to the drawn assignment and its placeholder.
    final assignmentOf = <(Id, Id), MatrixAssignment>{};
    final placeholderOf = <Id, ScorePlaceholder>{};
    for (final built in draw.revisions) {
      for (final round in built.draw.rounds) {
        rounds[round.ordinal] = round;
      }
      for (final group in built.draw.groups) {
        (groupsByRound[group.roundId] ??= []).add(group);
      }
      for (final a in built.draw.assignments) {
        assignmentOf[(a.scheduledRoundId, a.contestParticipationId)] = a;
      }
      for (final p in built.placeholders) {
        placeholderOf[p.assignmentId] = p;
      }
    }

    RestoredScoreRows score(
      RestoredFlight flight,
      MatrixAssignment assignment,
      ScorePlaceholder placeholder,
    ) {
      final attempt = ScoreAttempt(
        id: newId(),
        contestId: contestId,
        scorePlaceholderId: placeholder.id,
        configRevisionId: configRevisionId,
        matrixRevisionId: assignment.matrixRevisionId,
        rawComponents: flight.rawComponents,
        actorId: actorId,
        authority: Authority.director,
        sourceDevice: sourceDevice,
        clientMutationId:
            'gs:$fileFingerprint:${plan.sourceCompNo},${flight.key}',
        baseScoreRevision: 0,
      );
      final official = OfficialScore(
        id: newId(),
        contestId: contestId,
        scorePlaceholderId: placeholder.id,
        scoreAttemptId: attempt.id,
        scoreRevision: 1,
        components: flight.components,
        setAt: now,
        setBy: actorId,
        reason: reason,
      );
      return RestoredScoreRows(
        attempt: attempt,
        official: official,
        placeholder: ScorePlaceholder(
          id: placeholder.id,
          contestId: contestId,
          contestParticipationId: placeholder.contestParticipationId,
          assignmentId: placeholder.assignmentId,
          state: ScorePlaceholderState.official,
          scoreRevision: 1,
          revision: placeholder.revision,
        ),
      );
    }

    Id participation(int pilotNo) {
      final id = participationIds[pilotNo];
      if (id == null) throw StateError('pilot $pilotNo has no participation');
      return id;
    }

    MatrixAssignment drawnAssignment(Round round, int pilotNo) {
      final found = assignmentOf[(round.id, participation(pilotNo))];
      if (found == null) {
        throw StateError(
          'pilot $pilotNo is not drawn in round ${round.ordinal}',
        );
      }
      return found;
    }

    Round roundOf(int ordinal) {
      final round = rounds[ordinal];
      if (round == null) throw StateError('round $ordinal is not drawn');
      return round;
    }

    final scores = <RestoredScoreRows>[];
    final reflightScores = <(int, int, int), List<RestoredFlight>>{};
    for (final flight in plan.flights) {
      if (flight.isReflight) {
        (reflightScores[(
                  flight.roundNo,
                  flight.reflightNo,
                  flight.sourceGroupNo,
                )] ??=
                [])
            .add(flight);
        continue;
      }
      final assignment = drawnAssignment(
        roundOf(flight.roundNo),
        flight.sourcePilotNo,
      );
      scores.add(score(flight, assignment, placeholderOf[assignment.id]!));
    }

    final reflights = <RestoredReflightRows>[];
    for (final draft in plan.reflights) {
      final round = roundOf(draft.roundNo);
      final flown =
          reflightScores[(
            draft.roundNo,
            draft.reflightNo,
            draft.sourceGroupNo,
          )] ??
          const <RestoredFlight>[];
      final byPilot = {for (final f in flown) f.sourcePilotNo: f};
      final reFlight = ReFlight(
        id: newId(),
        contestId: contestId,
        creditedRoundId: round.id,
        sourceRoundId: round.id,
        sourceGroup: draft.sourceGroupNo,
        type: ReFlightType.reflyEntireGroup,
        sequence: draft.reflightNo,
        status: ReFlightStatus.finalized,
        reason:
            'Restored from GliderScore re-flight ${draft.reflightNo} '
            'of group ${draft.sourceGroupNo}',
        scheduledRoundId: round.id,
        flownGroup: draft.flownGroupNo,
        configRevisionId: configRevisionId,
        createdBy: actorId,
        createdAt: now,
        groupFinalizedBy: actorId,
        groupFinalizedAt: now,
        finalizedBy: actorId,
        finalizedAt: now,
      );
      final group = RoundGroup(
        id: newId(),
        contestId: contestId,
        roundId: round.id,
        groupNumber: draft.flownGroupNo,
        status: completed ? GroupStatus.locked : GroupStatus.open,
        lockedBy: completed ? actorId : null,
        lockedAt: completed ? now : null,
      );
      final assignments = <MatrixAssignment>[];
      final placeholders = <ScorePlaceholder>[];
      final participants = <ReFlightParticipant>[];
      final rows = <RestoredScoreRows>[];
      for (final member in draft.members) {
        final source = drawnAssignment(round, member.sourcePilotNo);
        final assignment = MatrixAssignment(
          id: newId(),
          contestId: contestId,
          matrixRevisionId: source.matrixRevisionId,
          contestParticipationId: source.contestParticipationId,
          scheduledRoundId: round.id,
          creditedRoundId: round.id,
          group: draft.flownGroupNo,
          flightSequence: draft.reflightNo + 1,
          assignmentType: AssignmentType.reflight,
          sourceAssignmentId: source.id,
          reFlightId: reFlight.id,
          actorId: actorId,
          reason: reFlight.reason,
          createdAt: now,
        );
        final placeholder = ScorePlaceholder(
          id: newId(),
          contestId: contestId,
          contestParticipationId: source.contestParticipationId,
          assignmentId: assignment.id,
        );
        assignments.add(assignment);
        placeholders.add(placeholder);
        participants.add(
          ReFlightParticipant(
            id: newId(),
            contestId: contestId,
            reFlightId: reFlight.id,
            contestParticipationId: source.contestParticipationId,
            role: member.role,
            drawPosition: member.position,
            assignmentId: assignment.id,
          ),
        );
        final flight = byPilot[member.sourcePilotNo];
        if (flight != null) rows.add(score(flight, assignment, placeholder));
      }
      reflights.add(
        RestoredReflightRows(
          reFlight: reFlight,
          group: group,
          assignments: assignments,
          placeholders: placeholders,
          participants: participants,
          scores: rows,
        ),
      );
    }

    // Round and group states.
    final trailing = plan.trailingUnflownRounds.toSet();
    final finalRounds = <Round>[];
    final finalGroups = <RoundGroup>[];
    for (final round in rounds.values) {
      final status = !completed
          ? RoundStatus.open
          : trailing.contains(round.ordinal)
          ? RoundStatus.cancelled
          : RoundStatus.locked;
      finalRounds.add(
        Round(
          id: round.id,
          contestId: round.contestId,
          matrixRevisionId: round.matrixRevisionId,
          ordinal: round.ordinal,
          groupCount: round.groupCount,
          status: status,
          revision: round.revision,
        ),
      );
      for (final group in groupsByRound[round.id] ?? const <RoundGroup>[]) {
        finalGroups.add(
          completed
              ? RoundGroup(
                  id: group.id,
                  contestId: group.contestId,
                  roundId: group.roundId,
                  groupNumber: group.groupNumber,
                  status: GroupStatus.locked,
                  lockedBy: actorId,
                  lockedAt: now,
                  revision: group.revision,
                )
              : group,
        );
      }
    }

    // Participations: numbered by the draw, retired by the file.
    final retiredAt = {
      for (final r in plan.retirements)
        if (participationIds[r.sourcePilotNo] != null)
          participationIds[r.sourcePilotNo]!: r.retiredAtRound,
    };
    final numbered = {for (final p in draw.numberedParticipations) p.id: p};
    final finalParticipations = [
      for (final p in participations.map((p) => numbered[p.id] ?? p))
        retiredAt.containsKey(p.id) ? p.withRetiredAtRound(retiredAt[p.id]) : p,
    ];

    final landing = plan.landing;
    final scoresId = newId();
    final stamp = ImportProvenance(
      id: newId(),
      ownerAccountId: actorId,
      contestId: contestId,
      stampedEntityType: ImportProvenance.contestScoresEntityType,
      stampedEntityId: scoresId,
      sourceSystem: ImportProvenance.gliderScore,
      sourceKeys: {'comp_no': plan.sourceCompNo},
      sourceValues: {
        'content_hash': plan.contentHash,
        'completed': completed,
        'flights': plan.flights.length,
        'reflights': plan.reflights.length,
        'retirements': [
          for (final r in plan.retirements) [r.sourcePilotNo, r.retiredAtRound],
        ],
        if (landing != null) ...{
          'landing_match': landing.match.name,
          'landing_table': landing.systemTable ?? landing.reconstructedName,
          'landing_source_table_no': landing.sourceTableNo,
        },
        'warnings': [for (final w in plan.warnings) w.code],
      },
      fileFingerprint: fileFingerprint,
      importOperationId: operationId,
      toolVersion: toolVersion,
      importedAt: now,
    );
    final audit = AuditEvent(
      id: newId(),
      entityType: 'ContestScores',
      entityId: scoresId,
      contestId: contestId,
      action: AuditAction.restoration,
      actorId: metadata.actorId,
      authority: metadata.authority,
      installationId: metadata.sourceInstallationId,
      device: metadata.sourceDevice,
      serverTimestamp: now,
      clientTimestamp: metadata.clientTime,
      reason: 'import:gliderscore:${operationId.value}',
      outcome: AuditOutcome.success,
    );
    return RestoredRows(
      rounds: finalRounds,
      groups: finalGroups,
      scores: scores,
      reflights: reflights,
      participations: finalParticipations,
      stamp: stamp,
      audit: audit,
    );
  }
}
