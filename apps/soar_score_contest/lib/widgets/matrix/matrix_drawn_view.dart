import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/matrix/config_drift.dart';
import '../../services/matrix/matrix_grid_model.dart';
import '../../services/matrix/matrix_page_data.dart';
import '../../services/matrix/matrix_rounds_plan.dart';
import 'fairness_panel.dart';
import 'find_filter_bar.dart';
import '../page_states/page_banner.dart';
import 'matrix_banner.dart';
import 'matrix_grid.dart';
import 'pilot_panel.dart';

/// The page once a matrix exists (mode 2): the configuration-changed
/// notice, the add rounds and redraw buttons, the fairness summary, find and
/// filter, the grid and the pilot panel.
class MatrixDrawnView extends StatefulWidget {
  const MatrixDrawnView({
    super.key,
    required this.data,
    required this.onOpenConfiguration,
    required this.plan,
    required this.onAddRounds,
    required this.onRedraw,
    this.actionBlock,
    this.onMovePilot,
  });

  final MatrixPageData data;
  final VoidCallback onOpenConfiguration;
  final MatrixRoundsPlan plan;

  /// Open the add rounds and redraw forms.
  final VoidCallback onAddRounds;
  final VoidCallback onRedraw;

  /// Why both actions are off for the whole contest (administration locked,
  /// or the contest is not in a state that allows them), or `null`.
  final String? actionBlock;

  /// Moves the pilot of an assignment (the pilot actions menu); `null` leaves
  /// the menu off.
  final ValueChanged<Id>? onMovePilot;

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

  /// Why redrawing the unscored rounds is not possible, or `null`.
  String? _redrawBlock(AppLocalizations l10n) {
    final plan = widget.plan;
    return switch (plan.blockKind) {
      null => null,
      RedrawBlockKind.allScored => l10n.matrixRedrawAllScored,
      RedrawBlockKind.roundLocked => l10n.matrixRedrawRoundLocked(
        plan.blockRound!,
      ),
      RedrawBlockKind.groupLocked => l10n.matrixRedrawGroupLocked(
        plan.blockRound!,
      ),
    };
  }

  /// The preliminary-round status of a seeded contest, or `null`.
  String? _seededStatus(AppLocalizations l10n) {
    final options = widget.data.options;
    final preliminary = options?.preliminaryRounds;
    if (options?.drawMode != DrawMode.seededManOnMan || preliminary == null) {
      return null;
    }
    var missing = 0;
    for (final round in _model.rounds) {
      if (round.ordinal <= preliminary) {
        final progress = round.progress;
        missing += progress.total - progress.scored;
      }
    }
    return missing == 0
        ? l10n.matrixSeededStatusDone(preliminary)
        : l10n.matrixSeededStatusWaiting(preliminary, missing);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final revision = data.matrix.revision!;
    final drift = ConfigDrift.differences(
      revision: revision,
      options: data.options,
    );
    final l10n = AppLocalizations.of(context);
    final redrawBlock = widget.actionBlock ?? _redrawBlock(l10n);
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
          onAddRounds: widget.actionBlock == null ? widget.onAddRounds : null,
          onMove: widget.onMovePilot,
          moveBlock: switch (data.contest) {
            Contest(adminLock: AdminLock.locked) => l10n.matrixMoveLocked,
            Contest(:final lifecycleState)
                when lifecycleState != LifecycleState.ready &&
                    lifecycleState != LifecycleState.running =>
              l10n.matrixMoveNotEditable,
            _ => null,
          },
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
                  // Larger text can make these taller than the screen: they
                  // scroll within half of it so the grid keeps the rest.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * .5,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 12,
                        children: [
                          if (drift.isNotEmpty)
                            MatrixBanner(
                              kind: MatrixBannerKind.warning,
                              icon: Icons.info,
                              title: 'Configuration changed since this draw',
                              body: redrawBlock == null
                                  ? l10n.matrixDriftBanner(drift.join(' '))
                                  : l10n.matrixDriftBannerBlocked(
                                      drift.join(' '),
                                      redrawBlock,
                                    ),
                              actions: [
                                if (redrawBlock == null)
                                  PageBannerAction(
                                    l10n.matrixRedrawButton,
                                    widget.onRedraw,
                                    emphasis: PageBannerEmphasis.filled,
                                    key: const ValueKey('banner-redraw'),
                                  ),
                                PageBannerAction(
                                  'Open Configuration',
                                  widget.onOpenConfiguration,
                                  emphasis: PageBannerEmphasis.outlined,
                                ),
                              ],
                            ),
                          _ActionBar(
                            adding: widget.actionBlock == null
                                ? widget.onAddRounds
                                : null,
                            redraw: redrawBlock == null
                                ? widget.onRedraw
                                : null,
                            reason: redrawBlock,
                            seeded:
                                data.options?.drawMode ==
                                DrawMode.seededManOnMan,
                            status: _seededStatus(l10n),
                          ),
                          FairnessPanel(
                            revision: revision,
                            hasLanes: _model.hasLanes,
                            configurationRevision:
                                data.configuration?.revisionNumber,
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
                            onTeam: (team) =>
                                setState(() => _teamFilter = team),
                          ),
                        ],
                      ),
                    ),
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

/// The Add rounds and Redraw unscored rounds buttons. A button that is not
/// allowed is shown disabled, with the reason beside it.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.adding,
    required this.redraw,
    required this.reason,
    required this.seeded,
    required this.status,
  });

  final VoidCallback? adding;
  final VoidCallback? redraw;
  final String? reason;
  final bool seeded;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('add-rounds'),
              onPressed: adding,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.matrixAddRoundsButton),
            ),
            OutlinedButton.icon(
              key: const ValueKey('redraw-rounds'),
              onPressed: redraw,
              icon: const Icon(Icons.shuffle, size: 18),
              label: Text(l10n.matrixRedrawButton),
            ),
            if (reason != null)
              Semantics(
                liveRegion: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Text(
                          reason!,
                          key: const ValueKey('redraw-reason-text'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (seeded && status != null)
          Text(
            status!,
            key: const ValueKey('seeded-status'),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
      ],
    );
  }
}
