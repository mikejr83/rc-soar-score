import 'package:flutter/material.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/matrix/draw_form_check.dart';
import '../../services/matrix/matrix_pilot.dart';
import '../../services/matrix/move_plan.dart';
import '../api_error_text.dart';
import 'matrix_colors.dart';

/// What the move dialog ended with.
sealed class MoveOutcome {
  const MoveOutcome();
}

/// The server moved the pilot; [matrix] is the matrix after the move.
class PilotMoved extends MoveOutcome {
  const PilotMoved(this.matrix);

  final CurrentMatrix matrix;
}

/// The matrix or the contest changed under the dialog: reload the page.
class MoveNeedsReload extends MoveOutcome {
  const MoveNeedsReload();
}

/// Sends a move to the server.
typedef SendMove = Future<CurrentMatrix> Function(
  MoveAssignmentRequest request,
);

/// Asks the director where to move [pilot] and sends the move. Returns the
/// outcome, or `null` when the director cancelled.
Future<MoveOutcome?> showMovePilotDialog(
  BuildContext context, {
  required MovePlan plan,
  required MatrixPilot pilot,
  required Map<Id, MatrixPilot> pilots,
  required SendMove send,
}) => showDialog<MoveOutcome>(
  context: context,
  barrierDismissible: false,
  builder: (context) =>
      MovePilotDialog(plan: plan, pilot: pilot, pilots: pilots, send: send),
);

/// The refusals of a move that mean the matrix or the contest changed since
/// the page loaded: the director reloads.
const _changedCodes = {
  'stale_matrix',
  'round_locked',
  'group_locked',
  'score_locked',
  'matrix_not_editable',
  'contest_locked',
  'no_matrix',
  'assignment_superseded',
  'round_not_current',
};

/// The dialog that moves a pilot to another group, lane or round. Groups are
/// marked recommended or not ideal; the ones that cannot be chosen say why. A
/// refused move keeps the dialog open with what was entered.
class MovePilotDialog extends StatefulWidget {
  const MovePilotDialog({
    super.key,
    required this.plan,
    required this.pilot,
    required this.pilots,
    required this.send,
  });

  final MovePlan plan;
  final MatrixPilot pilot;
  final Map<Id, MatrixPilot> pilots;
  final SendMove send;

  @override
  State<MovePilotDialog> createState() => _MovePilotDialogState();
}

class _MovePilotDialogState extends State<MovePilotDialog> {
  final _reason = TextEditingController();
  late Round _round = widget.plan.sourceRound;
  MoveTarget? _target;
  int? _lane;
  bool _submitted = false;
  bool _busy = false;
  bool _changed = false;
  String? _failure;

  /// The id of the move being sent. Repeating a request with the same id and
  /// values changes nothing more, so a retry cannot move twice.
  Id? _requestId;
  String? _requestKey;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _hasLanes => widget.plan.source.lane != null;

