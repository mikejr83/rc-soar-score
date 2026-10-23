import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/matrix/config_drift.dart';
import '../../services/matrix/matrix_grid_model.dart';
import '../../services/matrix/matrix_page_data.dart';
import 'fairness_panel.dart';
import 'find_filter_bar.dart';
import '../page_states/page_banner.dart';
import 'matrix_banner.dart';
import 'matrix_grid.dart';
import 'pilot_panel.dart';

/// The page once a matrix exists (mode 2): the configuration-changed
/// notice, the fairness summary, find and filter, the grid and the pilot
/// panel. There is no primary action; the page is for reading.
class MatrixDrawnView extends StatefulWidget {
  const MatrixDrawnView({
    super.key,
    required this.data,
    required this.onOpenConfiguration,
  });

  final MatrixPageData data;
  final VoidCallback onOpenConfiguration;

  @override
  State<MatrixDrawnView> createState() => _MatrixDrawnViewState();
}

class _MatrixDrawnViewState extends State<MatrixDrawnView> {
  /// Below this width the pilot panel is a bottom sheet instead of a side
  /// sheet, and the summary starts as one line.
  static const double narrowWidth = 900;

  final _search = TextEditingController();
  final _grid = MatrixGridController();
  final _focus = FocusNode(debugLabel: 'matrix page');
  Id? _selected;
  Id? _teamFilter;
  late MatrixGridModel _model = _build();

  MatrixGridModel _build() =>
      MatrixGridModel.of(widget.data.matrix, widget.data.pilots);

  @override
  void didUpdateWidget(MatrixDrawnView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.matrix != widget.data.matrix) {
      _model = _build();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _select(Id id) {
    // Keep keyboard focus on the page so Esc clears the highlight.
    _focus.requestFocus();
    setState(() => _selected = _selected == id ? null : id);
  }

  /// The earliest round, then the top group, that holds a match.
  (int, int)? get _firstMatch {
    final query = _search.text;
    for (var r = 0; r < _model.rounds.length; r++) {
      final groups = _model.rounds[r].groups;
      for (var g = 0; g < groups.length; g++) {
        if (groups[g].any((slot) => slot.pilot.matches(query))) {
          return (r, g);
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final revision = data.matrix.revision!;
    final drift = ConfigDrift.differences(
      revision: revision,
      options: data.options,
    );
    final query = _search.text;
    final matches = _model.pilots.where((p) => p.matches(query)).length;
    final teamSizes = <Id, int>{};
    for (final pilot in _model.pilots) {
      final team = pilot.teamId;
      if (team != null) {
        teamSizes[team] = (teamSizes[team] ?? 0) + 1;
      }
    }
    final selected = _selected == null
        ? null
        : _model.pilots
              .where((pilot) => pilot.participationId == _selected)
              .firstOrNull;
    final filtered = _teamFilter == null ? null : data.markers.of(_teamFilter);
    final live = selected != null
        ? '${selected.name} highlighted in ${_model.rounds.length} rounds. '
              'Opponent panel open.'
        : filtered != null
        ? 'Showing ${filtered.name} only: ${teamSizes[_teamFilter] ?? 0} '
              'pilots in each round.'
        : query.trim().isNotEmpty
        ? (matches > 0 ? '$matches pilots match.' : 'No pilot matches.')
        : '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < narrowWidth;
        final grid = MatrixGrid(
          model: _model,
          dropAfterRounds: data.options?.dropAfterRounds ?? const [],
          markers: data.markers,
          selected: _selected,
          query: query,
          teamFilter: _teamFilter,
          onSelect: _select,
          controller: _grid,
        );
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () {
              if (_selected != null) {
                setState(() => _selected = null);
              }
            },
          },
          child: Focus(
            focusNode: _focus,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Semantics(
                    liveRegion: true,
                    label: live,
                    child: const SizedBox.shrink(),
                  ),
                  if (drift.isNotEmpty)
                    MatrixBanner(
                      kind: MatrixBannerKind.warning,
                      icon: Icons.info,
                      title: 'Configuration changed since this draw',
                      body:
                          '${drift.join(' ')} The matrix is unchanged. '
                          'Applying these changes needs a redraw, which comes '
                          'in a later release.',
                      actions: [
                        PageBannerAction(
                          'Open Configuration',
                          widget.onOpenConfiguration,
                          emphasis: PageBannerEmphasis.outlined,
                        ),
                      ],
                    ),
                  FairnessPanel(
                    revision: revision,
                    hasLanes: _model.hasLanes,
                    configurationRevision: data.configuration?.revisionNumber,
                    startCollapsed: narrow,
                  ),
                  FindFilterBar(
                    search: _search,
                    matches: matches,
                    markers: data.markers,
                    teamSizes: teamSizes,
                    teamFilter: _teamFilter,
                    showNumbers: data.showNumbers,
                    onQuery: (_) => setState(() {}),
                    onJump: () {
                      final first = _firstMatch;
                      if (first != null) {
                        _grid.jumpTo(round: first.$1, group: first.$2);
                      }
                    },
                    onTeam: (team) => setState(() => _teamFilter = team),
                  ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: grid),
                        if (selected != null && !narrow) ...[
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PilotPanel(
                              model: _model,
                              pilot: selected,
                              markers: data.markers,
                              bottom: false,
                              onClose: () => setState(() => _selected = null),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (selected != null && narrow)
                    PilotPanel(
                      model: _model,
                      pilot: selected,
                      markers: data.markers,
                      bottom: true,
                      sheetHeight: (constraints.maxHeight * .4).clamp(200, 380),
                      onClose: () => setState(() => _selected = null),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
