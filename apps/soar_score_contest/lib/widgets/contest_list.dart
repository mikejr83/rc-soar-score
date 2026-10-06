import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// A plain list of [contests]: name, lifecycle status and dates.
///
/// No selection or actions yet; those belong to the contest selection
/// tickets.
class ContestList extends StatelessWidget {
  const ContestList({required this.contests, super.key});

  final List<Contest> contests;

  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: contests.length,
    separatorBuilder: (_, _) => const Divider(height: 1),
    itemBuilder: (context, index) {
      final contest = contests[index];
      return ListTile(
        title: Text(contest.name),
        subtitle: Text(_dates(contest)),
        trailing: Text(_status(contest.lifecycleState)),
      );
    },
  );

  static String _status(LifecycleState state) =>
      '${state.name[0].toUpperCase()}${state.name.substring(1)}';

  static String _dates(Contest contest) {
    final format = DateFormat.yMMMd();
    final start = format.format(contest.startDateTime.toLocal());
    final end = format.format(contest.endDateTime.toLocal());
    return start == end ? start : '$start to $end';
  }
}
