/// Represents a single round's group assignments.
class RoundAssignment {
  final int roundNumber;
  final List<List<MatrixPilotAssignment>> groups;

  RoundAssignment({
    required this.roundNumber,
    required this.groups,
  });
}

/// Represents a pilot's assignment to a group and lane in a round.
class MatrixPilotAssignment {
  final String pilotId;
  final int groupNumber;
  final int laneNumber;

  MatrixPilotAssignment({
    required this.pilotId,
    required this.groupNumber,
    required this.laneNumber,
  });
}