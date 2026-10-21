import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/scoring/row_save.dart';
import '../../services/scoring/score_check.dart';
import '../../services/scoring/score_row_draft.dart';
import '../../services/scoring/scoring_page_data.dart';
import '../../services/scoring/scoring_row.dart';
import '../../services/scoring/time_entry.dart';
import '../matrix/matrix_colors.dart';
import '../matrix/team_badge.dart';
import 'score_entry_panel.dart';
import 'focus_step.dart';
import '../../services/scoring/score_grid_options.dart';
import 'score_grid_columns.dart';
import 'status_chips.dart';

/// What a row's buttons do; the page owns the controller, the row only asks.
class ScoreRowActions {
  const ScoreRowActions({
    required this.onActivate,
    required this.onSave,
    required this.onRevert,
    required this.onKeepMine,
    required this.onTakeTheirs,
    required this.onRefresh,
    required this.onHistory,
    required this.onRetire,
    required this.onReinstate,
  });

  final VoidCallback onActivate;
  final VoidCallback onSave;
  final VoidCallback onRevert;
  final VoidCallback onKeepMine;
  final VoidCallback onTakeTheirs;
  final VoidCallback onRefresh;

  /// Opens the score history of the row.
  final VoidCallback onHistory;

  /// Retires the pilot from this round on, after asking.
  final VoidCallback onRetire;

  /// Takes a retirement back, after asking.
  final VoidCallback onReinstate;
}

/// One pilot of the group: a grid row under the table heading. Time and
/// height stay in the row so the quick path never leaves the line; the
/// active row opens a band below with the landing, toggles and penalties.
class ScoreRowTile extends StatefulWidget {
  const ScoreRowTile({
    super.key,
    required this.row,
    required this.draft,
    required this.save,
    required this.active,
    required this.block,
    required this.landings,
    required this.landingTableName,
    required this.preview,
    required this.heightPenalty,
    required this.findings,
    required this.actions,
    required this.mode,
    required this.grid,
    this.focusOrder = false,
    this.theirs,
    this.focusField,
    this.retireBlocked,
  });

  final ScoringRow row;
  final ScoreRowDraft draft;
  final RowSave save;
  final bool active;
  final EntryBlock? block;
  final List<LandingResult> landings;
  final String? landingTableName;

  /// The raw score of the typed values, or null.
  final double? preview;

  /// The height penalty of the typed launch height, or null.
  final double? heightPenalty;
  final List<ScoreFinding> findings;
  final ScoreRowActions actions;
  final ScoreGridMode mode;

  /// Whether the grid shows a lane or number column and teams.
  final ScoreGridOptions grid;

  /// Draws the keyboard path numbers over the controls.
  final bool focusOrder;

  /// What another revision saved, for a stale row.
  final Map<String, Object?>? theirs;

  /// A field to put the cursor in, set by a Score check finding.
  final String? focusField;

  /// Why the pilot cannot be retired or reinstated now, or null.
  final String? retireBlocked;

  @override
  State<ScoreRowTile> createState() => _ScoreRowTileState();
}

class _ScoreRowTileState extends State<ScoreRowTile> {
  late final TextEditingController _time;
  late final TextEditingController _height;
  late final TextEditingController _penalty;
  late final TextEditingController _cumulative;
  final _timeNode = FocusNode();
  final _heightNode = FocusNode();
  final _landingNode = FocusNode();
  final _penaltyNode = FocusNode();
  final _cumulativeNode = FocusNode();

