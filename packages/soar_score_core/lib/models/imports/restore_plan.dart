import '../../enums/landing_input_unit.dart';

import 'package:equatable/equatable.dart';

import '../../enums/re_flight_participant_role.dart';
import 'contest_import_draft.dart';
import 'draw_import_draft.dart';

/// Which competition of which database a restore is for, the same across
/// copies of the file (ADR 0006, amendment 2).
///
/// `CompID` when the competition has one (files from 2019 on); otherwise the
/// competition number plus name plus date, which the wizard confirms with the
/// director before it treats two competitions as the same.
class RestoreIdentity extends Equatable {
  const RestoreIdentity({
    required this.compNo,
    this.compId,
    this.name,
    this.date,
  });

  /// GliderScore's `CompNo`: only a key inside one file.
  final int compNo;

  /// GliderScore's `CompID`, when the row has one.
  final String? compId;

  final String? name;

  /// The competition's calendar day as `yyyy-mm-dd`.
  final String? date;

  bool get hasCompId => compId != null;

  /// The canonical text of the identity (stable across copies of a file).
  String get key => hasCompId
      ? 'id:${compId!.toLowerCase()}'
      : 'no:$compNo|${(name ?? '').trim().toLowerCase()}|${date ?? ''}';

  /// The contest stamp's dedupe key (the owner is not part of it).
  String get dedupeKey => 'gliderscore:$key';

  @override
  List<Object?> get props => [compNo, compId, name, date];
}

/// Why a competition cannot be restored (stable codes). The draw codes of
/// [DrawImportReason] and the contest codes of [ContestImportReason] are
/// passed through unchanged.
abstract final class RestoreReason {
  /// The class has no restore for scores yet.
  static const classNotSupported = 'class_not_supported';

  /// A re-flight does not cover the whole group of the flight it repeats.
  static const reflightNotWholeGroup = 'reflight_not_whole_group';

  /// A scored flight cannot be turned into Soar Score components; the detail
  /// names the first flights.
  static const flightNotRepresentable = 'flight_not_representable';
}

/// Why one flight cannot be represented (stable codes).
abstract final class FlightRefusal {
  /// `Time1Mins` is not a packed `M:SS` (seconds above 59, or negative).
  static const timeInvalid = 'time_invalid';

  /// The time is not below the working time, which Soar Score cannot score.
  static const timeOverWorkingTime = 'time_over_working_time';

  /// The launch height is not a whole number of metres.
  static const heightNotWhole = 'height_not_whole';

  /// A time without a launch height, or a height without a time.
  static const timeHeightMismatch = 'time_height_mismatch';

  /// The penalty is not a whole number of points.
  static const penaltyNotWhole = 'penalty_not_whole';
}

/// A warning about a restore (stable codes).
class RestoreWarning extends Equatable {
  const RestoreWarning(
    this.code, {
    this.round,
    this.group,
    this.sourcePilotNo,
    this.detail,
  });

  /// The motor restart option is empty (an old file) or 0, so the flag never
  /// zeroed the flight: the recorded score is kept and the flag is provenance.
  static const motorRestartKept = 'motor_restart_score_kept';

  /// A landing value is not in the pinned landing table; the landing is left
  /// out and the comparison decides.
  static const landingUnresolved = 'landing_unresolved';

  /// The landing table the competition used matches none of the candidates
  /// fully; the best one is pinned.
  static const landingPartialMatch = 'landing_partial_match';

  /// A pilot's retirement round was inferred from the last scored flight.
  static const retirementInferred = 'retirement_round_inferred';

  /// A re-flight pilot has no score in the original flight, so is awarded.
  static const reflightAwarded = 'reflight_pilot_awarded';

  /// A flown round has flights without a score.
  static const roundPartlyFlown = 'round_partly_flown';

  /// The competition has no scored flight, so it stays `Ready`.
  static const noScoredFlights = 'no_scored_flights';

  /// A flight with nothing recorded is imported as entered: Soar Score
  /// records it with no time and no height (a launch height of 0 is not a
  /// valid height) and the calculator produces the zero.
  static const allZeroFlight = 'all_zero_flight';

  final String code;
  final int? round;
  final int? group;
  final int? sourcePilotNo;
  final String? detail;

  @override
  List<Object?> get props => [code, round, group, sourcePilotNo, detail];
}

/// How a restored flight's result came about.
enum RestoredFlightKind {
  /// Time, height, landing and penalty as recorded (this includes a floored
  /// zero: the calculator reproduces it).
  entered,

  /// The restart flag with option 1 or 2: a zero with reason `motor_restart`.
  restartZero,

