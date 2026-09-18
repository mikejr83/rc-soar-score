import '../flight.dart';
import 'zero_reason.dart';

/// F3J discipline flight attempt.
///
/// F3J uses time-based scoring with 3 flights per round, best 2 count.
/// Each flight has a duration and potential zero reasons.
class F3JFlight extends Flight {
  /// Flight duration in seconds (supports fractions).
  final double durationSeconds;
  /// Zero reason if applicable (out-of-bounds landing).
  ///
  /// F3J has no over-flight >1 min or motor restart conditions.
  final ZeroReason? zeroReason;

  F3JFlight({
    required String id,
    required String pilotId,
    required this.durationSeconds,
    this.zeroReason,
  }) : super(id: id, pilotId: pilotId);
}