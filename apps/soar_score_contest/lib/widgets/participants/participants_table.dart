import 'package:flutter/material.dart';

import '../../services/participants/participant_option.dart';
import '../../services/participants/participant_row.dart';
import 'participant_cells.dart';
import 'participant_editing.dart';
import 'participant_row_note_view.dart';

/// A table column: its header, minimum width, share of extra width and
/// cell.
class _Column {
  const _Column(this.header, this.minWidth, this.flex, this.cell);

  final String header;
  final double minWidth;
  final double flex;
  final Widget Function(BuildContext context, ParticipantCells cells) cell;
}

/// The inline-editable participant table for wide windows. Columns exist
/// only for the options turned on in step 3; when the window is narrower
/// than the columns need, the table scrolls sideways.
class ParticipantsTable extends StatelessWidget {
  const ParticipantsTable({
    super.key,
    required this.editing,
    required this.rows,
    required this.onToggleAll,
    this.selectable = true,
  });

  final ParticipantEditing editing;

  /// The rows to show (all, or only those needing fixes).
  final List<ParticipantRow> rows;

  final VoidCallback onToggleAll;

  /// Whether rows can be selected (a read-only list hides the checkboxes).
  final bool selectable;

  static const double _gap = 8;
  static const double _padding = 12;

  List<_Column> _columns() => [
    _Column(
      'Name',
      130,
      1.4,
      (context, cells) => Row(
        children: [
          cells.avatar(context),
          const SizedBox(width: 10),
          Expanded(child: cells.nameBlock(context)),
        ],
      ),
    ),
    _Column('Email', 170, 1.3, (context, cells) => cells.emailCell(context)),
    for (final option in ParticipantCells.columnsFor(editing))
      ...switch (option) {
        ParticipantOption.roles => [
          _Column('Role', 128, 0, (context, cells) => cells.role(context)),
        ],
        ParticipantOption.classes => [
          _Column(
            'Class *',
            112,
            0,
            (context, cells) => cells.classification(context),
          ),
        ],
        ParticipantOption.teams => [
          _Column('Team', 150, 1.2, (context, cells) => cells.team(context)),
        ],
        ParticipantOption.pilotNumbers => [
          _Column(
            editing.rules.numberHeader,
            110,
            0,
            (context, cells) => cells.number(context),
          ),
        ],
        ParticipantOption.models => [
          _Column(
            'Models',
            150,
            0,
            (context, cells) => cells.modelsCell(context),
          ),
        ],
      },
    _Column('Status', 110, 0, (context, cells) => cells.status(context)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final columns = _columns();
    final checkboxWidth = selectable ? 40.0 : 0.0;
    final minWidth =
        checkboxWidth +
        columns.fold<double>(0, (sum, column) => sum + column.minWidth) +
        _gap * columns.length +
        _padding * 2;
    final totalFlex = columns.fold<double>(0, (sum, c) => sum + c.flex);
    final all =
        rows.isNotEmpty &&
        rows.every((p) => editing.selected.contains(p.rowId));
    final some = rows.any((p) => editing.selected.contains(p.rowId));

    return Semantics(
      container: true,
      label: 'Contest participants',
      child: Container(
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < minWidth
                ? minWidth
                : constraints.maxWidth;
            final extra = width - minWidth;
            final widths = [
              for (final column in columns)
                column.minWidth +
                    (totalFlex == 0 ? 0 : extra * column.flex / totalFlex),
            ];

            Widget line({
              required List<Widget> cells,
              required Widget lead,
              double minHeight = 56,
              Color? color,
              bool divider = true,
              Key? key,
              Widget? note,
            }) => Container(
              key: key,
              constraints: BoxConstraints(minHeight: minHeight),
              padding: const EdgeInsets.symmetric(
                horizontal: _padding,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: color,
                border: divider
                    ? Border(bottom: BorderSide(color: scheme.outlineVariant))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (selectable)
                        SizedBox(width: checkboxWidth, child: lead),
                      for (final (index, cell) in cells.indexed) ...[
                        if (selectable || index > 0)
                          const SizedBox(width: _gap),
                        SizedBox(width: widths[index], child: cell),
                      ],
                    ],
                  ),
                  ?note,
                ],
              ),
            );

            final headerStyle = theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            );
            final table = SizedBox(
              width: width,
              child: Column(
                children: [
                  line(
                    minHeight: 48,
                    lead: Checkbox(
                      value: all ? true : (some ? null : false),
                      tristate: true,
                      semanticLabel: 'Select all',
                      onChanged: (_) => onToggleAll(),
                    ),
                    cells: [
                      for (final column in columns)
                        Semantics(
                          header: true,
                          child: Text(column.header, style: headerStyle),
                        ),
                    ],
                  ),
                  for (final (index, participant) in rows.indexed)
                    () {
                      final cells = ParticipantCells(editing, participant);
                      final style = cells.style;
                      final note = style.note;
                      return line(
                        key: ValueKey('row-${participant.rowId}'),
                        color: style.highlighted && !style.hasChanges
                            ? scheme.primaryContainer
                            : cells.selected
                            ? scheme.onSurface.withValues(alpha: 0.08)
                            : style.hasChanges
                            ? scheme.primary.withValues(alpha: 0.07)
                            : null,
                        note: note == null
                            ? null
                            : Padding(
                                padding: const EdgeInsets.only(
                                  top: 6,
                                  bottom: 2,
                                ),
                                child: ParticipantRowNoteView(
                                  note: note,
                                  rowId: participant.rowId,
                                ),
                              ),
                        divider: index < rows.length - 1,
                        lead: cells.checkbox(),
                        cells: [
                          for (final column in columns)
                            column.cell(context, cells),
                        ],
                      );
                    }(),
                ],
              ),
            );
            return constraints.maxWidth < minWidth
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: table,
                  )
                : table;
          },
        ),
      ),
    );
  }
}
