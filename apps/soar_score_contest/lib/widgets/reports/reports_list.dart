import 'package:flutter/material.dart';

import '../../services/reports/report_availability.dart';
import '../../services/reports/report_kind.dart';
import '../../services/reports/reports_facts.dart';
import 'report_card.dart';

/// The report cards under their group headings. Two columns at an expanded
/// window, one below; a group takes any number of cards.
class ReportsList extends StatelessWidget {
  const ReportsList({
    super.key,
    required this.facts,
    required this.twoColumns,
    required this.compact,
    required this.onOpen,
    required this.onAction,
  });

  final ReportsFacts facts;
  final bool twoColumns;
  final bool compact;
  final ValueChanged<ReportKind> onOpen;
  final ValueChanged<ReportAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 28,
      children: [
        for (final group in ReportGroup.values)
          Column(
            key: ValueKey('report-group-${group.name}'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      group.title,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  Text(
                    group.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              _Grid(
                twoColumns: twoColumns,
                children: [
                  for (final kind in ReportKind.of(group))
                    ReportCard(
                      kind: kind,
                      availability: ReportAvailability.of(kind, facts),
                      compact: compact,
                      onOpen: () => onOpen(kind),
                      onAction: onAction,
                    ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}

/// Lays cards out in equal-width rows of one or two, each row as tall as its
/// tallest card.
class _Grid extends StatelessWidget {
  const _Grid({required this.twoColumns, required this.children});

  final bool twoColumns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final columns = twoColumns ? 2 : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        for (var i = 0; i < children.length; i += columns)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                for (var j = i; j < i + columns; j++)
                  Expanded(
                    child: j < children.length
                        ? children[j]
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
