/// What the draw import knows about the contest a competition was imported
/// into by phase B, read by the caller from the database (ADR 0006
/// amendment). The mapper is pure and decides from this, never from storage.
class DrawImportTarget {
  const DrawImportTarget({
    required this.sourceCompNo,
    required this.fileFingerprint,
    this.stamped = true,
    this.stampedFingerprint,
    this.hasMatrix = false,
    this.hasAcceptedScores = false,
    this.participantPilotNos = const {},
  });

  /// GliderScore's `CompNo`.
  final int sourceCompNo;

  /// Hash of the file being read now.
  final String fileFingerprint;

  /// False when no phase B contest carries a stamp for this competition.
  final bool stamped;

  /// The fingerprint on the contest's stamp.
  final String? stampedFingerprint;

  /// The contest already has a finalized matrix revision.
  final bool hasMatrix;

  /// The contest already has an accepted score or a re-flight.
  final bool hasAcceptedScores;

  /// GliderScore `PilotNo`s that have a participation in the contest (from
  /// the phase B participation stamps).
  final Set<int> participantPilotNos;
}

/// Whether a competition's draw can be imported.
enum DrawImportStatus {
  /// Everything needed is there.
  importable,

  /// The draw is refused; [DrawImportDraft.reason] says why. The others
  /// proceed.
  refused,
}

/// Why a draw is refused (stable codes).
abstract final class DrawImportReason {
  /// No contest was imported from this competition in phase B.
  static const notStamped = 'contest_not_stamped';

  /// The file differs from the one phase B read; until the re-import of
  /// #576, pilot numbers might no longer line up.
  static const fingerprintChanged = 'file_fingerprint_changed';

  /// The contest already has a matrix.
  static const alreadyDrawn = 'contest_already_drawn';

  /// The contest already has an accepted score or a re-flight.
  static const hasAcceptedScores = 'contest_has_accepted_scores';

  /// The file has no `Scores` table, or it was cut short by the row budget.
  static const scoresUnavailable = 'scores_unavailable';

  /// The competition is not in the file.
  static const competitionMissing = 'competition_missing';

  /// The class is not one a draw can be imported for yet.
  static const classNotSupported = 'class_not_supported';

  /// The competition has no drawn flights.
  static const noDraw = 'no_draw';

  /// A flight belongs to a pilot with no participation in the contest.
  static const pilotWithoutParticipation = 'pilot_without_participation';

  /// A flight is credited to another round than the one it was drawn in.
  static const creditMoved = 'credit_moved';

  /// The rounds of two tasks overlap.
  static const taskRangesOverlap = 'task_ranges_overlap';

  /// The rounds do not run 1..N without gaps.
  static const taskRangesGapped = 'task_ranges_gapped';

  /// A pilot has two first flights in one round.
  static const duplicateFlight = 'duplicate_flight';

  /// A re-flight has no first flight of that pilot in its round.
  static const reflightWithoutOriginal = 'reflight_without_original';

  /// A flight row lacks a round, task, group or pilot number.
  static const keyMissing = 'flight_key_missing';
}

/// A warning about a draw (stable codes).
class DrawImportWarning {
  const DrawImportWarning(
    this.code, {
    this.round,
    this.sourcePilotNo,
    this.detail,
  });

  /// The draw is history and cannot be reproduced from a seed.
  static const notReproducible = 'draw_not_reproducible';

  /// The configured groups per round differ from the groups drawn; the
  /// drawn groups win.
  static const groupsPerRoundDiffers = 'groups_per_round_differs';

  /// A group number inside 1..G has no pilots.
  static const emptyGroup = 'empty_group';

  /// The group sizes differ from the sizes Soar Score would derive from the
  /// pilot count and the number of groups; imported as drawn.
  static const groupSizesDiffer = 'group_sizes_differ';

  /// A pilot's position is beyond the competition's lane count; the lane is
  /// kept.
  static const laneBeyondLaneCount = 'lane_beyond_lane_count';

  /// Two pilots of a group share a `SeqNo`; ordered by pilot number.
  static const seqNoDuplicate = 'seq_no_duplicate';

  /// A flight has no `SeqNo`; it is placed after the others.
  static const seqNoMissing = 'seq_no_missing';

  final String code;
  final int? round;
  final int? sourcePilotNo;
  final String? detail;
}

/// One pilot's slot in a group, as drawn.
class AssignmentDraft {
  const AssignmentDraft({
    required this.sourcePilotNo,
    required this.seqNo,
    required this.position,
    this.lane,
  });

  final int sourcePilotNo;

  /// GliderScore's `SeqNo` (null when the row had none).
  final int? seqNo;

