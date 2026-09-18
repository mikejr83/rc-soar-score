import '../flight.dart';
import 'zero_reason.dart';

/// Thermal Duration discipline flight attempt.
///
/// Thermal Duration uses time-based scoring similar to ALES but with
/// different rules and potentially different time settings.
class ThermalDurationFlight extends Flight {
  /// Flight duration in seconds (supports fractions).
  final double durationSeconds;
  /// Zero reason if applicable (out-of-bounds, over-flight >1 min).
  ///
  /// Thermal Duration has no motor restart condition.
  final ZeroReason? zeroReason;

  ThermalDurationFlight({
    required String id,
    required String pilotId,
    required this.durationSeconds,
    this.zeroReason,
  }) : super(id: id, pilotId: pilotId);
}