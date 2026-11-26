/// A finished contest in the signed-in pilot's history.
class PastContest {
  const PastContest({
    required this.participationId,
    required this.contestId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.location,
    this.publicResultsUrl,
  });

  final String participationId;
  final String contestId;
  final String name;

  /// The first and last day in the contest's own time zone, as UTC midnight so
  /// the date prints the same wherever the page is read.
  final DateTime startDate;
  final DateTime endDate;

  /// Venue, such as `Denver, CO`; null when the director gave none.
  final String? location;

  /// Where the results are on the public site; null unless the contest is
  /// published and public.
  final Uri? publicResultsUrl;
}

/// One page of the history, newest contest first.
class PastContestsPage {
  const PastContestsPage({required this.contests, this.nextOffset});

  final List<PastContest> contests;

  /// The `offset` of the next page; null on the last one.
  final int? nextOffset;
}
