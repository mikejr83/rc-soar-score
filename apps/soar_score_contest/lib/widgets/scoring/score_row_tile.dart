import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/scoring/row_save.dart';
import '../../services/scoring/score_check.dart';
import '../../services/scoring/score_row_draft.dart';
import '../../services/scoring/scoring_page_data.dart';
import '../../services/scoring/scoring_row.dart';
import '../matrix/matrix_colors.dart';
import 'score_entry_panel.dart';
import 'status_chips.dart';
import 'team_chip.dart';

/// What a row's buttons do; the page owns the controller, the row only asks.
class ScoreRowActions {
  const ScoreRowActions({
    required this.onActivate,
    required this.onSave,
    required this.onRevert,
    required this.onKeepMine,
    required this.onTakeTheirs,
    required this.onRefresh,
  });

  final VoidCallback onActivate;
  final VoidCallback onSave;
  final VoidCallback onRevert;
  final VoidCallback onKeepMine;
  final VoidCallback onTakeTheirs;
  final VoidCallback onRefresh;
}

/// One pilot of the group. The time and height stay in the row so the quick
/// path never leaves the line; the active row opens a panel below with the
/// landing, toggles and penalties.
class ScoreRowTile extends StatefulWidget {
  const ScoreRowTile({
    super.key,
    required this.row,
    required this.draft,
    required this.save,
    required this.active,
    required this.block,
    required this.landings,
    required this.preview,
    required this.findings,
    required this.actions,
    this.theirs,
    this.focusField,
  });

  final ScoringRow row;
  final ScoreRowDraft draft;
  final RowSave save;
  final bool active;
  final EntryBlock? block;
  final List<LandingResult> landings;

  /// The raw score of the typed values, or null.
  final double? preview;
  final List<ScoreFinding> findings;
  final ScoreRowActions actions;

  /// What another revision saved, for a stale row.
  final Map<String, Object?>? theirs;

  /// A field to put the cursor in, set by a Score check finding.
  final String? focusField;

  @override
  State<ScoreRowTile> createState() => _ScoreRowTileState();
}

