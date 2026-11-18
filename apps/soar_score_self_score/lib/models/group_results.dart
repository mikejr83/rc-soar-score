import 'group_result_row.dart';
import 'officialization_policy.dart';

/// The preliminary results of the group a pilot flew in for one round.
class GroupResults {
  const GroupResults({
    required this.contestName,
    required this.round,
    required this.group,
    required this.latestRound,
    required this.rows,
    this.policy,
    this.preliminary = true,
  });

  final String contestName;
  final int round;
  final String group;

  /// The round the overall results link points to.
  final int latestRound;
  final List<GroupResultRow> rows;

  /// When the contest makes scores official; null when unknown.
  final OfficializationPolicy? policy;

  /// False once every score in the results is official.
  final bool preliminary;

  /// True when a flight in the group is held by an open review.
  bool get hasReviewHold =>
      rows.any((row) => row.kind == GroupRowKind.pendingReview);
}
