/// A contest that invited the pilot behind a [LinkCandidate].
class LinkCandidateContest {
  const LinkCandidateContest({required this.name, required this.dates});

  final String name;

  /// Already formatted for display, such as `10 Oct 2026 to 11 Oct 2026`.
  final String dates;
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
