import 'package:equatable/equatable.dart';

import 'round_flight_result.dart';

/// The calculated results of one round, by group.
class RoundResults extends Equatable {
  RoundResults({
    required this.ordinal,
    this.isStale = false,
    Iterable<RoundFlightResult> flights = const [],
  }) : flights = List.unmodifiable(flights);

  factory RoundResults.fromJson(Map<String, Object?> json) => RoundResults(
    ordinal: json['ordinal']! as int,
    isStale: json['stale']! as bool,
    flights: [
      for (final item in json['flights']! as List<Object?>)
        RoundFlightResult.fromJson(item! as Map<String, Object?>),
    ],
  );

  final int ordinal;

  /// True when the results were computed before the latest change to the
  /// scores, the configuration or the matrix.
  final bool isStale;

  /// The flights of the round, by group and then group score, best first.
  final List<RoundFlightResult> flights;

  bool get isPreliminary =>
      isStale || flights.any((f) => f.result.isPreliminary);

  Map<String, Object?> toJson() => {
    'ordinal': ordinal,
    'stale': isStale,
    'preliminary': isPreliminary,
    'flights': [for (final item in flights) item.toJson()],
  };

  @override
  List<Object?> get props => [ordinal, isStale, flights];
}
