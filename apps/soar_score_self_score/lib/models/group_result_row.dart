/// How a pilot's flight shows in the group results.
enum GroupRowKind {
  /// A scored flight.
  scored,

  /// A flight scored as zero, with [GroupResultRow.zeroReason].
  zero,

  /// No score has been entered yet.
  noScore,

  /// The pilot retired before this round, so no flight is expected.
  retired,
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
    this.isYou = false,
    this.reviewPending = false,
  });

  final String name;
  final int? pilotNumber;
  final GroupRowKind kind;

  /// Formatted time such as `6:30.4`; null when there is none.
  final String? time;

  /// Launch height in whole metres; null when there is none.
  final int? height;

  /// The points the landing table awarded; null when there is none.
  final int? landing;

  /// The flight score before normalising, formatted; null when there is none.
  final String? rawScore;

  /// The calculated flight score, formatted; null when there is none.
  final String? score;
  final String? zeroReason;

  final bool isYou;

  /// A review is open on the flight; the original entry is still shown. It
  /// holds for any kind, so a zero keeps its reason while under review.
  final bool reviewPending;
}
