import 'package:flutter/material.dart';

import '../../services/participants/participant_option.dart';
import '../../services/participants/participant_row.dart';
import 'participant_cells.dart';
import 'participant_editing.dart';

/// One participant as a stacked card, for narrow windows: name, email and
/// status on top, then a labelled field for each enabled column.
class ParticipantCard extends StatelessWidget {
  const ParticipantCard({
    super.key,
    required this.editing,
    required this.participant,
  });

  final ParticipantEditing editing;
  final ParticipantRow participant;

  static const double _minFieldWidth = 170;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cells = ParticipantCells(editing, participant, height: 44);
    final hasIssues = cells.issues.isNotEmpty;
    final label = theme.textTheme.bodySmall;

    Widget labelled(String text, Widget field, {bool error = false}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: label?.copyWith(
            color: error ? scheme.error : scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        field,
      ],
    );

    final fields = <Widget>[
      for (final option in ParticipantCells.columnsFor(editing))
        ...switch (option) {
          ParticipantOption.roles => [labelled('Role', cells.role(context))],
          ParticipantOption.classes => [
            labelled(
              'Class *',
              cells.classification(),
              error: cells.issues.contains(ParticipantIssue.classification),
            ),
          ],
          ParticipantOption.teams => [labelled('Team', cells.team())],
          ParticipantOption.pilotNumbers => [
            labelled('Pilot no.', cells.number(context)),
          ],
          ParticipantOption.models => [
            labelled('Models', cells.modelsCell(context)),
          ],
        },
    ];

    return Semantics(
      container: true,
      label: participant.name,
      child: Container(
        key: ValueKey('card-${participant.rowId}'),
        padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
        decoration: BoxDecoration(
          color: cells.selected
              ? scheme.secondaryContainer
              : scheme.surfaceContainerLow,
          border: Border.all(
            color: hasIssues ? scheme.error : scheme.outlineVariant,
            width: hasIssues ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox.square(dimension: 44, child: cells.checkbox()),
                const SizedBox(width: 8),
                cells.avatar(context, size: 36),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(participant.name, style: theme.textTheme.bodyLarge),
                      cells.emailCell(context, prefix: true),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                cells.status(context),
              ],
            ),
            if (fields.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = (constraints.maxWidth / _minFieldWidth)
                        .floor()
                        .clamp(1, fields.length);
                    final width =
                        (constraints.maxWidth - 12 * (columns - 1)) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final field in fields)
                          SizedBox(width: width, child: field),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
