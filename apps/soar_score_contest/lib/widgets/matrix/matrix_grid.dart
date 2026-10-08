import 'package:flutter/material.dart';
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
  static const double _addWidth = 176;

  final _body = ScrollController();
  final _bodyV = ScrollController();
  final _header = ScrollController();
  final _labels = ScrollController();
  double _scale = 1;
  List<double> _rowHeights = const [];

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
    _body.addListener(() => _follow(_header, _body));
    _bodyV.addListener(() => _follow(_labels, _bodyV));
  }

  @override
  void dispose() {
    for (final controller in [_body, _bodyV, _header, _labels]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _follow(ScrollController follower, ScrollController leader) {
    if (follower.hasClients && leader.hasClients) {
      final max = follower.position.maxScrollExtent;
      follower.jumpTo(leader.offset.clamp(0, max));
    }
  }

  void _jumpTo(int round, int group) {
    const duration = Duration(milliseconds: 250);
    if (_body.hasClients) {
      _body.animateTo(
        (round * _columnWidth).clamp(0, _body.position.maxScrollExtent),
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

    // The grid's own outline closes the last row, so it has no border of its
    // own; otherwise the two lines draw as one thick line.
    BorderSide bottomBorder(int g) =>
        g == groups - 1 ? BorderSide.none : border;

    Widget label(int g) {
      final sizes = [for (final round in model.rounds) round.groups[g].length];
      final size = sizes.isEmpty ? 0 : sizes.reduce((a, b) => a > b ? a : b);
      final mixed = sizes.any((n) => n != size);
      return Container(
        height: _rowHeights[g],
        width: _labelWidth,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border(right: border, bottom: bottomBorder(g)),
        ),
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

    Widget cell(GridRound round, int roundIndex, int g) {
      final slots = round.groups[g];
      final shown = slots.where(_visible).toList();
      final hidden = slots.length - shown.length;
      return Container(
        width: _columnWidth,
        height: _rowHeights[g],
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border(right: border, bottom: bottomBorder(g)),
        ),
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

    Widget gridFor(double addW) {
      final headerRow = Row(
        children: [
          for (final round in model.rounds)
            Container(
              width: _columnWidth,
              height: headerHeight,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                border: Border(right: border, bottom: border),
              ),
              child: RoundHeaderCell(
                round: round,
                pilotCount: model.pilots.length,
                textScale: _scale,
              ),
            ),
          Container(
            width: addW,
            height: headerHeight,
            padding: const EdgeInsets.all(12),
            alignment: Alignment.topLeft,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              border: Border(bottom: border),
            ),
            child: Tooltip(
              message: 'Add rounds · coming in a later release',
              child: OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add rounds'),
              ),
            ),
          ),
        ],
      );

      final grid = DecoratedBox(
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
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: _labelWidth,
                      height: headerHeight,
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.bottomLeft,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer,
                        border: Border(right: border, bottom: border),
                      ),
                      child: Text('Groups', style: theme.textTheme.bodySmall),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _header,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: headerRow,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: _labelWidth,
                        child: SingleChildScrollView(
                          controller: _labels,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              for (var g = 0; g < groups; g++) label(g),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: _body,
                          child: SingleChildScrollView(
                            key: const ValueKey('grid-scroll'),
                            controller: _body,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: model.rounds.length * _columnWidth + addW,
                              child: SingleChildScrollView(
                                controller: _bodyV,
                                child: Column(
                                  children: [
                                    for (var g = 0; g < groups; g++)
                                      Row(
                                        children: [
                                          for (
                                            var r = 0;
                                            r < model.rounds.length;
                                            r++
                                          )
                                            cell(model.rounds[r], r, g),
                                          // Continues the grid lines under
                                          // the "Add rounds" header column.
                                          Container(
                                            width: addW,
                                            height: _rowHeights[g],
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: bottomBorder(g),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      return grid;
    }

    // The grid is as tall as its rows, so short matrices leave no blank band
    // above Group A or below the last group.
    final total =
        headerHeight + _rowHeights.fold<double>(0, (a, b) => a + b) + 2;
    return LayoutBuilder(
      builder: (context, box) {
        // The "Add rounds" column takes whatever width the rounds leave, so
        // the header and the body cells run to the grid's right border.
        final spare =
            box.maxWidth - 2 - _labelWidth - model.rounds.length * _columnWidth;
        final addW = spare > _addWidth ? spare : _addWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: box.maxHeight.isFinite && box.maxHeight < total
                ? box.maxHeight
                : total,
            child: gridFor(addW),
          ),
        );
      },
    );
  }
}
