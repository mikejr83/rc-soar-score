import 'package:equatable/equatable.dart';

/// A pilot's overall place.
class PilotPlace extends Equatable {
  const PilotPlace({
    required this.pilotId,
    required this.place,
    required this.isTied,
  });

  final String pilotId;

  /// Pilots with equal keys share a place, and the next place is skipped
  /// (1, 1, 3).
  final int place;

  /// True when another pilot shares this place after every tie-breaker.
  final bool isTied;

  @override
  List<Object?> get props => [pilotId, place, isTied];
}
