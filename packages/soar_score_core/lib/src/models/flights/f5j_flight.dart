import '../flight.dart';
import 'zero_reason.dart';

/// F5J discipline flight attempt.
///
/// F5J uses time-based scoring with height and distance penalties.
/// Each flight has a duration plus optional penalty components.
class F5JFlight extends Flight {
  /// Flight duration in seconds (supports fractions).
  final double durationSeconds;
  /// Zero reason if applicable (out-of-bounds, over-flight >1 min, motor restart).
  final ZeroReason? zeroReason;
  /// Height penalty in seconds, if applicable.
  final double? heightPenaltySeconds;
  /// Distance penalty in seconds, if applicable.
  final double? distancePenaltySeconds;

  F5JFlight({
    required String id,
    required String pilotId,
    required this.durationSeconds,
    this.zeroReason,
    this.heightPenaltySeconds,
    this.distancePenaltySeconds,
  }) : super(id: id, pilotId: pilotId);
}