  /// Nothing recorded; the calculator produces the zero.
  allZero,

  /// The restart flag with option 0 or an empty option: the recorded score
  /// stays and the flag is kept as provenance only.
  restartKept,
}

/// One scored `Scores` row, ready to be stored as a restore attempt and an
/// official score.
class RestoredFlight extends Equatable {
  const RestoredFlight({
    required this.taskNo,
    required this.roundNo,
    required this.sourceGroupNo,
    required this.groupNo,
    required this.reflightNo,
    required this.sourcePilotNo,
    required this.kind,
    required this.components,
    required this.rawComponents,
    this.sourceRawScore,
  });

  final int taskNo;
  final int roundNo;

  /// GliderScore's `GroupNo`.
  final int sourceGroupNo;

  /// The group in Soar Score: the same as [sourceGroupNo] for a drawn flight,
  /// the flown group after the regular groups for a re-flight.
  final int groupNo;

  /// 0 for a drawn flight.
  final int reflightNo;
  final int sourcePilotNo;
  final RestoredFlightKind kind;

  /// The normalized score components (profile field keys).
  final Map<String, Object?> components;

  /// The GliderScore values verbatim, kept on the attempt.
  final Map<String, Object?> rawComponents;

  /// GliderScore's `RawScore`, the target of the comparison gate.
  final num? sourceRawScore;

  bool get isReflight => reflightNo > 0;

  /// `task,round,group,reflight,pilot`: the part of the restore attempt's
  /// mutation id that names the flight.
  String get key =>
      '$taskNo,$roundNo,$sourceGroupNo,$reflightNo,$sourcePilotNo';

  @override
  List<Object?> get props => [
    taskNo,
    roundNo,
    sourceGroupNo,
    groupNo,
    reflightNo,
    sourcePilotNo,
    kind,
    components,
    rawComponents,
    sourceRawScore,
  ];
}

/// One pilot of a re-flown group.
class ReflightMemberDraft extends Equatable {
  const ReflightMemberDraft({
    required this.sourcePilotNo,
    required this.role,
    required this.position,
    required this.scored,
  });

  final int sourcePilotNo;

  /// `Awarded` when the pilot had no score in the original flight,
  /// otherwise `GroupMember`.
  final ReFlightParticipantRole role;

  /// Rank in the re-flown group by `SeqNo`, 1-based.
  final int position;

  /// The re-flight has a score for the pilot.
  final bool scored;

  @override
  List<Object?> get props => [sourcePilotNo, role, position, scored];
}

/// A whole-group re-flight (`ReflyEntireGroup`).
class ReflightDraft extends Equatable {
  const ReflightDraft({
    required this.taskNo,
    required this.roundNo,
    required this.reflightNo,
    required this.sourceGroupNo,
    required this.flownGroupNo,
    required this.members,
  });

  final int taskNo;
  final int roundNo;

  /// GliderScore's `ReFlightNo`.
  final int reflightNo;

  /// The group that was re-flown, in both programs.
  final int sourceGroupNo;

  /// The group the re-flight is flown in: after the regular groups of the
  /// round.
  final int flownGroupNo;
  final List<ReflightMemberDraft> members;

  /// Every pilot has a score.
  bool get flown => members.every((m) => m.scored);

  @override
  List<Object?> get props => [
    taskNo,
    roundNo,
    reflightNo,
    sourceGroupNo,
    flownGroupNo,
    members,
  ];
}

/// A retirement, as an overlay on the draw.
class RetirementDraft extends Equatable {
  const RetirementDraft({
    required this.sourcePilotNo,
    required this.retiredAtRound,
  });

  final int sourcePilotNo;

  /// The round after the pilot's last scored flight (1 when none).
  final int retiredAtRound;

  @override
  List<Object?> get props => [sourcePilotNo, retiredAtRound];
}

/// Where the landing table of a competition was found.
enum LandingMatch {
  /// Every landing value resolved in a table the system ships.
  system,

  /// Every landing value resolved in the table rebuilt from the file.
  reconstructed,

  /// Some landing values resolved nowhere; the best candidate is used.
  partial,

  /// The flights hold no landing value.
  none,
}

/// The landing table the competition used and how landing values resolve.
class LandingSelection extends Equatable {
  const LandingSelection({
    required this.match,
    this.systemTable,
    this.reconstructedName,
    this.entries = const [],
    this.entryKeys = const {},
    this.unresolved = const {},
    this.sourceTableNo,
    this.inputUnit = LandingInputUnit.points,
  });

  final LandingMatch match;

  /// The shipped table, by the name of its `SystemLandingTables` field:
  /// `f5jStandard` or `f5jDistance`.
  final String? systemTable;

