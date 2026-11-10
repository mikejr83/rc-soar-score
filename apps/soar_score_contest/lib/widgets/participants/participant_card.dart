import 'package:flutter/material.dart';

import '../../services/participants/participant_option.dart';
import '../../services/participants/participant_row.dart';
import '../../services/participants/participant_row_style.dart';
import 'participant_cells.dart';
import 'participant_editing.dart';
import 'participant_row_note_view.dart';

/// One participant as a stacked card, for narrow windows: name, email and
/// status on top, then a labelled field for each enabled column.
class ParticipantCard extends StatelessWidget {
  const ParticipantCard({
    super.key,
    required this.editing,
    required this.participant,
    this.selectable = true,
    this.actions,
  });

  final ParticipantEditing editing;
  final ParticipantRow participant;
  final bool selectable;

  /// Optional actions beside the status, matching the wide table.
  final Widget? actions;

  static const double _minFieldWidth = 170;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cells = ParticipantCells(editing, participant, height: 44);
    final rowStyle = cells.style;
    final note = rowStyle.note;
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
      // The number leads, like the table's first column.
      if (editing.rules.has(ParticipantOption.pilotNumbers))
        labelled('Pilot no.', cells.number(context)),
      for (final option in ParticipantCells.columnsFor(editing))
        ...switch (option) {
          ParticipantOption.roles => [labelled('Role', cells.role(context))],
          ParticipantOption.classes => [
            labelled(
              'Class *',
              cells.classification(context),
              error: cells.issues.contains(ParticipantIssue.classification),
            ),
          ],
          ParticipantOption.teams => [labelled('Team', cells.team(context))],
          // The number field already leads the card.
          ParticipantOption.pilotNumbers => const [],
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
        padding: EdgeInsets.fromLTRB(selectable ? 4 : 16, 8, 16, 16),
        decoration: BoxDecoration(
          color: cells.selected
              ? scheme.secondaryContainer
              : rowStyle.highlighted && !rowStyle.hasChanges
              ? scheme.primaryContainer
              : rowStyle.hasChanges
              ? Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.07),
                  scheme.surfaceContainerLow,
                )
              : scheme.surfaceContainerLow,
          border: Border.all(
            color: note?.tone == ParticipantNoteTone.error || hasIssues
                ? scheme.error
                : note != null
                ? scheme.tertiary
                : rowStyle.hasChanges || rowStyle.highlighted
                ? scheme.primary
                : scheme.outlineVariant,
            width:
                hasIssues ||
                    note != null ||
                    rowStyle.hasChanges ||
                    rowStyle.highlighted
                ? 2
                : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (selectable) ...[
                  SizedBox.square(dimension: 44, child: cells.checkbox()),
                  const SizedBox(width: 8),
                ],
                cells.avatar(context, size: 36),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      cells.nameBlock(context),
                      cells.emailCell(context, prefix: true),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                cells.status(context),
                ?actions,
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
            if (note != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: ParticipantRowNoteView(
                  note: note,
                  rowId: participant.rowId,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
