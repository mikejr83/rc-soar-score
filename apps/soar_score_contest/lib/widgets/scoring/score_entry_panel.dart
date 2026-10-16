import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/scoring/row_save.dart';
import '../../services/scoring/score_check.dart';
import '../../services/scoring/score_row_draft.dart';
import '../../services/scoring/scoring_page_data.dart';
import '../../services/scoring/scoring_row.dart';
import '../matrix/matrix_colors.dart';
import 'score_row_banners.dart';
import 'score_row_tile.dart';
import 'score_toggle_tile.dart';

/// The open part of the active row: landing choice, the four toggles, the
/// penalties, inline questions and messages, and Save row.
class ScoreEntryPanel extends StatelessWidget {
  const ScoreEntryPanel({
    super.key,
    required this.row,
    required this.draft,
    required this.save,
    required this.block,
    required this.landings,
    required this.theirs,
    required this.findings,
    required this.actions,
    required this.penaltyController,
    required this.penaltyNode,
    required this.landingNode,
    required this.readOnly,
    required this.keyOf,
  });

  final ScoringRow row;
  final ScoreRowDraft draft;
  final RowSave save;
  final EntryBlock? block;
  final List<LandingResult> landings;
  final Map<String, Object?>? theirs;
  final List<ScoreFinding> findings;
  final ScoreRowActions actions;
  final TextEditingController penaltyController;
  final FocusNode penaltyNode;
  final FocusNode landingNode;
  final bool readOnly;
  final String Function(String name) keyOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = MatrixColors.of(context);
    final busy = save.isBusy;
    final enabled = !readOnly && !busy;
    final settings = draft.settings;
    final problems = draft.problems;
    final canSave =
        enabled &&
        problems.isEmpty &&
        (draft.isDirty || !row.isScored) &&
        (!draft.needsZeroConfirmation || draft.zeroConfirmed);

    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text('Landing', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          _landing(context, enabled),
          const SizedBox(height: 14),
          Text('Flight status', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ScoreToggleTile(
                key: ValueKey(keyOf('late')),
                label: 'Late landing',
                value: draft.lateLanding,
                offReason: draft.lateLandingOffReason,
                note: 'Landing bonus is not given',
                enabled: enabled,
                onChanged: draft.setLateLanding,
              ),
              if (settings.restartsAllowed)
                ScoreToggleTile(
                  key: ValueKey(keyOf('restart')),
                  label: 'Motor restart',
                  value: draft.motorRestart,
                  offReason: draft.motorRestartOffReason,
                  note: settings.restartsNonDroppable
                      ? 'Scores 0, and the zero cannot be dropped'
                      : 'Scores 0',
                  enabled: enabled,
                  onChanged: draft.setMotorRestart,
                ),
              ScoreToggleTile(
                key: ValueKey(keyOf('oob')),
                label: 'Out of bounds',
                value: draft.outOfBounds,
                offReason: draft.outOfBoundsOffReason,
                note: 'Scores 0',
                enabled: enabled,
                onChanged: draft.setOutOfBounds,
              ),
              ScoreToggleTile(
                key: ValueKey(keyOf('noalt')),
                label: 'No altitude recorded',
                value: draft.noAltitude,
                offReason: draft.noAltitudeOffReason,
                note: 'Scores 0',
                enabled: enabled,
                onChanged: draft.setNoAltitude,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Penalties', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              SizedBox(
                width: 240,
                child: TextField(
                  key: ValueKey(keyOf('penalty')),
                  controller: penaltyController,
                  focusNode: penaltyNode,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: draft.setPenalty,
                  onSubmitted: (_) {
                    if (canSave) actions.onSave();
                  },
                  decoration: InputDecoration(
                    labelText: 'Flight penalty',
                    prefixIcon: const Icon(Icons.remove_circle_outline),
                    suffixText: 'points',
                    helperText: 'This flight. Dropped with the round.',
                    helperMaxLines: 2,
                    errorText: problems
                        .where((p) => p.field == 'flight_penalty')
                        .map((p) => p.message)
                        .firstOrNull,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(
                width: 240,
                child: TextField(
                  key: ValueKey('cumulative-penalty'),
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Cumulative penalty',
                    prefixIcon: Icon(Icons.push_pin_outlined),
                    helperText:
                        'Contest total, never dropped. Not available '
                        'yet: the score API does not store it.',
                    helperMaxLines: 3,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          if (draft.heightUnusual)
            ScoreInlineNote(
              icon: Icons.help_outline,
              color: colors.warn,
              text:
                  '${draft.height} m is a high launch. Is this correct? '
                  'You can still save.',
            ),
          if (draft.heightZero)
            ScoreInlineNote(
              icon: Icons.help_outline,
              color: colors.warn,
              text:
                  '0 m is not a launch height. Saving it as No altitude '
                  'recorded scores 0.',
              actionLabel: 'Turn on No altitude recorded',
              onAction: enabled ? () => draft.setNoAltitude(true) : null,
            ),
          for (final finding in findings)
            ScoreInlineNote(
              icon: Icons.fact_check_outlined,
              color: colors.warn,
              text: finding.message,
            ),
          if (draft.needsZeroConfirmation &&
              !readOnly &&
              (draft.isDirty || !row.isScored))
            _zeroConfirm(context, enabled),
          if (save.kind != RowSaveKind.idle && !busy)
            ScoreSaveBanner(
              save: save,
              theirs: theirs,
              mine: draft.components,
              onRetry: actions.onSave,
              onRefresh: actions.onRefresh,
              onKeepMine: actions.onKeepMine,
              onTakeTheirs: actions.onTakeTheirs,
            ),
          if (block != null)
            ScoreInlineNote(
              icon: Icons.lock_outline,
              color: theme.colorScheme.onSurfaceVariant,
              text: block!.message,
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                key: ValueKey(keyOf('save')),
                onPressed: canSave ? actions.onSave : null,
                icon: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(busy ? 'Saving…' : 'Save row'),
              ),
              TextButton(
                key: ValueKey(keyOf('revert')),
                onPressed: enabled && draft.isDirty ? actions.onRevert : null,
                child: const Text('Revert'),
              ),
              if (problems.isNotEmpty)
                Text(
                  'Correct the marked fields to save this row.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _zeroConfirm(BuildContext context, bool enabled) {
    final colors = MatrixColors.of(context);
    final why = draft.isBlank
        ? 'Nothing is entered. Saving records No flight, a zero.'
        : 'Saving scores 0 for this pilot.';
    if (draft.zeroConfirmed) {
      return ScoreInlineNote(
        icon: Icons.check_circle_outline,
        color: colors.success,
        text: 'Zero confirmed. Save the row to record it.',
      );
    }
    return ScoreInlineNote(
      icon: Icons.help_outline,
      color: colors.warn,
      text: why,
      actionLabel: 'Confirm zero',
      onAction: enabled ? draft.confirmZero : null,
      actionKey: ValueKey(keyOf('confirm-zero')),
    );
  }

  Widget _landing(BuildContext context, bool enabled) {
    final theme = Theme.of(context);
    final reason = draft.landingOffReason;
    if (landings.isEmpty) {
      return Text(
        'The contest has no landing table. Choose one on the '
        'Configuration page.',
        style: theme.textTheme.bodySmall,
      );
    }
    void move(int delta) {
      final keys = [for (final l in landings) l.entryKey];
      final at = draft.landing == null ? -1 : keys.indexOf(draft.landing!);
      final next = (at + delta).clamp(0, keys.length - 1);
      draft.setLanding(keys[next]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          focusNode: landingNode,
          canRequestFocus: enabled && reason == null,
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.arrowDown) {
              move(1);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.arrowUp) {
              move(-1);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter) {
              penaltyNode.requestFocus();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Wrap(
            key: ValueKey(keyOf('landing')),
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final landing in landings)
                ChoiceChip(
                  key: ValueKey('${keyOf('landing')}-${landing.entryKey}'),
                  label: Text(
                    landing.displayValue.contains('${landing.pointValue}')
                        ? landing.displayValue
                        : '${landing.displayValue} · '
                              '${landing.pointValue} pts',
                  ),
                  selected: draft.landing == landing.entryKey,
                  onSelected: enabled && reason == null
                      ? (on) => draft.setLanding(on ? landing.entryKey : null)
                      : null,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  visualDensity: const VisualDensity(vertical: 1),
                ),
            ],
          ),
        ),
        if (reason != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.block, size: 16),
                const SizedBox(width: 6),
                Text(reason, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}
