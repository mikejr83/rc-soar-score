import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_client_provider.dart';
import '../../router.dart';
import '../../services/scoring/pilot_history.dart';
import '../../services/scoring/row_save.dart';
import '../../services/scoring/score_check.dart';
import '../../services/scoring/score_preview.dart';
import '../../services/scoring/scoring_controller.dart';
import '../../services/scoring/scoring_row.dart';
import '../../widgets/contest_scope.dart';
import '../../widgets/page_states/page_states.dart';
import '../../services/scoring/retire_impact.dart';
import '../../widgets/scoring/penalty_removal_dialog.dart';
import '../../widgets/scoring/retire_pilot_dialog.dart';
import '../../widgets/scoring/score_check_panel.dart';
import '../../widgets/scoring/scoring_refresh_failed_banner.dart';
import '../../widgets/scoring/score_history_dialog.dart';
import '../../widgets/scoring/score_grid_columns.dart';
import '../../widgets/scoring/score_row_tile.dart';
import '../../widgets/scoring/scoring_context_strip.dart';
import '../../widgets/scoring/scoring_toolbar.dart';
import '../../widgets/scoring/unsaved_edits_dialog.dart';
import '../../widgets/unsaved_changes_guard.dart';

/// Official score entry for one group of one round
/// (`plan/ui/contest-administration/official-scoring.md`, ADR 0002).
///
/// The route carries the round and group (`?round=3&group=2`), so refresh
/// and back navigation restore them. Each row saves on its own; a failed save
/// keeps what was typed.
class ContestScoringPage extends StatefulWidget {
  const ContestScoringPage({
    super.key,
    required this.contestId,
    this.round,
    this.group,
    this.guard,
  });

  final String contestId;

  /// The round the page was opened at (`?round=3`), if any.
  final int? round;

  /// The group number within the round (1 is group A), if any.
  final int? group;

  /// Lets the route's `onExit` ask before leaving with unsaved rows.
  final UnsavedChangesGuard? guard;

  @override
  State<ContestScoringPage> createState() => _ContestScoringPageState();
}

