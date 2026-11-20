import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_client_provider.dart';
import '../../l10n/app_localizations.dart';
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
import '../../widgets/scoring/confirm_zeros_dialog.dart';
import '../../widgets/scoring/unsaved_edits_dialog.dart';
import '../../widgets/unsaved_changes_guard.dart';
import '../../widgets/sync/reload_on_sync.dart';

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
      rows: c.unsavedCount,
      closingApp: UnsavedChangesGuard.closingApp,
    );
    switch (choice) {
      case UnsavedChoice.stay:
        return false;
      case UnsavedChoice.discard:
        c.discardEdits();
        return true;
      case UnsavedChoice.save:
        await _saveAllWithRemovals(editedOnly: true);
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

  /// Saves every dirty row in one bulk request, first recording a reason for
  /// each applied cumulative penalty the save removes. Returns how many rows
  /// saved.
  ///
  /// Removals whose save already failed, was refused or went stale keep their
  /// banner and are not asked about; a missing reason is asked once for every
  /// other removal that lacks one.
  Future<int> _saveAllWithRemovals({bool editedOnly = false}) async {
    final c = _controller!;
    final need = [
      for (final r in c.removalRows(editedOnly: editedOnly))
        if (c.removalReason(r.id) == null &&
            !const {
              RowSaveKind.failed,
              RowSaveKind.stale,
              RowSaveKind.refused,
            }.contains(c.saveOf(r.id).kind))
          r,
    ];
    if (need.isNotEmpty) {
      final reason = await askPenaltyRemovalReason(
        context,
        pilots: [for (final r in need) r.pilot.name],
      );
      if (!mounted || reason == null) return 0;
      for (final r in need) {
        c.recordRemovalReason(r.id, reason);
      }
    }
    // Save row asks for a zero to be confirmed, so saving many rows does too.
    final zeros = c.unconfirmedZeroRows(editedOnly: editedOnly);
    if (zeros.isNotEmpty && !await askConfirmZeros(context, zeros)) return 0;
    if (!mounted) return 0;
    return c.saveAll(editedOnly: editedOnly);
  }

  Future<void> _saveAll() async {
    final saved = await _saveAllWithRemovals();
    if (!mounted || saved == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved $saved ${saved == 1 ? 'row' : 'rows'}.')),
    );
  }

  /// The row's Mark official or Confirm button, or, for [retry], the banner's
  /// Retry of the request that failed.
  Future<void> _markOfficial(ScoringRow row, {bool retry = false}) async {
    final c = _controller!;
    final confirming = retry
        ? c.saveOf(row.id).target?.confirm ?? false
        : row.isAutomaticUnconfirmed;
    final ok = retry ? await c.retryPromotion(row) : await c.promote(row);
    final now = c.rows.where((r) => r.id == row.id).firstOrNull;
    if (ok && mounted && (now?.isAdoptionPending ?? false)) {
      final words = AppLocalizations.of(context);
      _say(
        confirming
            ? words.scoreConfirmQueued(row.pilot.name)
            : words.scoreMarkOfficialQueued(row.pilot.name),
      );
    }
    // The banner with the reason sits in the row's band, so open it.
    if (!ok && mounted && c.saveOf(row.id).kind != RowSaveKind.idle) {
      c.activate(row.id);
    }
  }

  /// Marks every valid row of the group official in one request, without
  /// asking (each row is checked on its own by the server), and says what
  /// happened, row by row where it did not go through.
  Future<void> _markAll() async {
    final c = _controller!;
    if (c.markAllRows.isEmpty) return;
    final words = AppLocalizations.of(context);
    final summary = await c.markAllOfficial();
    if (!mounted) return;
    final parts = [
      summary.nothingAccepted
          ? words.scoreMarkAllNothing
          : words.scoreMarkAllDone(summary.official),
      if (summary.queued > 0) words.scoreMarkAllQueued(summary.queued),
      if (summary.changed > 0) words.scoreMarkAllChanged(summary.changed),
      if (summary.refused > 0) words.scoreMarkAllRefused(summary.refused),
      if (summary.retry > 0) words.scoreMarkAllRetry(summary.retry),
      ..._skipLines(words, summary.skipped),
    ];
    _say(parts.join(' '));
  }

  static List<String> _skipLines(
    AppLocalizations words,
    Map<MarkOfficialSkip, int> skipped,
  ) {
    final lines = <String>[];
    for (final MapEntry(:key, :value) in skipped.entries) {
      switch (key) {
        case MarkOfficialSkip.edited:
          lines.add(words.scoreMarkAllSkipEdited(value));
        case MarkOfficialSkip.inReview:
          lines.add(words.scoreMarkAllSkipReview(value));
        case MarkOfficialSkip.closed:
          lines.add(words.scoreMarkAllSkipClosed(value));
        case MarkOfficialSkip.retired:
          lines.add(words.scoreMarkAllSkipRetired(value));
        case MarkOfficialSkip.waitingToSync:
          lines.add(words.scoreMarkAllSkipWaiting(value));
        case MarkOfficialSkip.busy:
        case MarkOfficialSkip.noSubmission:
          break;
      }
    }
    return lines;
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
  Widget build(BuildContext context) => ReloadOnSync.contest(
    contestId: widget.contestId,
    onSynced: () => unawaited(_controller?.refreshAfterSync()),
    child: _scaffold(context),
  );

  Widget _scaffold(BuildContext context) {
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
                    onMarkAll: _markAll,
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
                      onRetry: c.syncRefreshFailed
                          ? () => unawaited(c.refreshAfterSync())
                          : c.refresh,
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
                              return _table(
                                c,
                                rows,
                                mode,
                                MediumColumns.of(box.maxWidth),
                              );
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

  /// One rounded table: the heading (wide and medium) and a row per pilot.
  Widget _table(
    ScoringController c,
    List<ScoringRow> rows,
    ScoreGridMode mode,
    MediumColumns medium,
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
          if (mode != ScoreGridMode.compact)
            ScoreGridHeader(
              mode: mode,
              medium: medium,
              options: c.data!.gridOptions,
            ),
          Expanded(
            child: ListView(
              children: [for (final row in rows) _tile(c, row, mode, medium)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    ScoringController c,
    ScoringRow row,
    ScoreGridMode mode,
    MediumColumns medium,
  ) {
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
      medium: medium,
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
      markSkip: row.isAutomaticUnconfirmed
          ? c.confirmAutomaticSkip(row)
          : c.markOfficialSkip(row),
      focusField: _focusRow == row.id.value ? _focusField : null,
      actions: ScoreRowActions(
        onActivate: () => c.activate(row.id),
        onSave: () => _save(row),
        onMarkOfficial: () => _markOfficial(row),
        onRetryPromotion: () => _markOfficial(row, retry: true),
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
