import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_client_provider.dart';
import '../../router.dart';
import '../../services/scoring/row_save.dart';
import '../../services/scoring/score_check.dart';
import '../../services/scoring/score_preview.dart';
import '../../services/scoring/scoring_controller.dart';
import '../../services/scoring/scoring_row.dart';
import '../../widgets/api_error_text.dart';
import '../../widgets/message_view.dart';
import '../../widgets/scoring/score_check_panel.dart';
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
    widget.guard?.attach(_confirmLeave);
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
    if (mounted) setState(() {});
  }

  /// Asks what to do with unsaved rows. True when the caller may go on.
  Future<bool> _resolveUnsaved() async {
    final c = _controller!;
    if (!c.hasUnsaved) return true;
    final choice = await askUnsavedEdits(context, rows: c.dirtyCount);
    switch (choice) {
      case UnsavedChoice.stay:
        return false;
      case UnsavedChoice.discard:
        c.discardAll();
        return true;
      case UnsavedChoice.save:
        await c.saveAll();
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
    final ok = await c.save(row);
    if (!ok || !mounted) return;
    final rows = c.rows;
    final at = rows.indexWhere((r) => r.id == row.id);
    if (at >= 0 && at < rows.length - 1) {
      c.activate(rows[at + 1].id);
    }
  }

  Future<void> _saveAll() async {
    final saved = await _controller!.saveAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved $saved ${saved == 1 ? 'row' : 'rows'}.')),
    );
  }

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
      appBar: AppBar(title: const Text('Scoring')),
      body: c == null
          ? const MessageView(text: 'No API client is available.')
          : _body(c),
    );
  }

  Widget _body(ScoringController c) {
    if (c.data == null) {
      if (c.loadError != null) {
        return MessageView(
          text: 'The scores could not be loaded.',
          detail: apiErrorText(c.loadError!),
          onRetry: c.load,
        );
      }
      return const Center(
        key: ValueKey('scoring-loading'),
        child: CircularProgressIndicator(),
      );
    }
    final data = c.data!;
    if (data.matrix.isEmpty) {
      return MessageView(
        text: 'This contest has no matrix yet.',
        detail: 'Draw the matrix first. Then scores can be entered here.',
        action: FilledButton(
          key: const ValueKey('scoring-open-matrix'),
          onPressed: () => context.go(contestMatrixPath(widget.contestId)),
          child: const Text('Open the matrix'),
        ),
      );
    }
    final rows = c.rows;
    final check = c.check;
    return Column(
      children: [
        ScoringToolbar(controller: c, onOpen: _go, onSaveAll: _saveAll),
        ScoringContextStrip(controller: c),
        if (c.recalculationWarning != null)
          MaterialBanner(
            key: const ValueKey('scoring-recalculation-warning'),
            content: Text(c.recalculationWarning!),
            leading: const Icon(Icons.warning_amber),
            actions: [
              TextButton(onPressed: c.refresh, child: const Text('Refresh')),
            ],
          ),
        if (c.loadError != null)
          MaterialBanner(
            content: Text(apiErrorText(c.loadError!)),
            leading: const Icon(Icons.error_outline),
            actions: [
              TextButton(onPressed: c.refresh, child: const Text('Retry')),
            ],
          ),
        Expanded(
          child: rows.isEmpty
              ? const MessageView(
                  key: ValueKey('scoring-empty-group'),
                  text: 'No pilots in this group.',
                  detail: 'Every pilot assigned here is absent or retired.',
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24, top: 4),
                  children: [
                    if (check != null)
                      ScoreCheckPanel(
                        result: check,
                        onJump: _jump,
                        onClose: c.clearCheck,
                      ),
                    for (final row in rows) _tile(c, row),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _tile(ScoringController c, ScoringRow row) {
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
      focusField: _focusRow == row.id.value ? _focusField : null,
      actions: ScoreRowActions(
        onActivate: () => c.activate(row.id),
        onSave: () => _save(row),
        onRevert: () => c.revert(row),
        onKeepMine: () => c.keepMine(row),
        onTakeTheirs: () => c.takeTheirs(row),
        onRefresh: c.refresh,
      ),
    );
  }
}
