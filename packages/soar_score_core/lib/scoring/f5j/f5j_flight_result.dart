import 'package:equatable/equatable.dart';

import '../../enums/flight_outcome.dart';
import '../group/pilot_round.dart';
import 'f5j_motor_restart_mode.dart';
import 'f5j_zero_reason.dart';

/// The calculated result of one F5J flight, with its audit values.
class F5jFlightResult extends Equatable {
  F5jFlightResult({
    required this.outcome,
    List<F5jZeroReason> zeroReasons = const [],
    this.lateLanding = false,
    this.flightPoints = 0,
    this.landingBonus = 0,
    this.heightPenalty = 0,
    this.flightPenalty = 0,
    required this.motorRestartMode,
    this.nonDroppable = false,
  }) : zeroReasons = List.unmodifiable(zeroReasons);

  /// `zero` for a forced zero or a blank score, otherwise `scored`. A scored
  /// flight can still have a raw score of zero when the penalties exceed it.
  final FlightOutcome outcome;

  /// Why the flight scored zero; empty for an ordinary zero.
  final List<F5jZeroReason> zeroReasons;

  final bool lateLanding;
  final double flightPoints;

  /// The landing bonus awarded; zero after a late landing or a forced zero.
  final double landingBonus;
  final double heightPenalty;
  final double flightPenalty;

  /// The motor restart option the calculation used.
  final F5jMotorRestartMode motorRestartMode;

  /// A zero from a motor restart that may never be dropped.
  final bool nonDroppable;

  /// Flight points plus bonus less both penalties, never below zero.
  double get rawScore {
    final score = flightPoints + landingBonus - heightPenalty - flightPenalty;
    return score < 0 ? 0 : score;
  }

  /// This flight as input to the group score.
  PilotRound toPilotRound(String pilotId, {bool retired = false}) => PilotRound(
    pilotId: pilotId,
    flightPoints: flightPoints,
    landingBonus: landingBonus,
    deductions: heightPenalty + flightPenalty,
    retired: retired,
  );

  @override
  List<Object?> get props => [
    outcome,
    zeroReasons,
    lateLanding,
    flightPoints,
    landingBonus,
    heightPenalty,
    flightPenalty,
    motorRestartMode,
    nonDroppable,
  ];
}
