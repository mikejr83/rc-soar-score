import 'package:equatable/equatable.dart';

import 'pilot_place.dart';

/// The overall places of a contest as of a round.
class PilotRanking extends Equatable {
  PilotRanking({required List<PilotPlace> places, required this.isPreliminary})
    : places = List.unmodifiable(places);

  /// Ordered by place, then by the order the totals were given.
  final List<PilotPlace> places;

  /// True when any pilot's total is preliminary.
  final bool isPreliminary;

  PilotPlace? placeOf(String pilotId) {
    for (final place in places) {
      if (place.pilotId == pilotId) return place;
    }
    return null;
  }

  @override
  List<Object?> get props => [places, isPreliminary];
}
