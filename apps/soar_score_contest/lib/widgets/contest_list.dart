import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'contest_status_chip.dart';

/// The master pane of the contests page: title and count, then one row per
/// contest with a date badge, name, dates and status. The row for
/// [selectedId] is highlighted when [highlight] is set.
class ContestList extends StatelessWidget {
  const ContestList({
    required this.contests,
    required this.selectedId,
    required this.highlight,
    required this.onSelect,
    super.key,
  });

  final List<Contest> contests;
  final Id? selectedId;
  final bool highlight;
  final ValueChanged<Contest> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Contests', style: theme.textTheme.titleLarge),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '${contests.length} contests',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: contests.length,
            itemBuilder: (context, index) {
              final contest = contests[index];
              return ListTile(
                key: ValueKey('contest-${contest.id.value}'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                selected: highlight && contest.id == selectedId,
                selectedTileColor: theme.colorScheme.secondaryContainer,
                leading: _DateBadge(contest.startDateTime.toLocal()),
                title: Text(contest.name),
                subtitle: Text(contestDates(contest)),
                trailing: ContestStatusChip(state: contest.lifecycleState),
                onTap: () => onSelect(contest),
              );
            },
          ),
        ),
      ],
    );
  }

  /// The contest's date range, e.g. `Oct 17, 2026 to Oct 18, 2026`.
  static String contestDates(Contest contest) {
    final format = DateFormat.yMMMd();
    final start = format.format(contest.startDateTime.toLocal());
    final end = format.format(contest.endDateTime.toLocal());
    return start == end ? start : '$start to $end';
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge(this.date);

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat.MMM().format(date).toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          Text('${date.day}', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
