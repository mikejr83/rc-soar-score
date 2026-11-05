/// Where a round stands for one pilot on the pilot overview.
enum PilotRoundStatus { submitted, pendingReview, nextToScore, locked }

/// One row of the pilot overview: the draw for a round and its score state.
class PilotRound {
  const PilotRound({
    required this.number,
    required this.group,
    this.lane,
    required this.status,
    this.enteredBy,
  });

  final int number;
  final String group;
  final int? lane;
  final PilotRoundStatus status;

  /// Who entered the score: `You` or a name. Null before a score exists.
  final String? enteredBy;
}
