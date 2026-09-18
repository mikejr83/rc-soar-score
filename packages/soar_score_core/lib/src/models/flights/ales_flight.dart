import '../flight.dart';
import 'zero_reason.dart';

/// ALES discipline flight attempt.
///
/// ALES (American Ladies Endurance Soaring) uses time-based scoring.
/// The primary scoring input is flight duration.
class AlesFlight extends Flight {
  /// Flight duration in seconds (supports fractions).
  final double durationSeconds;
  /// Zero reason if applicable (out-of-bounds, over-flight >1 min, motor restart).
  final ZeroReason? zeroReason;

  AlesFlight({
    required String id,
    required String pilotId,
    required this.durationSeconds,
    this.zeroReason,
  }) : super(id: id, pilotId: pilotId);
}