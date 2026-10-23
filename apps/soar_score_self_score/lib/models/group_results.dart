import 'group_result_row.dart';

/// The preliminary results of the group a pilot flew in for one round.
class GroupResults {
  const GroupResults({
    required this.contestName,
    required this.round,
    required this.group,
    required this.latestRound,
    required this.rows,
  });

  final String contestName;
  final int round;
  final String group;

  /// The round the overall results link points to.
  final int latestRound;
  final List<GroupResultRow> rows;
}
