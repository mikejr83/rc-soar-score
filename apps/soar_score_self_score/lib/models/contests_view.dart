/// Where a contest stands for the pilot, as the contests page groups it.
enum ContestPhase {
  /// The pilot is invited and the contest has not started running.
  invited,

  /// The contest is running.
  inProgress,

  /// The contest finished; it stays on the list for 24 hours.
  completed,
}

/// A contest in the signed-in person's list.
class ContestSummary {
  const ContestSummary({
    required this.participationId,
    required this.contestId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.phase,
    this.location,
    this.publicResultsUrl,
  });

  /// The pilot's place in the contest. Opening the contest goes through it.
  final String participationId;
  final String contestId;
  final String name;

  /// The first and last day in the contest's own time zone, as UTC midnight so
  /// the date prints the same wherever the page is read.
  final DateTime startDate;
  final DateTime endDate;
  final ContestPhase phase;

  /// Venue, such as `Denver, CO`; null when the director gave none.
  final String? location;

  /// Where the results are on the public site; null unless the contest is
  /// published and public.
  final Uri? publicResultsUrl;
}

/// The contests page: the contests the account reaches.
class ContestsView {
  const ContestsView({required this.contests});

  final List<ContestSummary> contests;

  /// The contests in [phase], in the order the server sent them (newest first).
  List<ContestSummary> inPhase(ContestPhase phase) => [
    for (final contest in contests)
      if (contest.phase == phase) contest,
  ];
}
