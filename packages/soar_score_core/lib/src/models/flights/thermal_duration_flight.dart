import '../flight.dart';
import 'zero_reason.dart';

/// Thermal Duration discipline flight attempt.
///
/// Thermal Duration and ALES use the same scoring rules, which are time-based with optional landing bonus points.
class ThermalDurationFlight extends Flight implements WithLandingBonus {
  /// Flight duration in seconds (supports fractions).
  final double durationSeconds;
  /// Zero reason if applicable (out-of-bounds, over-flight >1 min).
  final ZeroReason? zeroReason;
  /// Landing bonus points (from configured landing table).
  final int? landingBonus;

  ThermalDurationFlight({
    required String id,
    required String pilotId,
    required this.durationSeconds,
    required this.landingBonus,
    this.zeroReason,
  }) : super(id: id, pilotId: pilotId);
}
