import 'package:equatable/equatable.dart';

import '../enums/flight_outcome.dart';
import '../scoring/f5j/f5j_flight_result.dart';

/// What the scoring engine made of one flight's components: the points that
/// go into a pilot's raw score, before group normalization.
///
/// These are calculated values, never entered ones.
class CalculatedFlight extends Equatable {
  const CalculatedFlight({
    required this.outcome,
    required this.rawScore,
    this.flightPoints = 0,
    this.landingBonus = 0,
    this.heightPenalty = 0,
    this.flightPenalty = 0,
    this.lateLanding = false,
    this.zeroReasons = const [],
  });

  factory CalculatedFlight.fromF5j(F5jFlightResult result) => CalculatedFlight(
    outcome: result.outcome,
    rawScore: result.rawScore,
    flightPoints: result.flightPoints,
    landingBonus: result.landingBonus,
    heightPenalty: result.heightPenalty,
    flightPenalty: result.flightPenalty,
    lateLanding: result.lateLanding,
    zeroReasons: [for (final reason in result.zeroReasons) reason.code],
  );

  factory CalculatedFlight.fromJson(Map<String, Object?> json) =>
      CalculatedFlight(
        outcome: FlightOutcome.values.firstWhere(
          (outcome) => _outcomeText(outcome) == json['outcome'],
        ),
        rawScore: (json['raw_score']! as num).toDouble(),
        flightPoints: (json['flight_points']! as num).toDouble(),
        landingBonus: (json['landing_bonus']! as num).toDouble(),
        heightPenalty: (json['height_penalty']! as num).toDouble(),
        flightPenalty: (json['flight_penalty']! as num).toDouble(),
        lateLanding: json['late_landing']! as bool,
        zeroReasons: [
          for (final reason in json['zero_reasons']! as List<Object?>)
            reason! as String,
        ],
      );

  static String _outcomeText(FlightOutcome outcome) => switch (outcome) {
    FlightOutcome.scored => 'Scored',
    FlightOutcome.zero => 'Zero',
  };

  final FlightOutcome outcome;

  /// Flight points plus the landing bonus, less the penalties, never below 0.
  final double rawScore;
  final double flightPoints;
  final double landingBonus;
  final double heightPenalty;
  final double flightPenalty;
  final bool lateLanding;

  /// Why the flight scored zero, as the profile's reason codes.
  final List<String> zeroReasons;

  Map<String, Object?> toJson() => {
    'outcome': _outcomeText(outcome),
    'raw_score': rawScore,
    'flight_points': flightPoints,
    'landing_bonus': landingBonus,
    'height_penalty': heightPenalty,
    'flight_penalty': flightPenalty,
    'late_landing': lateLanding,
    'zero_reasons': zeroReasons,
  };

  @override
  List<Object?> get props => [
    outcome,
    rawScore,
    flightPoints,
    landingBonus,
    heightPenalty,
    flightPenalty,
    lateLanding,
    zeroReasons,
  ];
}
