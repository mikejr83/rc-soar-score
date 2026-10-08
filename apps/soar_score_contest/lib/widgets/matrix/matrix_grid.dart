import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/matrix/draw_form_check.dart';
import '../../services/matrix/matrix_grid_model.dart';
import '../../services/matrix/team_marker.dart';
import 'pilot_row_tile.dart';
import 'round_header_cell.dart';

/// Lets the page scroll the grid to a cell, for "Jump to first".
class MatrixGridController {
  _MatrixGridState? _state;

  void jumpTo({required int round, required int group}) =>
      _state?._jumpTo(round, group);
}

/// The round-by-group grid: rounds are columns, groups are rows. Round
/// headings stay at the top and the group column stays at the left while the
/// body scrolls, in both directions.
class MatrixGrid extends StatefulWidget {
  const MatrixGrid({
    super.key,
    required this.model,
    required this.markers,
    required this.selected,
    required this.query,
    required this.teamFilter,
    required this.onSelect,
    required this.controller,
  });

  final MatrixGridModel model;
  final TeamMarkers markers;
  final Id? selected;
  final String query;
  final Id? teamFilter;
  final ValueChanged<Id> onSelect;
  final MatrixGridController controller;

  @override
  State<MatrixGrid> createState() => _MatrixGridState();
}

class _MatrixGridState extends State<MatrixGrid> {
  static const double _labelWidth = 132;
  static const double _columnWidth = 232;
  static const double _addWidth = 150;