  Id _idFor(String key) {
    if (_requestKey != key || _requestId == null) {
      _requestKey = key;
      _requestId = Id.create();
    }
    return _requestId!;
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _failure = null;
    });
    final target = _target;
    final reason = _reason.text.trim();
    if (target == null ||
        reason.isEmpty ||
        (_hasLanes && _lane == null) ||
        _busy) {
      return;
    }
    final key = '${target.round.id.value}/${target.group}/$_lane/$reason';
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      final matrix = await widget.send(
        MoveAssignmentRequest(
          id: _idFor(key),
          scheduledRoundId: target.round.id,
          group: target.group,
          lane: _hasLanes ? _lane : null,
          reason: reason,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(PilotMoved(matrix));
      }
    } on ApiNetworkError {
      if (mounted) {
        setState(() {
          _busy = false;
          _failure = l10n.matrixMoveNetwork;
        });
      }
    } on ApiHttpError catch (error) {
      if (mounted) {
        final changed =
            error.statusCode == 409 &&
            _changedCodes.contains(error.error?.code);
        setState(() {
          _busy = false;
          _changed = changed;
          _failure = changed ? l10n.matrixMoveChanged : apiErrorText(error);
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failure = apiErrorText(error);
        });
      }
    }
  }

  String _blockText(AppLocalizations l10n, MoveTarget target) =>
      switch (target.block!) {
        MoveBlockKind.currentGroup => l10n.matrixMoveBlockCurrent,
        MoveBlockKind.alreadyInGroup => l10n.matrixMoveBlockAlready(
          target.round.ordinal,
        ),
        MoveBlockKind.groupLocked => l10n.matrixMoveBlockGroupLocked,
        MoveBlockKind.roundLocked => l10n.matrixMoveBlockRoundLocked,
        MoveBlockKind.teamProtection => l10n.matrixMoveBlockTeam,
      };

  String _notIdealText(AppLocalizations l10n, NotIdealReason reason) =>
      switch (reason) {
        NotIdealReason.hasScores => l10n.matrixMoveReasonHasScores,
        NotIdealReason.roundCompleted => l10n.matrixMoveReasonRoundCompleted,
        NotIdealReason.teammate => l10n.matrixMoveReasonTeammate,
      };

  Widget _banner(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String text,
    required bool error,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: key,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: error ? scheme.errorContainer : scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Icon(
              icon,
              size: 20,
              color: error
                  ? scheme.onErrorContainer
                  : scheme.onTertiaryContainer,
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: error
                      ? scheme.onErrorContainer
                      : scheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groupTile(
    BuildContext context,
    AppLocalizations l10n,
    MoveTarget target,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final colors = MatrixColors.of(context);
    final letter = DrawFormCheck.groupLetter(target.group - 1);
    final selected =
        _target?.round.id == target.round.id && _target?.group == target.group;
    final sourceBlocked = widget.plan.sourceBlock != null;
    final enabled = target.allowed && !sourceBlocked && !_busy;
    final List<String> lines = target.allowed
        ? [for (final reason in target.notIdeal) _notIdealText(l10n, reason)]
        : [_blockText(l10n, target)];
    final mark = !target.allowed
        ? null
        : target.recommended
        ? (Icons.thumb_up_outlined, l10n.matrixMoveRecommended, scheme.primary)
        : (Icons.warning_amber, l10n.matrixMoveNotIdeal, colors.warn);
    return Semantics(
      selected: selected,
      child: ListTile(
        key: ValueKey('move-group-$letter'),
        enabled: enabled,
        selected: selected,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: selected
              ? BorderSide(color: scheme.primary, width: 2)
              : BorderSide.none,
        ),
        leading: Icon(
          !target.allowed
              ? Icons.block
              : selected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
        ),
        title: Row(
          spacing: 8,
          children: [
            Text(l10n.matrixMoveGroupLabel(letter)),
            if (mark != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Icon(mark.$1, size: 16, color: mark.$3),
                  Text(
                    mark.$2,
                    key: ValueKey('move-mark-$letter'),
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: mark.$3, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
          ],
        ),
        subtitle: lines.isEmpty
            ? null
            : Text(lines.join(' '), key: ValueKey('move-note-$letter')),
        onTap: enabled
            ? () => setState(() {
                _target = target;
                _lane = null;
              })
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plan = widget.plan;
    final source = plan.source;
    final from = DrawFormCheck.groupLetter(source.group - 1);
    final sourceBlock = plan.sourceBlock;
    final target = _target;
    final lanes = target == null ? const <LaneOption>[] : plan.lanesOf(target);
    return AlertDialog(
      title: Text(l10n.matrixMoveTitle(widget.pilot.name)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                source.lane == null
                    ? l10n.matrixMoveFrom(plan.sourceRound.ordinal, from)
                    : l10n.matrixMoveFromLane(
                        plan.sourceRound.ordinal,
                        from,
                        source.lane!,
                      ),
              ),
              if (plan.scored)
                _banner(
                  context,
                  key: const ValueKey('move-score-warning'),
                  icon: Icons.warning_amber,
                  text: l10n.matrixMoveScoredWarning,
                  error: true,
                ),
              if (sourceBlock != null)
                _banner(
                  context,
                  key: const ValueKey('move-source-block'),
                  icon: Icons.lock_outline,
                  text: switch (sourceBlock) {
                    SourceBlockKind.groupLocked =>
                      l10n.matrixMoveSourceGroupLocked,
                    SourceBlockKind.scoreLocked =>
                      l10n.matrixMoveSourceScoreLocked,
                  },
                  error: false,
                ),
              DropdownButtonFormField<int>(
                key: const ValueKey('move-round'),
                initialValue: _round.ordinal,
                decoration: InputDecoration(
                  labelText: l10n.matrixMoveRound,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final round in plan.rounds)
                    DropdownMenuItem(
                      value: round.ordinal,
                      child: Text(l10n.matrixMoveRoundOption(round.ordinal)),
                    ),
                ],
                onChanged: _busy
                    ? null
                    : (ordinal) => setState(() {
                        _round = plan.rounds.firstWhere(
                          (round) => round.ordinal == ordinal,
                        );
                        _target = null;
                        _lane = null;
                      }),
              ),
              Text(
                l10n.matrixMoveGroupHeading,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in plan.groupsOf(_round))
                    _groupTile(context, l10n, group),
                ],
              ),
              if (_submitted && target == null)
                Text(
                  l10n.matrixMoveGroupRequired,
                  key: const ValueKey('move-group-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_hasLanes && target != null)
                DropdownButtonFormField<int>(
                  // A new target starts a new field, so the lane is empty.
                  key: ValueKey(
                    'move-lane-${target.round.id.value}-${target.group}',
                  ),
                  initialValue: _lane,
                  decoration: InputDecoration(
                    labelText: l10n.matrixMoveLane,
                    border: const OutlineInputBorder(),
                    errorText: _submitted && _lane == null
                        ? l10n.matrixMoveLaneRequired
                        : null,
                  ),
                  items: [
                    for (final option in lanes)
                      DropdownMenuItem(
                        value: option.lane,
                        enabled: option.takenBy == null,
                        child: Text(
                          option.takenBy == null
                              ? l10n.matrixMoveLaneFree(option.lane)
                              : l10n.matrixMoveLaneTaken(
                                  option.lane,
                                  widget.pilots[option.takenBy]?.name ?? '',
                                ),
                        ),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (lane) => setState(() => _lane = lane),
                ),
              TextField(
                key: const ValueKey('move-reason'),
                controller: _reason,
                enabled: !_busy,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.matrixMoveReasonLabel,
                  helperText: l10n.matrixMoveReasonHelp,
                  border: const OutlineInputBorder(),
                  errorText: _submitted && _reason.text.trim().isEmpty
                      ? l10n.matrixMoveReasonRequired
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_failure != null)
                _banner(
                  context,
                  key: const ValueKey('move-error'),
                  icon: Icons.error_outline,
                  text: _failure!,
                  error: true,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('move-cancel'),
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.matrixMoveCancel),
        ),
        if (_changed)
          FilledButton(
            key: const ValueKey('move-reload'),
            onPressed: () => Navigator.of(context).pop(const MoveNeedsReload()),
            child: Text(l10n.matrixMoveReload),
          )
        else
          FilledButton(
            key: const ValueKey('move-confirm'),
            style: plan.scored
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: _busy || sourceBlock != null ? null : _submit,
            child: Text(
              _busy
                  ? l10n.matrixMoveWorking
                  : plan.scored
                  ? l10n.matrixMoveConfirmDiscard
                  : l10n.matrixMoveConfirm,
            ),
          ),
      ],
    );
  }
}
