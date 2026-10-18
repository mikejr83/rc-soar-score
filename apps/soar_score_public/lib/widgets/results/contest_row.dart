import 'package:flutter/material.dart';

import '../../pages/results/contest_filters.dart';
import '../../pages/results/contest_summary.dart';

/// One contest in the search list: start date, name, venue and status.
class ContestRow extends StatelessWidget {
  const ContestRow({super.key, required this.contest, required this.onTap});

  final ContestSummary contest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = contest.status == ContestStatus.completed;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(ContestFilters.formatDay(contest.start)),
            ),
            Expanded(
              flex: 3,
              child: Text(
                contest.name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(contest.venue, overflow: TextOverflow.ellipsis),
            ),
            Chip(
              avatar: Icon(
                completed
                    ? Icons.check_circle_outline
                    : Icons.play_circle_outline,
                size: 18,
              ),
              label: Text(completed ? 'Completed' : 'In progress'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
