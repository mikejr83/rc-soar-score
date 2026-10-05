import 'package:equatable/equatable.dart';

import '../../enums/flight_outcome.dart';
import '../group/pilot_round.dart';
import 'ales_zero_reason.dart';

/// The calculated result of one ALES flight, with its audit values.
class AlesFlightResult extends Equatable {
  AlesFlightResult({
    required this.outcome,
    List<AlesZeroReason> zeroReasons = const [],
    this.flightPoints = 0,
    this.landingBonus = 0,
    this.overflightSeconds = 0,
  }) : zeroReasons = List.unmodifiable(zeroReasons);

  /// `zero` for a forced zero or a blank score, otherwise `scored`.
  final FlightOutcome outcome;

  /// Why the flight scored zero; empty for an ordinary zero.
  final List<AlesZeroReason> zeroReasons;

  /// Target-time flight points, already floored at zero.
  final double flightPoints;

  /// The landing bonus awarded; zero after a forced zero.
  final double landingBonus;

  /// Seconds flown past the target time, kept for audit; zero at or under it.
  final double overflightSeconds;

  /// Flight points plus landing bonus.
  double get rawScore => flightPoints + landingBonus;

  /// This flight as input to the group score.
  PilotRound toPilotRound(String pilotId, {bool retired = false}) => PilotRound(
    pilotId: pilotId,
    flightPoints: flightPoints,
    landingBonus: landingBonus,
    retired: retired,
  );

  @override
  List<Object?> get props => [
    outcome,
    zeroReasons,
    flightPoints,
    landingBonus,
    overflightSeconds,
  ];
}
