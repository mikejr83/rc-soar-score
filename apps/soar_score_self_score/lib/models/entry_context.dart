import 'landing_result.dart';

/// What the entry form needs to know about the flight it is scoring.
class EntryContext {
  const EntryContext({
    required this.pilotName,
    this.pilotNumber,
    required this.round,
    required this.roundCount,
    required this.group,
    this.lane,
    this.taskType,
    this.fieldKeys = const [],
    required this.landingTable,
    this.allowsMotorRestart = true,
  });

  final String pilotName;
  final int? pilotNumber;
  final int round;
  final int roundCount;
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
    'no_altitude',
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
}