  /// Rank of the pilot in the group, 1-based, gaps in `SeqNo` closed up.
  final int position;

  /// The lane: [position] when the competition has a lane count above 0,
  /// else null.
  final int? lane;
}

class GroupDraft {
  const GroupDraft({required this.groupNo, required this.assignments});

  final int groupNo;
  final List<AssignmentDraft> assignments;
}

class RoundDraft {
  const RoundDraft({required this.ordinal, required this.groups});

  /// GliderScore's `RoundNo`, verbatim.
  final int ordinal;

  /// One per group 1..G, empty groups included.
  final List<GroupDraft> groups;

  int get pilotCount => groups.fold(0, (n, g) => n + g.assignments.length);
}

/// One matrix revision: a run of consecutive rounds of one task with the
/// same number of groups.
class RevisionDraft {
  const RevisionDraft({
    required this.revisionNumber,
    required this.taskNo,
    required this.firstRound,
    required this.lastRound,
    required this.groupsPerRound,
    required this.rounds,
  });

  /// 1-based; each revision extends the one before.
  final int revisionNumber;
  final int taskNo;
  final int firstRound;
  final int lastRound;
  final int groupsPerRound;
  final List<RoundDraft> rounds;
}

/// One `Scores` row with every field it holds, so phase D adds only
/// persistence. Nothing here is written by phase C.
class FlightDraft {
  const FlightDraft({
    required this.taskNo,
    required this.roundNo,
    required this.groupNo,
    required this.reflightNo,
    required this.sourcePilotNo,
    required this.scored,
    this.seqNo,
    this.originalRoundNo,
    this.drawFrequency,
    this.time1Mins,
    this.time1Secs,
    this.time2Mins,
    this.time2Secs,
    this.flightScoreDeduction,
    this.landing,
    this.rawScore,
    this.normalisedScore,
    this.penalty,
    this.scoresChecked,
    this.landingOver75m,
    this.helper,
    this.laps,
    this.motorRestarted,
  });

  final int taskNo;
  final int roundNo;
  final int groupNo;

  /// 0 for the drawn flight, 1 and up for a re-flight.
  final int reflightNo;
  final int sourcePilotNo;

  /// GliderScore's `Updated`: true when the flight has data.
  final bool scored;

  final int? seqNo;
  final int? originalRoundNo;
  final num? drawFrequency;
  final num? time1Mins;
  final num? time1Secs;
  final num? time2Mins;
  final num? time2Secs;
  final num? flightScoreDeduction;
  final num? landing;
  final num? rawScore;
  final num? normalisedScore;
  final num? penalty;
  final num? scoresChecked;
  final num? landingOver75m;
  final num? helper;
  final num? laps;
  final num? motorRestarted;

  bool get isReflight => reflightNo > 0;
}

/// The draw of one competition, ready to review before anything is stored.
class DrawImportDraft {
  const DrawImportDraft({
    required this.sourceCompNo,
    required this.status,
    this.reason,
    this.reasonDetail,
    this.laneCount = 0,
    this.teamProtection = false,
    this.revisions = const [],
    this.flights = const [],
    this.probablyUnflownRounds = const [],
    this.warnings = const [],
  });

  final int sourceCompNo;
  final DrawImportStatus status;

  /// A [DrawImportReason] code when refused.
  final String? reason;
  final String? reasonDetail;

  /// GliderScore's lane count (0 means no lanes).
  final int laneCount;

  /// `Comps.UseTeamProtection`, copied to the revision's draw config.
  final bool teamProtection;

  final List<RevisionDraft> revisions;

  /// Every `Scores` row of the competition, drawn flights and re-flights.
  final List<FlightDraft> flights;

  /// Rounds after the last round with a scored flight (every round when
  /// nothing was scored): probably drawn but not flown. Used by phase D.
  final List<int> probablyUnflownRounds;

  final List<DrawImportWarning> warnings;

  bool get isImportable => status == DrawImportStatus.importable;

  int get roundCount => revisions.fold(0, (n, r) => n + r.rounds.length);

  int get groupCount => revisions.fold(
    0,
    (n, r) => n + r.rounds.fold(0, (m, round) => m + round.groups.length),
  );

  /// Drawn slots (first flights).
  int get assignmentCount => revisions.fold(
    0,
    (n, r) => n + r.rounds.fold(0, (m, round) => m + round.pilotCount),
  );

  /// Distinct pilots in the draw.
  Set<int> get pilots => {
    for (final r in revisions)
      for (final round in r.rounds)
        for (final g in round.groups)
          for (final a in g.assignments) a.sourcePilotNo,
  };
}
