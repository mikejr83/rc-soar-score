import 'landing_result.dart';

/// What the entry form needs to know about the flight it is scoring.
class EntryContext {
  const EntryContext({
    required this.pilotName,
    required this.pilotNumber,
    required this.round,
    required this.roundCount,
    required this.group,
    required this.lane,
    required this.landingTable,
    this.allowsMotorRestart = true,
  });

  final String pilotName;
  final int pilotNumber;
  final int round;
  final int roundCount;
  final String group;
  final int lane;

  /// The contest's landing table; its size picks the landing control.
  final List<LandingResult> landingTable;

  /// Motor restart is hidden when the contest does not allow it.
  final bool allowsMotorRestart;
}