class _ContestScoringPageState extends State<ContestScoringPage> {
  ScoringController? _controller;
  String? _focusRow;
  String? _focusField;
  // The lifecycle state the shell was last asked to catch up with, so a slow
  // or failed reload is not repeated on every change of the page.
  LifecycleState? _reloadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final client = apiClientOf(context);
    if (client == null) return;
    final Id id;
    try {
      id = Id.parse(widget.contestId);
    } on ArgumentError {
      return;
    }
    _controller = ScoringController(
      client: client,
      contestId: id,
      round: widget.round,
      group: widget.group,
    )..addListener(_changed);
    widget.guard?.attach(
      _confirmLeave,
      hasChanges: () => _controller?.hasUnsaved ?? false,
    );
    _controller!.load();
  }

  @override
  void didUpdateWidget(ContestScoringPage old) {
    super.didUpdateWidget(old);
    final c = _controller;
    final round = widget.round;
    if (c == null || c.data == null || round == null) return;
    final group = widget.group ?? 1;
    if (round == c.round && group == c.group) return;
    _followRoute(round, group);
  }

  /// The route changed under the page (back button, a link). Unsaved rows
  /// are asked about before the group is replaced.
  Future<void> _followRoute(int round, int group) async {
    final c = _controller!;
    if (c.hasUnsaved) {
      final ok = await _resolveUnsaved();
      if (!ok) {
        if (mounted) {
          context.go(
            contestScoringPath(
              widget.contestId,
              round: c.round,
              group: c.group,
            ),
          );
        }
        return;
      }
    }
    await c.open(round, group);
  }

  @override
  void dispose() {
    widget.guard?.detach(_confirmLeave);
    _controller?.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    _syncShellContest();
  }

  /// The first saved score moves a Ready contest to Running on the server. The
  /// shell loaded the contest once, so without a reload the workspace, rail and
  /// status panel keep showing Ready after the director goes back.
  void _syncShellContest() {
    final scope = ContestScope.maybeOf(context);
    final shown = scope?.contest;
    final saved = _controller?.data?.contest;
    if (scope == null || shown == null || saved == null) return;
    if (shown.lifecycleState == saved.lifecycleState) return;
    if (_reloadedFor == saved.lifecycleState) return;
    _reloadedFor = saved.lifecycleState;
    scope.reload().ignore();
  }

  /// Asks what to do with unsaved rows. True when the caller may go on.
  Future<bool> _resolveUnsaved() async {
    final c = _controller!;
    if (!c.hasUnsaved) return true;
    final choice = await askUnsavedEdits(
      context,
      rows: c.dirtyCount,
      closingApp: UnsavedChangesGuard.closingApp,
    );
    switch (choice) {
      case UnsavedChoice.stay:
        return false;
      case UnsavedChoice.discard:
        c.discardAll();
        return true;
      case UnsavedChoice.save:
        await _saveAllWithRemovals();
        return !c.hasUnsaved;
    }
  }

  Future<bool> _confirmLeave() async {
    if (_controller == null || !mounted) return true;
    return _resolveUnsaved();
  }

  Future<void> _go(int round, int group) async {
    final c = _controller!;
    if (round == c.round && group == c.group) return;
    if (!await _resolveUnsaved()) return;
    if (!mounted) return;
    context.go(
      contestScoringPath(widget.contestId, round: round, group: group),
    );
    // The route builds the page again with the new query; open now too so
    // the group changes even where the query is unchanged on rebuild.
    await c.open(round, group);
  }

  Future<void> _save(ScoringRow row) async {
    final c = _controller!;
    // Removing an applied cumulative penalty is an official correction and
    // needs its own recorded reason before the row is saved. A reason
    // already recorded for this row (its save failed or went stale) is
    // kept instead.
    if (c.isPenaltyRemoval(row)) {
      final reason =
          c.removalReason(row.id) ??
          await askPenaltyRemovalReason(context, pilots: [row.pilot.name]);
      if (!mounted || reason == null) return;
      await c.save(row, reason: reason);
      return;
    }
    final ok = await c.save(row);
    if (!ok || !mounted) return;
    final rows = c.rows;
    final at = rows.indexWhere((r) => r.id == row.id);
    if (at >= 0 && at < rows.length - 1) {
      c.activate(rows[at + 1].id);
    }
  }

  /// Saves every dirty row, first recording a reason for each applied
  /// cumulative penalty the save removes. Returns how many rows saved.
  ///
  /// Removals whose save already failed or went stale keep their recorded
  /// reason and are not asked about again; a missing reason is asked once
  /// for every removal that lacks one.
  Future<int> _saveAllWithRemovals() async {
    final c = _controller!;
    var saved = 0;
    final removal = c.removalRows;
    if (removal.isNotEmpty) {
      final need = [
        for (final r in removal)
          if (c.removalReason(r.id) == null) r,
      ];
      String? freshReason;
      if (need.isNotEmpty) {
        freshReason = await askPenaltyRemovalReason(
          context,
          pilots: [for (final r in need) r.pilot.name],
        );
        if (!mounted || freshReason == null) return 0;
      }
      for (final row in removal) {
        final fresh = c.rows.firstWhere(
          (r) => r.id == row.id,
          orElse: () => row,
        );
        // A removal that already failed or went stale stays with its banner;
        // the director retries or resolves it on the row.
        final pending = c.saveOf(fresh.id).kind;
        if (pending == RowSaveKind.failed ||
            pending == RowSaveKind.stale ||
            pending == RowSaveKind.refused) {
          continue;
        }
        if (c.isPenaltyRemoval(fresh)) {
          final reason = c.removalReason(fresh.id) ?? freshReason;
          if (reason == null) continue;
          if (await c.save(fresh, reason: reason)) saved++;
        }
      }
    }
    saved += await c.saveAll();
    return saved;
  }

  Future<void> _saveAll() async {
    final saved = await _saveAllWithRemovals();
    if (!mounted || saved == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved $saved ${saved == 1 ? 'row' : 'rows'}.')),
    );
  }

  Future<void> _showHistory(ScoringRow row) {
    final c = _controller!;
    return showDialog<void>(
      context: context,
      builder: (context) => ScoreHistoryDialog(
        title: 'Score history · ${row.pilot.name}',
        load: () async => [
          PilotHistory(
            pilot: row.pilot.name,
            entries: (await c.historyOf(row)).entries,
          ),
        ].where((h) => h.entries.isNotEmpty).toList(),
        landings: c.data!.landings,
        zoneId: c.data!.contest.timezone,
      ),
    );
  }

  Future<void> _showGroupHistory() {
    final c = _controller!;
    return showDialog<void>(
      context: context,
      builder: (context) => ScoreHistoryDialog(
        title: 'Group history',
        byPilot: true,
        load: c.groupHistory,
        landings: c.data!.landings,
        zoneId: c.data!.contest.timezone,
      ),
    );
  }

  Future<void> _retire(ScoringRow row) async {
    final c = _controller!;
    final impact = RetireImpact.retire(c.data!, row, c.round);
    final done = await confirmRetirement(
      context,
      impact: impact,
      apply: () => c.retire(row),
    );
    if (done && mounted) {
      _say('${row.pilot.name} retired from round ${c.round}.');
    }
  }

  Future<void> _reinstate(ScoringRow row) async {
    final c = _controller!;
    final impact = RetireImpact.reinstate(c.data!, row);
    final done = await confirmRetirement(
      context,
      impact: impact,
      apply: () => c.reinstate(row),
    );
    if (done && mounted) {
      _say('${row.pilot.name} reinstated.');
    }
  }

  void _say(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _jump(ScoreFinding finding) {
    final id = _controller!.rows
        .where((r) => r.id.value == finding.rowKey)
        .map((r) => r.id)
        .firstOrNull;
    if (id == null) return;
    _controller!.activate(id);
    setState(() {
      _focusRow = finding.rowKey;
      _focusField = finding.field;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _focusRow = null;
          _focusField = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      body: c == null
          ? const PageStateView.unavailable(
              title: 'No API client is available.',
            )
          : _body(c),
    );
  }

  Widget _body(ScoringController c) {
    if (c.data == null) {
      if (c.loadError != null) {
        return loadFailedView(
          c.loadError!,
          title: 'The scores could not be loaded.',
          onRetry: c.load,
        );
      }
      return const PageStateView.loading(
        key: ValueKey('scoring-loading'),
        label: 'Loading the scores',
      );
    }
    final data = c.data!;
    if (data.matrix.isEmpty) {
      return PageStateView.empty(
        title: 'This contest has no matrix yet.',
        body: 'Draw the matrix first. Then scores can be entered here.',
        primary: PageStateAction(
          key: const ValueKey('scoring-open-matrix'),
          label: 'Open the matrix',
          onPressed: () => context.go(contestMatrixPath(widget.contestId)),
        ),
      );
    }
    final rows = c.rows;
    final check = c.check;
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          // Larger text can make these taller than a short screen: they
          // scroll within 40% of it so the scores keep the rest.
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight * .4),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ScoringToolbar(
                    controller: c,
                    onOpen: _go,
                    onSaveAll: _saveAll,
                    onGroupHistory: _showGroupHistory,
                  ),
                  ScoringContextStrip(controller: c),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (c.recalculationWarning != null)
                    MaterialBanner(
                      key: const ValueKey('scoring-recalculation-warning'),
                      content: Text(c.recalculationWarning!),
                      leading: const Icon(Icons.warning_amber),
                      actions: [
                        TextButton(
                          onPressed: c.refresh,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  if (c.loadError != null)
                    ScoringRefreshFailedBanner(
                      error: c.loadError!,
                      onRetry: c.refresh,
                    ),
                  if (check != null)
                    ScoreCheckPanel(
                      result: check,
                      onJump: _jump,
                      onClose: c.clearCheck,
                    ),
                  Expanded(
                    child: rows.isEmpty
                        ? const PageStateView.empty(
                            key: ValueKey('scoring-empty-group'),
                            title: 'No pilots in this group.',
                            body: 'Every pilot assigned here is absent or retired.',
                          )
                        : LayoutBuilder(
                            builder: (context, box) {
                              final mode = ScoreGridMode.of(box.maxWidth);
                              return _table(c, rows, mode);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One rounded table: the heading (wide only) and a row per pilot.
  Widget _table(
    ScoringController c,
    List<ScoringRow> rows,
    ScoreGridMode mode,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('score-table'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (mode == ScoreGridMode.wide)
            ScoreGridHeader(options: c.data!.gridOptions),
          Expanded(
            child: ListView(
              children: [for (final row in rows) _tile(c, row, mode)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(ScoringController c, ScoringRow row, ScoreGridMode mode) {
    final data = c.data!;
    final draft = c.draftOf(row);
    final save = c.saveOf(row.id);
    return ScoreRowTile(
      key: ValueKey('tile-${row.id.value}'),
      row: row,
      draft: draft,
      save: save,
      active: c.activeId == row.id,
      block: c.block,
      landings: data.landings,
      landingTableName: data.landingTableName,
      mode: mode,
      grid: data.gridOptions,
      focusOrder: c.showFocusOrder,
      heightPenalty: draft.height != null && draft.height! > 0
          ? previewHeightPenalty(
              draft.height!,
              discipline:
                  data.base.configuration?.config.discipline ?? const {},
            )
          : null,
      preview: draft.isDirty
          ? previewRawScore(
              draft.components,
              discipline:
                  data.base.configuration?.config.discipline ?? const {},
              landings: data.landings,
            )
          : null,
      findings: c.check?.of(row.id.value).toList() ?? const [],
      theirs: save.kind == RowSaveKind.stale ? c.theirsOf(row.id) : null,
      retireBlocked: c.retireBlocked,
      focusField: _focusRow == row.id.value ? _focusField : null,
      actions: ScoreRowActions(
        onActivate: () => c.activate(row.id),
        onSave: () => _save(row),
        onRevert: () => c.revert(row),
        onKeepMine: () => c.keepMine(row),
        onTakeTheirs: () => c.takeTheirs(row),
        onRefresh: c.refresh,
        onHistory: () => _showHistory(row),
        onRetire: () => _retire(row),
        onReinstate: () => _reinstate(row),
      ),
    );
  }
}
