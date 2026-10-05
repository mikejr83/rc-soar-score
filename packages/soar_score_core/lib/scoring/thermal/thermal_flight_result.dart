import 'package:equatable/equatable.dart';

import '../../enums/flight_outcome.dart';
import '../group/pilot_round.dart';
import 'thermal_zero_reason.dart';

/// The calculated result of one Thermal Duration flight, with its audit values.
class ThermalFlightResult extends Equatable {
  ThermalFlightResult({
    required this.outcome,
    List<ThermalZeroReason> zeroReasons = const [],
    this.flightPoints = 0,
    this.landingBonus = 0,
    this.overflightSeconds = 0,
    this.flightPenalty = 0,
  }) : zeroReasons = List.unmodifiable(zeroReasons);

  /// `zero` for a forced zero or a blank score, otherwise `scored`.
  final FlightOutcome outcome;

  /// Why the flight scored zero; empty for an ordinary zero.
  final List<ThermalZeroReason> zeroReasons;

  /// Points for the time flown, after the over-flight is taken off.
  final double flightPoints;

  /// The landing bonus awarded; zero after a forced zero.
  final double landingBonus;

  /// Seconds flown past the target time.
  final double overflightSeconds;

  /// The flight penalty entered with the score.
  final double flightPenalty;

  /// Flight points plus the landing bonus less the flight penalty, never
  /// below zero.
  double get rawScore {
    final score = flightPoints + landingBonus - flightPenalty;
    return score < 0 ? 0 : score;
  }

  /// This flight as input to the group score.
  PilotRound toPilotRound(String pilotId, {bool retired = false}) => PilotRound(
    pilotId: pilotId,
    flightPoints: flightPoints,
    landingBonus: landingBonus,
    deductions: flightPenalty,
    retired: retired,
  );

  @override
  List<Object?> get props => [
    outcome,
    zeroReasons,
    flightPoints,
    landingBonus,
    overflightSeconds,
    flightPenalty,
  ];
}