  /// The name for a rebuilt table.
  final String? reconstructedName;

  /// The entries of a rebuilt table.
  final List<LandingEntryDraft> entries;

  /// GliderScore's landing value to the entry key it is stored as.
  final Map<int, String> entryKeys;

  /// Landing values found in the flights that resolve nowhere.
  final Set<int> unresolved;

  /// GliderScore's table number (`durLndg`).
  final int? sourceTableNo;

  /// What a scorer picks in a rebuilt table: the points (the value is the
  /// points awarded) or metres (the value is a distance).
  final LandingInputUnit inputUnit;

  bool get isReconstructed => match == LandingMatch.reconstructed;

  @override
  List<Object?> get props => [
    match,
    systemTable,
    reconstructedName,
    entries,
    entryKeys,
    unresolved,
    sourceTableNo,
    inputUnit,
  ];
}

/// One entry of a rebuilt landing table.
class LandingEntryDraft extends Equatable {
  const LandingEntryDraft({
    required this.entryKey,
    required this.label,
    required this.points,
  });

  final String entryKey;
  final String label;
  final int points;

  @override
  List<Object?> get props => [entryKey, label, points];
}

/// The state the restored contest ends in.
enum RestoreFinalState {
  /// No scored flight: nothing to restore beyond the draw.
  ready,

  /// Scored flights, still in competition.
  running,

  /// Closed: trailing unflown rounds cancelled, contest and rounds locked.
  completed,
}

/// Whether a competition can be restored.
enum RestoreStatus { importable, refused }

/// Everything one competition restores: the contest, its draw, every scored
/// flight, the re-flights, the retirements, the landing table and the final
/// state. Pure data; the content hash tells a second import of the same file
/// that nothing changed.
class RestorePlan {
  const RestorePlan({
    required this.sourceCompNo,
    required this.identity,
    required this.status,
    required this.contest,
    this.reason,
    this.reasonDetail,
    this.draw,
    this.flights = const [],
    this.reflights = const [],
    this.retirements = const [],
    this.landing,
    this.partlyFlownRounds = const [],
    this.trailingUnflownRounds = const [],
    this.completedByDefault = false,
    this.warnings = const [],
    this.contentHash = '',
  });

  final int sourceCompNo;
  final RestoreIdentity identity;
  final RestoreStatus status;

  /// A [RestoreReason], [DrawImportReason] or [ContestImportReason] code.
  final String? reason;
  final String? reasonDetail;

  /// The contest, configuration and participations (phase B's mapping).
  final ContestImportDraft contest;

  /// The draw of the first flights (phase C's mapping).
  final DrawImportDraft? draw;

  /// Every scored flight, drawn flights and re-flights, in draw order.
  final List<RestoredFlight> flights;
  final List<ReflightDraft> reflights;
  final List<RetirementDraft> retirements;
  final LandingSelection? landing;

  /// Flown rounds (up to the last round with a scored flight) that still have
  /// flights without a score, retired pilots excepted.
  final List<int> partlyFlownRounds;

  /// Rounds after the last round with a scored flight: restored as cancelled
  /// when the contest is completed.
  final List<int> trailingUnflownRounds;

  /// The preselected "Completed" checkbox: scored flights, and no flown round
  /// with unscored flights.
  final bool completedByDefault;

  final List<RestoreWarning> warnings;

  /// Hash of what this plan restores, not of the file: equal for the same
  /// content however many times and from whichever copy of the file.
  final String contentHash;

  bool get isImportable => status == RestoreStatus.importable;

  bool get hasScoredFlights => flights.isNotEmpty;

  /// The state the restore ends in for the director's checkbox.
  RestoreFinalState finalState({required bool completed}) {
    if (!hasScoredFlights) {
      return RestoreFinalState.ready;
    }
    return completed ? RestoreFinalState.completed : RestoreFinalState.running;
  }

  /// A readable, stable summary used by golden tests and the review.
  Map<String, Object?> summary() => {
    'comp_no': sourceCompNo,
    'identity': identity.key,
    'status': status.name,
    'reason': reason,
    'flights': flights.length,
    'reflights': reflights.length,
    'retirements': [
      for (final r in retirements)
        {'pilot': r.sourcePilotNo, 'round': r.retiredAtRound},
    ],
    'landing': landing?.match.name,
    'partly_flown_rounds': partlyFlownRounds,
    'trailing_unflown_rounds': trailingUnflownRounds,
    'completed_by_default': completedByDefault,
    'warnings': [for (final w in warnings) w.code],
    'content_hash': contentHash,
  };
}
