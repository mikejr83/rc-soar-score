import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'contest_status_chip.dart';

/// The master pane of the contests page: title and count, then one row per
/// contest with a date badge, name, dates and status. The row for
/// [selectedId] is highlighted when [highlight] is set.
class ContestList extends StatefulWidget {
  const ContestList({
    required this.contests,
    required this.selectedId,
    required this.highlight,
    required this.onSelect,
    this.onOpen,
    super.key,
  });

  final List<Contest> contests;
  final Id? selectedId;
  final bool highlight;
  final ValueChanged<Contest> onSelect;

  /// Opens a contest: a double-click or Enter on its row. Rows only select
  /// when this is null.
  final ValueChanged<Contest>? onOpen;

  @override
  State<ContestList> createState() => _ContestListState();

  /// The contest's date range, e.g. `Oct 17, 2026 to Oct 18, 2026`.
  static String contestDates(Contest contest) {
    final format = DateFormat.yMMMd();
    final start = format.format(contest.startDateTime.toLocal());
    final end = format.format(contest.endDateTime.toLocal());
    return start == end ? start : '$start to $end';
  }
}

class _ContestListState extends State<ContestList> {
  /// How soon a second tap on the same row counts as a double-click.
  static const _doubleClick = Duration(milliseconds: 300);

  // Double-clicks are detected here rather than with a gesture detector,
  // which would hold back the row's selection until the window passed.
  Id? _tappedId;
  Timer? _tappedTimer;

  @override
  void dispose() {
    _tappedTimer?.cancel();
    super.dispose();
  }

  void _tap(Contest contest) {
    widget.onSelect(contest);
    final open = widget.onOpen;
    if (open != null && _tappedId == contest.id) {
      _tappedTimer?.cancel();
      _tappedId = null;
      open(contest);
      return;
    }
    _tappedId = contest.id;
    _tappedTimer?.cancel();
    _tappedTimer = Timer(_doubleClick, () => _tappedId = null);
  }

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
                  '${widget.contests.length} contests',
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
            itemCount: widget.contests.length,
            itemBuilder: (context, index) {
              final contest = widget.contests[index];
              final tile = ListTile(
                key: ValueKey('contest-${contest.id.value}'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                selected: widget.highlight && contest.id == widget.selectedId,
                selectedTileColor: theme.colorScheme.secondaryContainer,
                leading: _DateBadge(contest.startDateTime.toLocal()),
                title: Text(contest.name),
                subtitle: Text(ContestList.contestDates(contest)),
                trailing: ContestStatusChip(state: contest.lifecycleState),
                onTap: () => _tap(contest),
              );
              final open = widget.onOpen;
              if (open == null) {
                return tile;
              }
              return CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.enter): () =>
                      open(contest),
                  const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
                      open(contest),
                },
                child: tile,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge(this.date);

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 48 square at the default text size, and growing with the text.
    final side = MediaQuery.textScalerOf(context).scale(48);
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
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
      ),
    );
  }
}
