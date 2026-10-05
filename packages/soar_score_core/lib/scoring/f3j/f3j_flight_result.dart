import 'package:equatable/equatable.dart';

import '../../enums/flight_outcome.dart';
import '../group/pilot_round.dart';
import 'f3j_zero_reason.dart';

/// The calculated result of one F3J flight, with its audit values.
class F3jFlightResult extends Equatable {
  F3jFlightResult({
    required this.outcome,
    List<F3jZeroReason> zeroReasons = const [],
    this.lateLanding = false,
    this.flightPoints = 0,
    this.landingBonus = 0,
    this.latePenalty = 0,
    this.flightPenalty = 0,
  }) : zeroReasons = List.unmodifiable(zeroReasons);

  /// `zero` for a forced zero or a blank score, otherwise `scored`. A scored
  /// flight can still have a raw score of zero when the penalties exceed it.
  final FlightOutcome outcome;

  /// Why the flight scored zero; empty for an ordinary zero.
  final List<F3jZeroReason> zeroReasons;

  final bool lateLanding;
  final double flightPoints;

  /// The landing bonus awarded; zero after a late landing or a forced zero.
  final double landingBonus;

  /// The fixed late landing penalty; zero for any other flight.
  final double latePenalty;

  /// The flight penalty entered with the score.
  final double flightPenalty;

  /// Flight points plus bonus less both penalties, never below zero.
  double get rawScore {
    final score = flightPoints + landingBonus - latePenalty - flightPenalty;
    return score < 0 ? 0 : score;
  }

  /// This flight as input to the group score. The late landing penalty and
  /// the flight penalty stay with the round as deductions.
  PilotRound toPilotRound(String pilotId, {bool retired = false}) => PilotRound(
    pilotId: pilotId,
    flightPoints: flightPoints,
    landingBonus: landingBonus,
    deductions: latePenalty + flightPenalty,
    retired: retired,
  );

  @override
  List<Object?> get props => [
    outcome,
    zeroReasons,
    lateLanding,
    flightPoints,
    landingBonus,
    latePenalty,
    flightPenalty,
  ];
}
