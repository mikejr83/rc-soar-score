import 'landing_result.dart';
import 'score_submission.dart';

/// What the entry form needs to know about the flight it is scoring.
class EntryContext {
  const EntryContext({
    required this.pilotName,
    this.pilotNumber,
    required this.round,
    required this.roundCount,
    int? lastOpenRound,
    required this.group,
    this.lane,
    this.taskType,
    this.fieldKeys = const [],
    required this.landingTable,
    this.allowsMotorRestart = true,
    this.matrixRevision = 0,
    this.alreadySubmitted = false,
    this.submittedScore,
  }) : lastOpenRound = lastOpenRound ?? roundCount;

  final String pilotName;
  final int? pilotNumber;
  final int round;
  final int roundCount;

  /// The latest round the pilot can open: scored rounds and the next one to
  /// score, as on the pilot overview. Later rounds stay closed.
  final int lastOpenRound;
  final String group;

  /// Null for disciplines that fly without lanes.
  final int? lane;

  /// The task the server scores this flight as, when it says. The form scores
  /// only flights without a named task.
  final String? taskType;

  /// The score fields the server asks for. The form is the F5J one; see
  /// [formSupported].
  final List<String> fieldKeys;

  /// The fields the F5J form knows how to show and submit.
  static const knownFieldKeys = {
    'time_flown',
    'launch_height',
    'landing',
    'late_landing',
    'motor_restart',
    'out_of_bounds',
    'no_altitude_recorded',
    'flight_penalty',
  };

  /// Whether the F5J form can score this flight. A flight asking for any other
  /// field would be scored wrongly, so the page says so instead.
  bool get formSupported =>
      taskType == null && fieldKeys.every(knownFieldKeys.contains);

  /// The contest's landing table; its size picks the landing control.
  final List<LandingResult> landingTable;

  /// Motor restart is hidden when the contest does not allow it.
  final bool allowsMotorRestart;

  /// The draw revision this context was read at; sent back with the score.
  final int matrixRevision;

  /// A score already exists for this flight, so the form opens read-only.
  final bool alreadySubmitted;

  /// What was entered for this flight, when the server sent it.
  final SubmittedScore? submittedScore;
}

/// The score a flight already has, as the server stored it, so the form can
/// show what was entered.
class SubmittedScore {
  const SubmittedScore({
    required this.components,
    this.flightScore,
    this.details,
  });

  /// The stored components, such as `time_flown` and `landing`.
  final Map<String, Object?> components;

  /// The server's calculation, formatted.
  final String? flightScore;
  final ScoreDetails? details;
}
