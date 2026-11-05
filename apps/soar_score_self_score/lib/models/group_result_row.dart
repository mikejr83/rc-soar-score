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

/// One pilot's flight in a group, as the group results page shows it.
class GroupResultRow {
  const GroupResultRow({
    required this.name,
    this.pilotNumber,
    required this.kind,
    this.time,
    this.score,
    this.detail,
    this.zeroReason,
    this.isYou = false,
  });

  final String name;
  final int? pilotNumber;
  final GroupRowKind kind;

  /// Formatted time such as `6:30.4`; null when there is none.
  final String? time;
  final String? score;

  /// Launch height and landing, such as `Height 45 m · Good 50`.
  final String? detail;
  final String? zeroReason;
  final bool isYou;
}