class _ScoreRowTileState extends State<ScoreRowTile> {
  late final TextEditingController _time;
  late final TextEditingController _height;
  late final TextEditingController _penalty;
  final _timeNode = FocusNode();
  final _heightNode = FocusNode();
  final _landingNode = FocusNode();
  final _penaltyNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    _time = TextEditingController(text: draft.timeText);
    _height = TextEditingController(text: draft.heightText);
    _penalty = TextEditingController(text: draft.penaltyText);
    draft.addListener(_onDraft);
    if (widget.active) _focusFirst();
  }

  @override
  void didUpdateWidget(ScoreRowTile old) {
    super.didUpdateWidget(old);
    if (old.draft != widget.draft) {
      old.draft.removeListener(_onDraft);
      widget.draft.addListener(_onDraft);
      _sync();
    }
    if (!old.active && widget.active) _focusFirst();
    if (widget.focusField != null && widget.focusField != old.focusField) {
      _focusField(widget.focusField!);
    }
  }

  @override
  void dispose() {
    widget.draft.removeListener(_onDraft);
    for (final c in [_time, _height, _penalty]) {
      c.dispose();
    }
    for (final n in [_timeNode, _heightNode, _landingNode, _penaltyNode]) {
      n.dispose();
    }
    super.dispose();
  }

  void _onDraft() {
    _sync();
    if (mounted) setState(() {});
  }

  void _sync() {
    final d = widget.draft;
    if (_time.text != d.timeText) _time.text = d.timeText;
    if (_height.text != d.heightText) _height.text = d.heightText;
    if (_penalty.text != d.penaltyText) _penalty.text = d.penaltyText;
  }

  void _focusFirst() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.block != null) return;
      if (widget.draft.measurementsOffReason == null) {
        _timeNode.requestFocus();
      } else {
        _penaltyNode.requestFocus();
      }
    });
  }

  void _focusField(String field) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (field) {
        case 'launch_height':
          _heightNode.requestFocus();
        case 'flight_penalty':
          _penaltyNode.requestFocus();
        default:
          _timeNode.requestFocus();
      }
    });
  }

  String _k(String name) => 'score-$name-${widget.row.id.value}';

  bool get _readOnly => widget.block != null || widget.row.isLocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = MatrixColors.of(context);
    final draft = widget.draft;
    final row = widget.row;
    final dirty = draft.isDirty;
    final saved = row.result;
    final busy = widget.save.isBusy;
    final off = draft.measurementsOffReason;
    final editable = !_readOnly && !busy;

    final time = draft.time;
    final timeError = time.error;
    final heightProblem = draft.problems
        .where((p) => p.field == 'launch_height')
        .map((p) => p.message)
        .firstOrNull;

    final timeField = SizedBox(
      width: 150,
      child: TextField(
        key: ValueKey(_k('time')),
        controller: _time,
        focusNode: _timeNode,
        enabled: editable && off == null,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,:]')),
        ],
        onTap: widget.actions.onActivate,
        onChanged: draft.setTime,
        onSubmitted: (_) => _heightNode.requestFocus(),
        decoration: InputDecoration(
          labelText: 'Time',
          helperText: off != null
              ? 'Scores 0'
              : (time.display != null && timeError == null
                    ? time.display
                    : null),
          errorText: timeError,
          errorMaxLines: 3,
          border: const OutlineInputBorder(),
          isDense: false,
        ),
      ),
    );
    final heightField = SizedBox(
      width: 130,
      child: TextField(
        key: ValueKey(_k('height')),
        controller: _height,
        focusNode: _heightNode,
        enabled: editable && off == null,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onTap: widget.actions.onActivate,
        onChanged: draft.setHeight,
        onSubmitted: (_) =>
            (draft.landingOffReason == null ? _landingNode : _penaltyNode)
                .requestFocus(),
        decoration: InputDecoration(
          labelText: 'Height',
          suffixText: 'm',
          helperText: off != null ? 'Scores 0' : null,
          errorText: heightProblem != null && !draft.heightZero
              ? heightProblem
              : null,
          errorMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
      ),
    );

    String number(double? value) =>
        value == null ? '–' : value.toStringAsFixed(1);
    final rawValue = dirty ? widget.preview : saved?.rawPoints;
    final groupValue = dirty ? null : saved?.groupScore;
    Widget derived(
      String label,
      String value, {
      bool dim = false,
      String? note,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: dim ? scheme.onSurfaceVariant : null,
            fontStyle: dim ? FontStyle.italic : null,
          ),
        ),
        if (note != null) Text(note, style: theme.textTheme.labelSmall),
      ],
    );
    final rawBox = SizedBox(
      width: 110,
      child: derived(
        'Raw',
        number(rawValue),
        dim: dirty,
        note: dirty && widget.preview != null ? 'Preview, not saved' : null,
      ),
    );
    final groupBox = SizedBox(
      width: 80,
      child: derived('Group', number(groupValue), dim: dirty),
    );
    final penalty = draft.penalty ?? 0;
    final penaltyBox = SizedBox(
      width: 110,
      child: derived('Penalty', penalty > 0 ? '−$penalty this flight' : 'None'),
    );

    final badge = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.active ? scheme.primary : null,
        border: Border.all(color: scheme.primary, width: 2),
      ),
      child: Text(
        '${row.lane ?? row.pilot.number ?? ''}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: widget.active ? scheme.onPrimary : scheme.primary,
        ),
      ),
    );
    final name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          row.pilot.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: widget.active ? FontWeight.bold : null,
          ),
        ),
        if (row.team != null) TeamChip(marker: row.team!),
        if (row.hasSubmission)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox, size: 16),
              const SizedBox(width: 4),
              Text('Participant submission', style: theme.textTheme.labelSmall),
            ],
          ),
      ],
    );
    final status = Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (widget.findings.isNotEmpty)
          Tooltip(
            message: widget.findings.map((f) => f.message).join('\n'),
            child: StatusChip(
              icon: Icons.help_outline,
              label: 'Check',
              foreground: colors.warn,
            ),
          ),
        RowStatusChip(status: row.status, unsaved: dirty),
        PopupMenuButton<void>(
          tooltip: 'More for ${row.pilot.name}',
          itemBuilder: (context) => const [
            PopupMenuItem<void>(enabled: false, child: Text('Score history')),
            PopupMenuItem<void>(enabled: false, child: Text('Retire pilot')),
          ],
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        final header = wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  badge,
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: name),
                  timeField,
                  const SizedBox(width: 8),
                  heightField,
                  const SizedBox(width: 12),
                  rawBox,
                  groupBox,
                  penaltyBox,
                  const SizedBox(width: 8),
                  status,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      badge,
                      const SizedBox(width: 12),
                      Expanded(child: name),
                      status,
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: [timeField, heightField],
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [rawBox, groupBox, penaltyBox]),
                ],
              );
        return Semantics(
          container: true,
          label: '${row.pilot.name}, ${_statusWord(dirty)}',
          child: Card(
            key: ValueKey('score-row-${row.id.value}'),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: widget.active ? scheme.primary : scheme.outlineVariant,
                width: widget.active ? 2 : 1,
              ),
            ),
            color: widget.active
                ? Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.06),
                    scheme.surface,
                  )
                : null,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.actions.onActivate,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    if (widget.active)
                      ScoreEntryPanel(
                        row: row,
                        draft: draft,
                        save: widget.save,
                        block: widget.block,
                        landings: widget.landings,
                        theirs: widget.theirs,
                        findings: widget.findings,
                        actions: widget.actions,
                        penaltyController: _penalty,
                        penaltyNode: _penaltyNode,
                        landingNode: _landingNode,
                        readOnly: _readOnly,
                        keyOf: _k,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _statusWord(bool dirty) {
    if (dirty) return 'unsaved changes';
    return switch (widget.row.status) {
      RowStatus.notEntered => 'not entered',
      RowStatus.submitted => 'submitted by a participant',
      RowStatus.official => 'official',
      RowStatus.locked => 'locked',
    };
  }
}
