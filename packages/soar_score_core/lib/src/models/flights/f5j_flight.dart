import '../flight.dart';
import 'zero_reason.dart';

/// F5J discipline flight attempt.
///
/// F5J uses time-based scoring with height and distance penalties.
/// Each flight has a duration plus optional penalty components.
class F5JFlight extends Flight implements WithLandingBonus {
  /// Flight duration in seconds (supports fractions).
  final double durationSeconds;
  /// Zero reason if applicable (out-of-bounds, over-flight >1 min, motor restart).
  final ZeroReason? zeroReason;
  /// Height penalty input: launch altitude in meters.
  final double? launchAltitudeMeters;
  /// Distance penalty in seconds, if applicable.
  final double? distancePenaltySeconds;
  /// Landing bonus points (from configured landing table).
  final int? landingBonus;

  F5JFlight({
    required String id,
    required String pilotId,
    required this.durationSeconds,
    required this.landingBonus,
    this.zeroReason,
    this.launchAltitudeMeters,
    this.distancePenaltySeconds,
  }) : super(id: id, pilotId: pilotId);
}
