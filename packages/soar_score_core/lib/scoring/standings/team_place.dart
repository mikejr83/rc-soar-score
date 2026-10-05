import 'package:equatable/equatable.dart';

/// A team's total and place.
class TeamPlace extends Equatable {
  TeamPlace({
    required this.teamId,
    required this.place,
    required this.isTied,
    required this.total,
    required List<String> countedPilotIds,
    required this.isPreliminary,
  }) : countedPilotIds = List.unmodifiable(countedPilotIds);

  final String teamId;

  /// Tied teams share a place and the next place is skipped.
  final int place;

  /// True when the tie is unresolved after the team tie-breakers.
  final bool isTied;

  /// The sum of the counted pilots' overall scores.
  final double total;

  /// The pilots whose scores count, best first.
  final List<String> countedPilotIds;

  /// True when any counted pilot's total is preliminary.
  final bool isPreliminary;

  @override
  List<Object?> get props => [
    teamId,
    place,
    isTied,
    total,
    countedPilotIds,
    isPreliminary,
  ];
}
