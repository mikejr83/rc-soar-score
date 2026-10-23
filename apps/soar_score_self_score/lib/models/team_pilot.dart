/// Where a team pilot stands in the running order.
enum TeamPilotState { upNow, upNext, justFlown, retired, scheduled }

/// One pilot on the team overview.
class TeamPilot {
  const TeamPilot({
    required this.id,
    required this.name,
    required this.number,
    required this.state,
    this.slot = '',
    this.needsScoreRound,
  });

  final String id;
  final String name;
  final int number;
  final TeamPilotState state;

  /// Round, group and lane of the next flight; empty when retired.
  final String slot;

  /// For a just-flown pilot with no score: the round that needs one.
  final String? needsScoreRound;
}