  /// The launch height is checked only once the director has touched it.
  bool _heightTouched = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    _time = TextEditingController(text: draft.timeText);
    _height = TextEditingController(text: draft.heightText);
    _penalty = TextEditingController(text: draft.penaltyText);
    _cumulative = TextEditingController(text: draft.cumulativePenaltyText);
    draft.addListener(_onDraft);
    _timeNode.addListener(_onTimeFocus);
    _heightNode.addListener(_onHeightFocus);
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
    for (final c in [_time, _height, _penalty, _cumulative]) {
      c.dispose();
    }
    _timeNode.removeListener(_onTimeFocus);
    _heightNode.removeListener(_onHeightFocus);
    for (final n in [
      _timeNode,
      _heightNode,
      _landingNode,
      _penaltyNode,
      _cumulativeNode,
    ]) {
      n.dispose();
    }
    super.dispose();
  }

  /// Leaving the time field shows a valid time as m:ss.
  void _onTimeFocus() {
    if (_timeNode.hasFocus) return;
    final t = widget.draft.time;
    if (t.isValid && t.display != null && t.display != widget.draft.timeText) {
      widget.draft.setTime(t.display!);
    }
  }

  void _onHeightFocus() {
    if (!_heightNode.hasFocus && !_heightTouched && mounted) {
      setState(() => _heightTouched = true);
    }
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
    if (_cumulative.text != d.cumulativePenaltyText) {
      _cumulative.text = d.cumulativePenaltyText;
    }
  }

  void _focusFirst() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.block != null) return;
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
        case 'cumulative_penalty':
          _cumulativeNode.requestFocus();
        default:
          _timeNode.requestFocus();
      }
    });
  }

  String _k(String name) => 'score-$name-${widget.row.id.value}';

  bool get _readOnly =>
      widget.block != null || widget.row.isLocked || widget.row.retired;

  // Cells.

  Widget _label(
    BuildContext context,
    String text,
    bool on, [
    TextAlign align = TextAlign.start,
  ]) => on
      ? Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            text,
            textAlign: align,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        )
      : const SizedBox.shrink();

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _caption(BuildContext context, String? text, {bool error = false}) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 32,
      child: text == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.error,
                        size: 14,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: error
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(
    BuildContext context, {
    required Key key,
    required TextEditingController controller,
    required FocusNode node,
    required bool enabled,
    required TextInputType type,
    required List<TextInputFormatter> formatters,
    required ValueChanged<String> onChanged,
    required ValueChanged<String> onSubmitted,
    required bool invalid,
    String? suffix,
    required double order,
    required String badge,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final field = TextField(
      key: key,
      controller: controller,
      focusNode: node,
      enabled: enabled,
      keyboardType: type,
      textInputAction: TextInputAction.next,
      inputFormatters: formatters,
      onTap: widget.actions.onActivate,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        isDense: true,
        filled: !enabled,
        fillColor: scheme.onSurface.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 14,
        ),
        suffixText: suffix,
        border: _border(invalid ? scheme.error : scheme.outline),
        enabledBorder: _border(
          invalid ? scheme.error : scheme.outline,
          invalid ? 2 : 1,
        ),
        disabledBorder: _border(Colors.transparent),
        focusedBorder: _border(scheme.primary, 3),
      ),
    );
    return FocusStep(
      order: order,
      badge: widget.focusOrder ? badge : null,
      enterPath: true,
      child: field,
    );
  }

  Widget _timeCell(BuildContext context, bool labels, bool editable) {
    final d = widget.draft;
    final off = d.measurementsOffReason;
    final t = d.time;
    final missing = d.problems
        .where((p) => p.field == 'time_flown' && t.error == null)
        .map((p) => p.message)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _label(context, 'Time flown (m:ss)', labels),
        _field(
          context,
          key: ValueKey(_k('time')),
          controller: _time,
          node: _timeNode,
          enabled: editable && off == null,
          type: const TextInputType.numberWithOptions(decimal: true),
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,:]'))],
          onChanged: d.setTime,
          onSubmitted: (_) => _heightNode.requestFocus(),
          invalid: t.error != null || missing != null,
          order: 1,
          badge: '1↵',
        ),
        _caption(
          context,
          off != null
              ? 'Scores 0'
              : (t.error != null
                    ? TimeEntry.outOfRange
                    : (missing ?? t.display)),
          error: (t.error != null || missing != null) && off == null,
        ),
      ],
    );
  }

  Widget _heightCell(BuildContext context, bool labels, bool editable) {
    final d = widget.draft;
    final off = d.measurementsOffReason;
    final problem = d.problems
        .where((p) => p.field == 'launch_height')
        .map((p) => p.message)
        .firstOrNull;
    // Nothing is checked until the field has been touched. Then an empty
    // field is Required, and a typed value is checked.
    final touched = _heightTouched || d.heightText.trim().isNotEmpty;
    final String? shown;
    if (!touched || d.zeroing) {
      shown = null;
    } else if (d.heightText.trim().isEmpty) {
      shown = 'Required';
    } else if (problem != null && !d.heightZero) {
      shown = problem;
    } else {
      shown = null;
    }
    final penalty = widget.heightPenalty;
    final note = shown == null && penalty != null && problem == null
        ? '${_points(penalty)} pts'
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _label(context, 'Launch height (m)', labels),
        _field(
          context,
          key: ValueKey(_k('height')),
          controller: _height,
          node: _heightNode,
          enabled: editable && off == null,
          type: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: d.setHeight,
          onSubmitted: (_) =>
              (d.landingOffReason == null ? _landingNode : _penaltyNode)
                  .requestFocus(),
          invalid: shown != null,
          suffix: 'm',
          order: 2,
          badge: '2↵',
        ),
        _caption(
          context,
          off != null ? 'Scores 0' : (shown ?? note),
          error: shown != null && off == null,
        ),
      ],
    );
  }

  /// 250 as "250", 62.5 as "62.5".
  static String _points(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  Widget _landingCell(BuildContext context, bool labels) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final d = widget.draft;
    var text = '–';
    IconData? icon;
    if (d.measurementsOffReason != null) {
      text = 'Scores 0';
      icon = Icons.block;
    } else if (d.lateLanding) {
      text = 'No landing bonus';
      icon = Icons.block;
    } else if (d.landing != null) {
      for (final l in widget.landings) {
        if (l.entryKey == d.landing) text = l.displayValue;
      }
    }
    final flags = <(IconData, String)>[
      if (d.lateLanding) (Icons.timer_off, 'Late landing'),
      if (d.motorRestart) (Icons.settings, 'Motor restart'),
      if (d.outOfBounds) (Icons.wrong_location, 'Out of bounds'),
      if (d.noAltitude) (Icons.height, 'No altitude'),
    ];
    // A value is right aligned; "–" is centered.
    final hasValue = text != '–';
    final cross = hasValue ? CrossAxisAlignment.end : CrossAxisAlignment.center;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: cross,
        children: [
          _label(
            context,
            'Landing · flags',
            labels,
            hasValue ? TextAlign.end : TextAlign.center,
          ),
          Row(
            mainAxisAlignment: hasValue
                ? MainAxisAlignment.end
                : MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  text,
                  textAlign: hasValue ? TextAlign.end : TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          for (final (flagIcon, flagText) in flags)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: StatusChip(icon: flagIcon, label: flagText, dense: true),
            ),
        ],
      ),
    );
  }

  Widget _numberCell(
    BuildContext context,
    String label,
    bool labels,
    String value,
    bool dirty,
  ) {
    final theme = Theme.of(context);
    // A value is right aligned; "–" is centered.
    final hasValue = value != '–';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: hasValue
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.center,
        children: [
          _label(
            context,
            label,
            labels,
            hasValue ? TextAlign.end : TextAlign.center,
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: dirty ? theme.colorScheme.onSurfaceVariant : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _penaltyCell(BuildContext context, bool labels) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final d = widget.draft;
    final flight = d.penalty ?? 0;
    final cumulative = d.cumulativePenalty;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _label(context, 'Penalties', labels, TextAlign.center),
          if (flight > 0)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.remove,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text('$flight flight', style: theme.textTheme.bodyMedium),
                ],
              ),
            )
          else if (cumulative == null)
            Text('None', textAlign: TextAlign.center, style: muted),
          // A removal keeps its row: the value was applied earlier.
          if (cumulative == 0)
            Text('Removed', textAlign: TextAlign.center, style: muted),
          if (cumulative != null && cumulative > 0)
            Padding(
              padding: EdgeInsets.only(top: flight > 0 ? 4 : 0),
              // The cell is 108 px; scale the line down in the roomiest
              // test font instead of overflowing.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.push_pin_outlined,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$cumulative total',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _indicatorCell(BuildContext context, bool labels) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(context, 'Indicators', labels),
          if (widget.row.hasSubmission)
            const Tooltip(
              message:
                  'A pilot or helper submitted values. The submission is '
                  'kept in history.',
              child: StatusChip(
                icon: Icons.smartphone,
                label: 'Pilot entry',
                dense: true,
              ),
            )
          else
            Text(
              '–',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusCell(BuildContext context, bool labels, bool dirty) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = MatrixColors.of(context);
    final subs = <(IconData, String, Color?)>[
      if (dirty) (Icons.edit_note, 'Not saved yet', null),
      if (widget.findings.isNotEmpty)
        (Icons.help_outline, 'Check: ${widget.findings.length}', colors.warn),
      if (widget.row.isLocked && widget.block != null)
        (Icons.lock, widget.block!.message, null),
      if (widget.row.retired)
        (
          Icons.person_off_outlined,
          'Retired from round ${widget.row.pilot.retiredAtRound}',
          null,
        ),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(context, 'Status', labels),
          RowStatusChip(status: widget.row.status, unsaved: dirty),
          for (final (icon, text, color) in subs)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 14, color: color ?? scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      text,
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _menuCell(BuildContext context) {
    final row = widget.row;
    final retired = row.retired;
    final blocked = widget.retireBlocked;
    final round = row.pilot.retiredAtRound;
    return FocusStep(
      order: 12,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: PopupMenuButton<String>(
          key: ValueKey('row-menu-${row.id.value}'),
          tooltip: 'More for ${row.pilot.name}',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => switch (value) {
            'history' => widget.actions.onHistory(),
            'retire' => widget.actions.onRetire(),
            'reinstate' => widget.actions.onReinstate(),
            _ => null,
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              key: ValueKey('menu-history'),
              value: 'history',
              child: Text('Score history'),
            ),
            if (round == null || !retired)
              PopupMenuItem<String>(
                key: const ValueKey('menu-retire'),
                value: 'retire',
                enabled: blocked == null,
                child: Text(blocked ?? 'Retire pilot from this round on'),
              )
            else
              PopupMenuItem<String>(
                key: const ValueKey('menu-reinstate'),
                value: 'reinstate',
                enabled: blocked == null,
                child: Text(
                  blocked ?? 'Reinstate pilot (retired from round $round)',
                ),
              ),
            const PopupMenuItem<String>(
              enabled: false,
              child: Text('Correct a locked score · Later release'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _laneCell(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 36),
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: widget.active ? scheme.primary : null,
              border: Border.all(color: scheme.primary, width: 1.5),
            ),
            child: Text(
              '${(widget.grid.showsLanes ? widget.row.lane : widget.row.pilot.number) ?? ''}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: widget.active ? scheme.onPrimary : scheme.primary,
              ),
            ),
          ),
          if (widget.active)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(Icons.edit, size: 18, color: scheme.primary),
            ),
        ],
      ),
    );
  }

  Widget _pilotCell(BuildContext context) {
    final theme = Theme.of(context);
    final row = widget.row;
    final sub = [
      if (widget.grid.showTeams && row.team != null) row.team!.name,
      if (row.pilot.number != null && widget.grid.idLabel != 'No.')
        'No. ${row.pilot.number}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.grid.showTeams) ...[
            Tooltip(
              message: row.team?.name ?? 'No team',
              child: TeamBadge(marker: row.team),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.pilot.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: widget.active ? FontWeight.bold : null,
                  ),
                ),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Layout.

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = widget.draft;
    final dirty = d.isDirty;
    final saved = widget.row.result;
    final editable = !_readOnly && !widget.save.isBusy;
    final labels = widget.mode != ScoreGridMode.wide;
    final rawValue = dirty ? widget.preview : saved?.rawPoints;
    final groupValue = dirty ? null : saved?.groupScore;
    String number(double? v) => v == null ? '–' : v.toStringAsFixed(1);

    final lane = _laneCell(context);
    final pilot = _pilotCell(context);
    final time = _timeCell(context, labels, editable);
    final height = _heightCell(context, labels, editable);
    final land = _landingCell(context, labels);
    final raw = _numberCell(
      context,
      'Raw score',
      labels,
      number(rawValue),
      dirty,
    );
    final grp = _numberCell(
      context,
      'Group score',
      labels,
      number(groupValue),
      dirty,
    );
    final pen = _penaltyCell(context, labels);
    final ind = _indicatorCell(context, labels);
    final stat = _statusCell(context, labels, dirty);
    final menu = _menuCell(context);
    const gap = SizedBox(width: ScoreGridColumns.gap);
    const vgap = SizedBox(height: 4);

    final Widget grid = switch (widget.mode) {
      ScoreGridMode.wide => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.grid.showId) ...[
            SizedBox(width: ScoreGridColumns.lane, child: lane),
            gap,
          ],
          Expanded(child: pilot),
          gap,
          SizedBox(width: ScoreGridColumns.time, child: time),
          gap,
          SizedBox(width: ScoreGridColumns.height, child: height),
          gap,
          SizedBox(width: ScoreGridColumns.land, child: land),
          gap,
          SizedBox(width: ScoreGridColumns.raw, child: raw),
          gap,
          SizedBox(width: ScoreGridColumns.group, child: grp),
          gap,
          SizedBox(width: ScoreGridColumns.pen, child: pen),
          gap,
          SizedBox(width: ScoreGridColumns.ind, child: ind),
          gap,
          SizedBox(width: ScoreGridColumns.stat, child: stat),
          gap,
          SizedBox(width: ScoreGridColumns.menu, child: menu),
        ],
      ),
      ScoreGridMode.medium => Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.grid.showId) ...[
                SizedBox(width: 44, child: lane),
                gap,
              ],
              Expanded(flex: 2, child: pilot),
              gap,
              Expanded(flex: 2, child: stat),
              gap,
              SizedBox(width: 44, child: menu),
            ],
          ),
          vgap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.grid.showId) ...[const SizedBox(width: 44), gap],
              Expanded(child: time),
              gap,
              Expanded(child: height),
              gap,
              Expanded(flex: 2, child: land),
              gap,
              const SizedBox(width: 44),
            ],
          ),
          vgap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.grid.showId) ...[const SizedBox(width: 44), gap],
              Expanded(child: raw),
              gap,
              Expanded(child: grp),
              gap,
              Expanded(child: pen),
              gap,
              Expanded(child: ind),
              gap,
              const SizedBox(width: 44),
            ],
          ),
        ],
      ),
      ScoreGridMode.compact => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.grid.showId) ...[
                SizedBox(width: 40, child: lane),
                gap,
              ],
              Expanded(child: pilot),
              SizedBox(width: 44, child: menu),
            ],
          ),
          stat,
          vgap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: time),
              gap,
              Expanded(child: height),
            ],
          ),
          land,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: raw),
              gap,
              Expanded(child: grp),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: pen),
              gap,
              Expanded(child: ind),
            ],
          ),
        ],
      ),
    };

    final active = widget.active;
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Semantics(
        container: true,
        label: '${widget.row.pilot.name}, ${_statusWord(dirty)}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.actions.onActivate,
          child: Container(
            key: ValueKey('score-row-${widget.row.id.value}'),
            padding: const EdgeInsets.symmetric(
              horizontal: ScoreGridColumns.rowPadding,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              // The whole row, band included, is the highlighted block.
              color: active
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF14283A)
                        : const Color(0xFFE4EFF8))
                  : null,
              border: active
                  ? Border.symmetric(
                      horizontal: BorderSide(color: scheme.primary, width: 2),
                    )
                  : Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Column(
              children: [
                grid,
                if (active)
                  ScoreEntryPanel(
                    row: widget.row,
                    draft: d,
                    save: widget.save,
                    block: widget.block,
                    landings: widget.landings,
                    landingTableName: widget.landingTableName,
                    theirs: widget.theirs,
                    findings: widget.findings,
                    actions: widget.actions,
                    penaltyController: _penalty,
                    penaltyNode: _penaltyNode,
                    landingNode: _landingNode,
                    cumulativePenaltyController: _cumulative,
                    cumulativePenaltyNode: _cumulativeNode,
                    readOnly: _readOnly,
                    keyOf: _k,
                    focusOrder: widget.focusOrder,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusWord(bool dirty) {
    if (dirty) return 'unsaved changes';
    return switch (widget.row.status) {
      RowStatus.notEntered => 'not entered',
      RowStatus.submitted => 'submitted by a participant',
      RowStatus.official => 'official',
      RowStatus.locked => 'locked',
      RowStatus.retired => 'retired',
    };
  }
}
