/// A contest in the signed-in person's list.
class ContestSummary {
  const ContestSummary({
    required this.id,
    required this.name,
    required this.dates,
    this.next,
  });

  final String id;
  final String name;

  /// Already formatted for display, such as `Sat 10 Oct 2026 to Sun 11 Oct 2026`.
  final String dates;

  /// The participant's next round, such as `Round 4, Group B, lane 2`.
  final String? next;
}

/// The contests page: the contests the account reaches.
class ContestsView {
  const ContestsView({required this.contests});

  final List<ContestSummary> contests;
}
