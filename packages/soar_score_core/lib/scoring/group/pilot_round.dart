import 'package:equatable/equatable.dart';

/// One pilot's calculated flight in a group, before the group score.
///
/// Values keep full precision; nothing here is rounded.
class PilotRound extends Equatable {
  PilotRound({
    required this.pilotId,
    this.flightPoints = 0,
    this.landingBonus = 0,
    this.deductions = 0,
    this.retired = false,
  }) {
    for (final (name, value) in [
      ('flightPoints', flightPoints),
      ('landingBonus', landingBonus),
      ('deductions', deductions),
    ]) {
      if (!value.isFinite || value < 0) {
        throw ArgumentError.value(value, name, 'must not be negative');
      }
    }
  }

  final String pilotId;
  final double flightPoints;
  final double landingBonus;

  /// Discipline penalties and any flight penalty, deducted from the score.
  final double deductions;

  /// A retired pilot is left out of the normalization population.
  final bool retired;

  /// Flight points less deductions, never below zero.
  double get timeScore => _floorAtZero(flightPoints - deductions);

  /// Flight points plus landing bonus less deductions, never below zero.
  double get rawScore => _floorAtZero(flightPoints + landingBonus - deductions);

  static double _floorAtZero(double value) => value < 0 ? 0 : value;

  @override
  List<Object?> get props => [
    pilotId,
    flightPoints,
    landingBonus,
    deductions,
    retired,
  ];
}
