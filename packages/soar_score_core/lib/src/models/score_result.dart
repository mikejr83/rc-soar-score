/// The result of computing a pilot's score for a round.
class ScoreResult {
  /// Raw score before group normalization.
  final double rawScore;

  /// Normalized group score (0-1000).
  final double groupScore;

  /// Whether the pilot received a zero score (and the reason).
  final bool isZeroScore;

  /// The zero reason, if applicable.
  final String? zeroReason;

  ScoreResult({
    required this.rawScore,
    required this.groupScore,
    this.isZeroScore = false,
    this.zeroReason,
  });
}

/// Group of raw scores for normalization.
class GroupScores {
  final List<ScoreResult> scores;

  GroupScores(this.scores);
}