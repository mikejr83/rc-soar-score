/// Where a round stands for one pilot on the pilot overview.
///
/// [locked] means the server has closed the round (scoring closed, or the
/// round is locked). [upcoming] is a round that has not opened yet because an
/// earlier round is unscored; it is not a lock.
enum PilotRoundStatus {
  submitted,
  pendingReview,
  nextToScore,
  upcoming,
  locked,
  retired,
}

/// One row of the pilot overview: the draw for a round and its score state.
class PilotRound {
  const PilotRound({
    required this.number,
    required this.group,
    this.lane,
    required this.status,
    this.enteredBy,
    this.unavailableReason,
  });

  final int number;
  final String group;
  final int? lane;
  final PilotRoundStatus status;

  /// Who entered the score: `You` or a name. Null before a score exists.
  final String? enteredBy;

  /// Why a [PilotRoundStatus.locked] round cannot be scored, in the server's
  /// words, when it says. Null otherwise.
  final String? unavailableReason;
}
