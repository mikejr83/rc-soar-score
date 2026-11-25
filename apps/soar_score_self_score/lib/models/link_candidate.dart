/// A contest that invited the pilot behind a [LinkCandidate].
class LinkCandidateContest {
  const LinkCandidateContest({
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  final String name;

  /// The contest's first and last day in its own time zone, as UTC midnight
  /// of that calendar day (the same as `ContestSummary`).
  final DateTime startDate;
  final DateTime endDate;
}

/// A pilot the signed-in account's verified email matches: the "Is this you?"
/// prompt (#546). The pilot answers with [id]; it is the only id the card
/// carries.
class LinkCandidate {
  const LinkCandidate({
    required this.id,
    required this.pilotName,
    this.contests = const [],
  });

  final String id;

  /// The name as the contest director typed it.
  final String pilotName;
  final List<LinkCandidateContest> contests;
}
