/// How a pilot's flight shows in the group results.
enum GroupRowKind {
  /// A scored flight.
  scored,

  /// A flight scored as zero, with [GroupResultRow.zeroReason].
  zero,

  /// No score has been entered yet.
  noScore,

  /// A review is open; the original entry is still shown.
  pendingReview,
}

/// One pilot's flight in a group, as the group results page shows it. Each
/// component that makes up the score is its own field so the page can give it
/// its own column.
class GroupResultRow {
  const GroupResultRow({
    required this.name,
    this.pilotNumber,
    required this.kind,
    this.time,
    this.height,
    this.landing,
    this.rawScore,
    this.score,
    this.zeroReason,
    this.isEstimate = false,
    this.isYou = false,
  });

  final String name;
  final int? pilotNumber;
  final GroupRowKind kind;

  /// Formatted time such as `6:30.4`; null when there is none.
  final String? time;

  /// Launch height in whole metres; null when there is none.
  final int? height;

  /// The landing's label, such as `Good`; null when there is none.
  final String? landing;

  /// The flight score before normalising, formatted; null when there is none.
  final String? rawScore;

  /// The calculated flight score, formatted; null when there is none.
  final String? score;
  final String? zeroReason;

  /// True when the score is a missing-score estimate, not an entered one.
  final bool isEstimate;

  final bool isYou;
}