  final _body = ScrollController();
  final _bodyV = ScrollController();
  double _scale = 1;
  double _roundWidth = _columnWidth;
  List<double> _rowHeights = const [];

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
  }

  @override
  void dispose() {
    _body.dispose();
    _bodyV.dispose();
    super.dispose();
  }

  void _jumpTo(int round, int group) {
    const duration = Duration(milliseconds: 250);
    if (_body.hasClients) {
      _body.animateTo(
        (round * _roundWidth).clamp(0, _body.position.maxScrollExtent),
        duration: duration,
        curve: Curves.easeOut,
      );
    }
    if (_bodyV.hasClients) {
      final top = _rowHeights.take(group).fold<double>(0, (a, b) => a + b);
      _bodyV.animateTo(
        top.clamp(0, _bodyV.position.maxScrollExtent),
        duration: duration,
        curve: Curves.easeOut,
      );
    }
  }

  bool _visible(GridSlot slot) =>
      widget.teamFilter == null || slot.pilot.teamId == widget.teamFilter;

  double get _pilotHeight => (_scale > 1.15 ? 64 : 32) * _scale;

  /// The height of the group row [group]: the tallest of its cells.
  double _rowHeight(int group) {
    var most = 1;
    var hidden = false;
    for (final round in widget.model.rounds) {
      final slots = round.groups[group];
      final shown = slots.where(_visible).length;
      most = shown > most ? shown : most;
      hidden = hidden || shown < slots.length;
    }
    final content = most * _pilotHeight + 13 + (hidden ? 44 * _scale : 0);
    // The group label needs two lines of text, so a short row is padded.
    return content < 64 * _scale ? 64 * _scale : content;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final model = widget.model;
    _scale = MediaQuery.textScalerOf(context).scale(1).clamp(1, 2).toDouble();
    final groups = model.groupCount;
    _rowHeights = [for (var g = 0; g < groups; g++) _rowHeight(g)];
    final headerHeight = 100 * _scale;
    final border = BorderSide(color: scheme.outlineVariant);

    Widget label(int g) {
      final sizes = [for (final round in model.rounds) round.groups[g].length];
      final size = sizes.isEmpty ? 0 : sizes.reduce((a, b) => a > b ? a : b);
      final mixed = sizes.any((n) => n != size);
      return Container(
        padding: const EdgeInsets.all(12),
        color: scheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group ${DrawFormCheck.groupLetter(g)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              mixed ? 'up to $size pilots' : '$size pilots',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    Widget cell(GridRound round, int g) {
      final slots = round.groups[g];
      final shown = slots.where(_visible).toList();
      final hidden = slots.length - shown.length;
      return Container(
        padding: const EdgeInsets.all(6),
        child: Semantics(
          container: true,
          label:
              'Round ${round.ordinal}, group '
              '${DrawFormCheck.groupLetter(g)}, ${slots.length} pilots',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final slot in shown)
                SizedBox(
                  height: _pilotHeight,
                  child: PilotRowTile(
                    slot: slot,
                    marker: widget.markers.of(slot.pilot.teamId),
                    showTeam: widget.markers.ordered.isNotEmpty,
                    selected: widget.selected == slot.pilot.participationId,
                    matched: slot.pilot.matches(widget.query),
                    showLane: model.hasLanes,
                    round: round.ordinal,
                    group: DrawFormCheck.groupLetter(g),
                    textScale: _scale,
                    onTap: () => widget.onSelect(slot.pilot.participationId),
                  ),
                ),
              if (hidden > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    '$hidden hidden by the team filter',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Column 0 holds the group labels, columns 1..N the rounds and the last
    // one the "Add rounds" button. Row 0 holds the headings. The first row and
    // column are pinned by the table, so it scrolls as one piece.
    final rounds = model.rounds.length;
    Widget gridFor(double columnWidth) {
      final table = TableView.builder(
        key: const ValueKey('grid-scroll'),
        horizontalDetails: ScrollableDetails.horizontal(controller: _body),
        verticalDetails: ScrollableDetails.vertical(controller: _bodyV),
        pinnedRowCount: 1,
        pinnedColumnCount: 1,
        columnCount: rounds + 2,
        rowCount: groups + 1,
        columnBuilder: (column) => TableSpan(
          extent: FixedTableSpanExtent(switch (column) {
            0 => _labelWidth,
            _ when column <= rounds => columnWidth,
            _ => _addWidth,
          }),
          foregroundDecoration: column <= rounds
              ? TableSpanDecoration(border: TableSpanBorder(trailing: border))
              : null,
        ),
        rowBuilder: (row) => TableSpan(
          extent: FixedTableSpanExtent(
            row == 0 ? headerHeight : _rowHeights[row - 1],
          ),
          foregroundDecoration: row <= groups - 1
              ? TableSpanDecoration(border: TableSpanBorder(trailing: border))
              : null,
        ),
        cellBuilder: (context, vicinity) {
          final row = vicinity.row;
          final column = vicinity.column;
          if (row == 0) {
            if (column == 0) {
              return TableViewCell(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.bottomLeft,
                  color: scheme.surfaceContainer,
                  child: Text('Groups', style: theme.textTheme.bodySmall),
                ),
              );
            }
            if (column <= rounds) {
              return TableViewCell(
                child: ColoredBox(
                  color: scheme.surfaceContainer,
                  child: RoundHeaderCell(
                    round: model.rounds[column - 1],
                    pilotCount: model.pilots.length,
                    textScale: _scale,
                  ),
                ),
              );
            }
            return TableViewCell(
              child: Container(
                padding: const EdgeInsets.all(12),
                alignment: Alignment.topLeft,
                color: scheme.surfaceContainer,
                child: Tooltip(
                  message: 'Add rounds · coming in a later release',
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add rounds'),
                  ),
                ),
              ),
            );
          }
          final g = row - 1;
          if (column == 0) return TableViewCell(child: label(g));
          if (column <= rounds) {
            return TableViewCell(child: cell(model.rounds[column - 1], g));
          }
          return const TableViewCell(child: SizedBox.shrink());
        },
      );
      return DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Semantics(
            container: true,
            label: 'Matrix grid, scrolls in both directions',
            child: table,
          ),
        ),
      );
    }

    // The grid is as tall as its rows, so short matrices leave no blank band
    // above Group A or below the last group.
    final total =
        headerHeight + _rowHeights.fold<double>(0, (a, b) => a + b) + 2;
    return LayoutBuilder(
      builder: (context, box) {
        // As in the design, the round columns share the spare width, so the
        // table fills the pane when there are few rounds and scrolls when
        // there are many. The "Add rounds" column keeps its own width.
        final spare = box.maxWidth - 2 - _labelWidth - _addWidth;
        final columnWidth = rounds == 0
            ? _columnWidth
            : (spare / rounds).clamp(_columnWidth, double.infinity).toDouble();
        _roundWidth = columnWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: box.maxHeight.isFinite && box.maxHeight < total
                ? box.maxHeight
                : total,
            child: gridFor(columnWidth),
          ),
        );
      },
    );
  }
}
